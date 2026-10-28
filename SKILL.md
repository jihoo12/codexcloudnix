---
name: rootless-nix
description: Install, diagnose, and verify Nix without sudo in Linux cloud or container environments using nix-portable and bubblewrap. Use when /nix is unavailable or unwritable, and when validating a project's nix develop shell.
---

# Rootless Nix

Use this skill to set up a Nix development environment in a Linux cloud or container
workspace where you do not have root privileges.

## Workflow

1. Read the workspace's instructions and any managed-environment setup rules.
   Check the environment's network policy before downloading anything. Keep
   inherited proxy and CA settings; do not disable TLS verification or bypass
   network restrictions.
2. Inspect the environment:

   ```bash
   id
   uname -sm
   command -v nix || true
   command -v bwrap || true
   ls -ld /nix 2>/dev/null || true
   ```

   If a working Nix installation is already available, reuse it. Do not
   overwrite its binaries or store.
3. For Linux x86_64 or aarch64 without a working Nix installation, test
   bubblewrap user namespaces:

   ```bash
   bwrap --unshare-user --uid 0 --gid 0 --ro-bind / / --dev /dev --proc /proc true
   ```

   A successful result can permit a rootless Nix environment even without a
   writable host-wide `/nix`. Do not assume sudo, systemd, or a privileged
   container.
4. Run `bash scripts/install.sh /absolute/writable/prefix` from **this skill's
   directory**. Prefer persistent workspace storage, such as `/workspace/.local`,
   if the environment offers it. The script installs the pinned nix-portable
   **v012** executable and a `bin/nix-rootless` launcher. This version bundles
   Nix **2.20.6**; it is not the current Nix release. Existing launchers are
   never overwritten.
5. Verify the launcher:

   ```bash
   /absolute/writable/prefix/bin/nix-rootless --version
   /absolute/writable/prefix/bin/nix-rootless eval --expr 'builtins.add 20 22'
   ```

   The second command should return `42`. First use may download Git and
   other dependencies from the Nix binary cache.
6. Locate and inspect the **actual project's** `flake.nix`, including
   `shellHook` commands, before running the development shell. Then test it:

   ```bash
   /absolute/writable/prefix/bin/nix-rootless develop /path/to/project --command bash -c '<project-specific verification command>'
   ```

   Preserve the existing `flake.lock` unless the user requests an update or a
   necessary compatibility change, and explain any such change.
7. If the project has no `flake.nix`, report that its `nix develop` workflow
   is not yet available. For an **independent** smoke test, run:

   ```bash
   bash scripts/smoke-test.sh /absolute/writable/prefix/bin/nix-rootless /absolute/new-test-directory
   ```

   This creates a new, minimal fixture, verifies `shellHook`, and runs
   `hello`. The fixture deliberately pins `nixos-24.05` for compatibility
   with nix-portable v012, **not** as a recommendation for new projects.
8. Report the exact install path, Nix version, commands and results tested,
   and whether verification exercised the actual project or only the fixture.

## Troubleshooting and safety

- If `bwrap` or user namespaces fail, stop this installation path and report
  the specific error. The upstream nix-portable project documents a proot
  runtime, which may be considered only after checking proot and ptrace
  availability; never claim it works without testing. Do not change kernel
  security settings.
- If download or evaluation fails, check network policy, inherited proxies,
  and CA certificates. GitHub and its release-asset hosts, api.github.com,
  and cache.nixos.org may be required. Do not bypass network restrictions.
- Newer nixpkgs revisions may require newer Nix than the Nix 2.20.6 bundled
  in nix-portable v012. Identify this as a version mismatch rather than an
  installation failure. Discuss a compatible pin or a supported upgrade
  before changing a project's lock file.
- nix-portable normally stores data in `~/.nix-portable` and exposes a
  virtual `/nix` inside its runtime. It does **not** create a system daemon
  or host-global `/nix`. Installing a launcher inside the workspace does not
  guarantee store persistence across workspace resets. Never remove or
  relocate an existing store without explicit authorization.
- Do not claim the launcher is available globally on `PATH` or will survive
  workspace replacement unless that is verified.

Upstream nix-portable: https://github.com/DavHau/nix-portable
