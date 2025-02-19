#!/usr/bin/env python3

"""
Creates a shaders list 
"""
import configparser
import json
import os
import re
import subprocess
import urllib.parse
from urllib.request import Request, urlopen

SHADER_LIST_URL = "https://raw.githubusercontent.com/crosire/reshade-shaders/refs/heads/list/EffectPackages.ini"

VERSION_REGEX = re.compile(r"^v(\d+\.)?(\d+\.)?(\*|\d+)$")
EXTRA_SOURCES = os.environ.get("EXTRA_SOURCES", "extraSources.ini")


def nix_prefetch_git(url: str, branch: str) -> tuple[str, str]:
    out = subprocess.run(
        ["nix-prefetch-git", url, "--rev", f"refs/heads/{branch}"],
        check=True,
        text=True,
        capture_output=True,
    ).stdout.strip()
    j = json.loads(out.strip())
    commit: str = j["rev"]
    hash: str = j["hash"]
    return (commit, hash)


class Repo:
    branch: str
    commit: str
    owner: str
    repo: str
    hash: str

    def __init__(self, url: str) -> None:
        """
        Parse url and return a repos
        Supported urls:
            https://github.com/{owner}/{repo}
            https://github.com/{owner}/{repo}/tree/{branch}
        """
        url_path_split = [
            s.strip()
            for s in urllib.parse.urlparse(url).path.split("/")
            if s.strip() != ""
        ]
        self.owner = url_path_split[0].strip()
        self.repo = url_path_split[1].strip()
        print(f"owner: '{self.owner}' repo: '{self.repo}'")
        if self.owner == "" or self.repo == "":
            print(f"Owner/Repo blank paths: {', '.join(url_path_split)}\n    {url}")
            raise Exception("Failed to get owner & repo from url")

        if len(url_path_split) >= 3:
            self.branch = url_path_split[-1]
        else:
            req = url.replace("github.com", "api.github.com/repos", 1)
            with urlopen(req) as resp:
                self.branch = json.loads(resp.read().decode().strip())[
                    "default_branch"
                ].strip()
        print(f"branch: '{self.branch}'")
        self.commit, self.hash = nix_prefetch_git(
            f"https://github.com/{self.owner}/{self.repo}", self.branch
        )


class ShaderEntry:
    """
    Shader entry from ini section
    """

    repo: Repo
    name: str
    deniedEffects: list[str]
    effects: list[str]
    installPath: str
    texturePath: str
    description: str
    enabledByDefault: bool
    required: bool

    def __init__(self, section) -> None:

        def remove_empty(l: list[str]) -> list[str]:
            return [e.strip() for e in l if e.strip() != ""]

        self.name = section["PackageName"].strip()
        self.description = section.get(
            "PackageDescription", "No description provided"
        ).strip()
        self.repo = Repo(section["RepositoryUrl"])
        self.deniedEffects = remove_empty(section.get("DenyEffectFiles", "").split(","))
        self.effects = remove_empty(section["effectfiles"].split(","))
        self.texturePath = section["textureinstallpath"].strip().replace("\\", "/")
        self.installPath = section["installpath"].strip().replace("\\", "/")
        self.enabledByDefault = section.get("Enabled", "0").strip() == "1"
        self.required = section.get("Required", "0").strip() == "1"


def reshade_manifest() -> dict[str, str]:
    """
    Version + Prefetch
    """
    reshade_latest_version: str | None = None
    with urlopen(
        Request(
            "https://api.github.com/repos/crosire/reshade/tags",
            headers={"Accept": "application/vnd.github+json"},
        )
    ) as resp:
        body: str = resp.read().decode()
        tags = json.loads(body)
        for tag in tags:
            version: str = tag["name"]
            if VERSION_REGEX.match(version) is None:
                continue
            reshade_latest_version = version.strip().strip("v")
            break
    if reshade_latest_version is None:
        raise Exception("Failed to find latest version for ReShade")
    manifest = {"version": reshade_latest_version}
    urls = [
        f"https://reshade.me/downloads/ReShade_Setup_{reshade_latest_version}.exe",
        f"https://reshade.me/downloads/ReShade_Setup_{reshade_latest_version}_Addon.exe",
    ]
    for url in urls:
        get_hash = subprocess.run(
            ["nix-prefetch-url", url], check=True, capture_output=True, text=True
        )
        hash_convert = subprocess.run(
            [
                "nix",
                "hash",
                "convert",
                "--hash-algo",
                "sha256",
                "--to",
                "sri",
                get_hash.stdout.strip(),
            ],
            capture_output=True,
            check=True,
            text=True,
        )
        withAddons = url.endswith("_Addon.exe")
        edition: str = "addon" if withAddons else "base"
        manifest[edition] = hash_convert.stdout.strip()
    return manifest


def shader_manifest():
    req = Request(
        SHADER_LIST_URL,
        headers={
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
        },
    )
    config = configparser.ConfigParser()
    with urlopen(req) as resp:
        body: str = resp.read().decode()
        config.read_string(body)
    if os.path.exists(EXTRA_SOURCES):  # If extra sources are defined we can add them
        with open(EXTRA_SOURCES, mode="r") as f:
            config.read_file(f)

    manifest = {}
    for k in config:
        if not k.isnumeric():
            continue
        shader = ShaderEntry(config[k])
        manifest[shader.name] = {
            "name": shader.name,
            "description": shader.description,
            "url": f"https://github.com/{shader.repo.owner}/{shader.repo.repo}",
            "owner": shader.repo.owner,
            "repo": shader.repo.repo,
            "deniedEffects": shader.deniedEffects,
            "effects": shader.effects,
            "installPath": shader.installPath,
            "texturePath": shader.texturePath,
            "commit": shader.repo.commit,
            "branch": shader.repo.branch,
            "hash": shader.repo.hash,
            "enabledByDefault": shader.enabledByDefault,
            "required": shader.required,
        }

    return manifest


def main():
    manifest = {"reshade": reshade_manifest(), "shaders": shader_manifest()}
    data: str = json.dumps(manifest)
    path = os.environ.get("MANIFEST_PATH", "sources.json")
    with open(path, "w") as f:
        _ = f.write(data)


if __name__ == "__main__":
    main()
