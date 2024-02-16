{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: {
    legacyPackages.x86_64-linux.holo-dev-server-bin =
      let
        inherit (nixpkgs) lib;
        system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
        src = import ./sources.nix;

        runtimeDeps = lib.concatMapStringsSep " "
          (dep:
            builtins.appendContext dep.outPath {
              ${dep.drvPath} = { outputs = [ "${dep.output}" ]; };
            }
          )
          (lib.importJSON ./depinfo.json);
      in
      pkgs.runCommand "holo-dev-server-bin" { } ''
        mkdir -p $out/bin
        echo ${runtimeDeps} > $out/.runtimedeps
        cp -a ${src.${system}.holo-dev-server-bin}/bin/holo-dev-server $out/bin/holo-dev-server
      '';
  };
}
