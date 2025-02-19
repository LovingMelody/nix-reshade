{
  fetchurl,
  stdenvNoCC,
  ...
}:
stdenvNoCC.mkDerivation {
  name = "d3dcompiler_47-dll";
  src = fetchurl {
    url = "https://lutris.net/files/tools/dll/d3dcompiler_47.dll";
    hash = "sha256-6ZSEfgGm8eTL3FqGRhasJi9n7k8U2xlJhGYajZJ6t/Q=";
  };
  unpackPhase = ''
    install -Dm644 -v $src $out/lib/d3dcompiler_47.dll
  '';
}
