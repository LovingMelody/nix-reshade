{
  wine64,
  stdenvNoCC,
  ...
}:
stdenvNoCC.mkDerivation {
  name = "d3dcompiler_47-dll";
  src = wine64;
  phases = ["unpackPhase" "installPhase"];
  installPhase = ''
    install -Dm644 -v "$src/lib/wine/x86_64-windows/d3dcompiler_47.dll" "$out/lib/d3dcompiler_47.dll"
  '';
}
