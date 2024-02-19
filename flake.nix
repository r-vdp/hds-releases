{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      forEachSystem = lib.genAttrs [
        "x86_64-linux"
      ];
    in
    {
      legacyPackages = forEachSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          srcs = (import ./sources.nix).${system};
        in
        {
          holo-dev-server-bin =
            let
              src = srcs.holo-dev-server-bin;

              runtimeDeps = lib.concatMapStringsSep " "
                (dep:
                  builtins.appendContext "" {
                    ${dep.drvPath} = { outputs = [ "${dep.output}" ]; };
                  }
                )
                (lib.importJSON ./depinfo.json);
            in
            pkgs.runCommand "holo-dev-server-bin" { } ''
              mkdir -p $out/bin
              echo ${runtimeDeps} > $out/.runtimedeps
              cp -a ${src}/bin/holo-dev-server $out/bin/holo-dev-server
            '';
        });
    };
}
