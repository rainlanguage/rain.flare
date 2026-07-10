{
  description = "Flake for development workflows.";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    rainix.url = "github:rainlanguage/rainix";
    rain.url = "github:rainlanguage/rain.cli";
  };

  outputs =
    {
      flake-utils,
      rainix,
      rain,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = rainix.pkgs.${system};
      in
      rec {
        packages = {
          rain-flare-prelude = rainix.mkTask.${system} {
            name = "rain-flare-prelude";
            body = ''
              set -euxo pipefail

              mkdir -p meta;
              forge script --silent ./script/BuildAuthoringMeta.sol;
              rain meta build \
                -i <(cat ./meta/FlareFtsoSubParserAuthoringMeta.rain.meta) \
                -m authoring-meta-v2 \
                -t cbor \
                -e deflate \
                -l none \
                -o meta/FlareFtsoWords.rain.meta \
                ;
              forge script --silent ./script/BuildPointers.sol;
              forge fmt;
            '';
            additionalBuildInputs = rainix.sol-build-inputs.${system} ++ [ rain.defaultPackage.${system} ];
          };
        }
        // rainix.packages.${system};

        devShells.default = pkgs.mkShell {
          packages = [
            packages.rain-flare-prelude
            rain.defaultPackage.${system}
          ];

          inherit (rainix.devShells.${system}.default) shellHook buildInputs nativeBuildInputs;
        };
      }
    );
}
