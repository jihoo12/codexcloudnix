# codexcloudnix — Rootless Nix for AI coding agents

Set up and verify a Nix development shell in **Linux cloud workspaces without
sudo**. This repository packages a reusable `rootless-nix` agent skill with
its install script and an isolated `nix develop` smoke test.

It is intended for constrained Codex/cloud/container workspaces, **not** as a
replacement for an existing system Nix installation.

## What it does

- Checks Linux architecture and bubblewrap user-namespace support.
- Installs a pinned [nix-portable](https://github.com/DavHau/nix-portable)
  **v012** executable into a writable prefix, without requiring host `/nix`.
- Creates a `nix-rootless` launcher using `NP_RUNTIME=bwrap`.
- Verifies Nix evaluation and optionally tests a project's actual
  `flake.nix` / `nix develop` environment.
- Provides a separate smoke-test fixture if a project has no flake yet.

**Compatibility:** v012 bundles Nix 2.20.6. Some modern nixpkgs pins require a
newer Nix; a version mismatch is not the same as a failed rootless installation.

## Install as a Codex skill

Clone the repository into your user-level Codex skills directory:

```bash
mkdir -p ~/.agents/skills
git clone https://github.com/jihoo12/codexcloudnix.git ~/.agents/skills/rootless-nix
```

Codex can then discover the `SKILL.md` at
`~/.agents/skills/rootless-nix/SKILL.md`. In Codex, request
`$rootless-nix` or ask it to set up Nix without sudo. See [SKILL.md](SKILL.md)
for the agent's full workflow.

For a repository-scoped skill, clone or copy this folder into
`<project>/.agents/skills/rootless-nix/` instead.

## Run manually

Requires **Linux x86_64 or aarch64**, `curl`, `bwrap` (bubblewrap), a
writable persistent prefix, working user namespaces, and network access to
GitHub release assets and Nix binary caches.

```bash
git clone https://github.com/jihoo12/codexcloudnix.git
cd codexcloudnix

# Choose an absolute, writable location.
bash scripts/install.sh "$HOME/.local"

# Verify basic evaluation.
"$HOME/.local/bin/nix-rootless" --version
"$HOME/.local/bin/nix-rootless" eval --expr 'builtins.add 20 22'

# For an existing flake-based project, inspect its flake.nix first.
"$HOME/.local/bin/nix-rootless" develop /path/to/project --command bash -c 'echo shell-ready'

# Or test an independent fixture in a *new* directory:
bash scripts/smoke-test.sh "$HOME/.local/bin/nix-rootless" "$HOME/rootless-nix-smoke"
```

The fixture uses `nixos-24.05` strictly as a compatibility test for the
older bundled Nix release. It is **not** a recommended nixpkgs channel for new
applications.

## Limitations and safety

- User namespaces can be disabled by cloud/container policy, preventing
  bubblewrap from starting. This skill reports the failure; it does not
  bypass sandbox restrictions or alter the host kernel.
- Network restrictions, proxies, CA certificates, and cache availability
  can affect installation. The scripts never disable TLS verification.
- The nix-portable store is normally located under `~/.nix-portable`, not
  the chosen executable prefix. Workspace resets may remove this data.
- Existing `nix-rootless` launchers are not overwritten. The script does not
  modify your shell startup files or system-wide PATH.
- This repository ships scripts and instructions. It does **not** vendor
  nix-portable itself. Review upstream licensing and releases independently.
- This setup has not been validated on every Codex Cloud image or sandbox
  configuration; use the included checks to establish support in yours.

## Credits and licensing

This repository's workflow is adapted from the Rootless Nix agent skill.
The installation runtime is provided by the upstream
[nix-portable](https://github.com/DavHau/nix-portable) project.

Repository license: [Apache-2.0](LICENSE). The nix-portable binary is a
third-party dependency distributed by its upstream project under its own
applicable terms.
