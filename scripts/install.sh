#!/usr/bin/env bash
set -euo pipefail

prefix=${1:?Usage: install.sh /absolute/writable/prefix}
[[ "$prefix" = /* ]] || { echo "Use an absolute prefix." >&2; exit 1; }
[[ $(uname -s) = Linux ]] || { echo "Linux required." >&2; exit 1; }

case $(uname -m) in
  x86_64) arch=x86_64 ;;
  aarch64) arch=aarch64 ;;
  *) echo "Unsupported architecture." >&2; exit 1 ;;
esac

command -v curl >/dev/null
command -v bwrap >/dev/null
bwrap --unshare-user --uid 0 --gid 0 --ro-bind / / --dev /dev --proc /proc true

mkdir -p "$prefix/bin"
portable="$prefix/bin/nix-portable"
launcher="$prefix/bin/nix-rootless"

[[ ! -e "$launcher" && ! -L "$launcher" ]] || {
  echo "Launcher exists; inspect and reuse: $launcher" >&2
  exit 1
}

if [[ ! -e "$portable" && ! -L "$portable" ]]; then
  tmp=$(mktemp "$prefix/bin/.nix-portable.XXXXXX")
  trap 'rm -f "$tmp"' EXIT
  curl --fail --location --retry 2 --connect-timeout 20 --max-time 300 \
    "https://github.com/DavHau/nix-portable/releases/download/v012/nix-portable-$arch" -o "$tmp"
  chmod 755 "$tmp"
  mv -n "$tmp" "$portable"
fi

[[ -f "$portable" && -x "$portable" ]] || {
  echo "Existing nix-portable is not executable." >&2
  exit 1
}

# noclobber prevents replacing an existing launcher, even on a concurrent install.
(set -o noclobber; cat > "$launcher" <<'LAUNCHER'
#!/usr/bin/env bash
set -euo pipefail
bin_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export NP_RUNTIME=bwrap
exec "$bin_dir/nix-portable" nix "$@"
LAUNCHER
)
chmod 755 "$launcher"

"$launcher" --version
"$launcher" eval --expr 'builtins.add 20 22'
printf 'Run: %q develop <project-path>\n' "$launcher"
