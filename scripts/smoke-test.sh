#!/usr/bin/env bash
set -euo pipefail

launcher=${1:?Usage: smoke-test.sh /absolute/nix-rootless /absolute/new-test-dir}
fixture=${2:?Provide a new test directory}
[[ "$launcher" = /* && "$fixture" = /* ]] || {
  echo "Absolute paths required." >&2
  exit 1
}

# Never overwrite a project or an earlier test directory.
mkdir "$fixture"
cat > "$fixture/flake.nix" <<'FLAKE'
{
  description = "Rootless Nix development shell compatibility smoke test";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  outputs = { self, nixpkgs }: let
    pkgs = import nixpkgs { system = builtins.currentSystem; };
  in {
    devShells.${builtins.currentSystem}.default = pkgs.mkShell {
      packages = [ pkgs.hello ];
      shellHook = ''export NIX_DEVELOP_SMOKE_TEST=ready'';
    };
  };
}
FLAKE

"$launcher" develop --impure "path:$fixture" --command bash -c \
  'set -eu; test "$NIX_DEVELOP_SMOKE_TEST" = ready; printf "shellHook: %s\n" "$NIX_DEVELOP_SMOKE_TEST"; command -v hello; hello'
