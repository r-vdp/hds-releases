{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      forEachSystem = lib.genAttrs [
        "aarch64-linux"
        "x86_64-linux"
      ];
      # We only run tests for x86_64-linux in CI
      forEachTestSystem = lib.genAttrs [
        "x86_64-linux"
      ];
    in
    {
      packages = forEachSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          srcs = (import ./sources.nix).${system};
        in
        {
          holo-dev-server-bin =
            let
              src = srcs.holo-dev-server-bin;

              # depinfo.json contains the info on the runtime dependencies of
              # the original holo-dev-server binary, as detected by nix.
              # Nix detects runtime dependencies by scanning for the
              # out path hashes of the build-time inputs.
              # So in order for nix to detect the right runtime dependencies,
              # we create a string with the needed derivations in its string
              # context and use that string in the -bin derivation.
              # This will cause these derivations to be added to the build-time
              # dependencies, which will in turn cause nix to scan for them in
              # our output.
              # NOTE: these dependencies are not vendored! So users need to be
              # able to either build or substitute them.
              runtimeDeps = lib.concatMapStringsSep " "
                (dep:
                  builtins.appendContext "" {
                    ${dep.drvPath} = { outputs = [ "${dep.output}" ]; };
                  }
                )
                (lib.importJSON "${src}/depinfo.json");
            in
            pkgs.runCommand "holo-dev-server-bin" { } ''
              mkdir -p $out/bin
              # this comment pulls in the build-time dependencies: ${runtimeDeps}
              # If they appear in the binary, they will be registered as runtime dependencies.
              cp -a ${src}/bin/holo-dev-server $out/bin/holo-dev-server
            '';
        });

      checks = forEachTestSystem (system: {
        holo-dev-server-bin = self.packages.${system}.holo-dev-server-bin;
      });
    };
}
