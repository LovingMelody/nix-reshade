(
  import
  (
    builtins.fetchTarball {
      url = "https://github.com/edolstra/flake-compat/archive/99f1c2157fba4bfe6211a321fd0ee43199025dbf.tar.gz";
      sha256 = "0d3lb0391h2szyyl4hbqxm8a4y5bwk23w3wq23qicw5b95i5z7cy";
    }
  )
  {
    src = ./.;
  }
)
.defaultNix
