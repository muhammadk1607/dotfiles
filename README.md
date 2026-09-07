# .dotfiles

Personal setup for **Pop!\_OS 24.04 LTS** running the **COSMIC** desktop.

## Installation

```bash
cd ~
git clone git@github.com:MBM1607/dotfiles.git
cd dotfiles
./install.sh
```

Every step is idempotent, so re-run `./install.sh` any time to pick up changes.

```bash
./install.sh --list             # show the available steps
./install.sh mise vscode        # run only these steps
./install.sh --skip docker      # run everything except this one
```

## What it does

| Step          | What it sets up                                                                |
| ------------- | ------------------------------------------------------------------------------ |
| `dotfiles`    | Symlinks `dot/` into `~`, backing up anything already there                    |
| `apt`         | Packages from `lists/apt-packages.txt`, plus pipx tools                        |
| `gh`          | GitHub CLI from GitHub's own apt repo                                          |
| `ssh`         | Generates `~/.ssh/id-github` and registers it with GitHub for auth and signing |
| `mise`        | node, ruby, python, java and gradle, plus global npm packages and gems         |
| `docker`      | Docker CE with the buildx and compose plugins                                  |
| `vscode`      | VS Code and every extension in `lists/vscode-extensions.txt`                   |
| `flatpak`     | COSMIC applets and GUI apps, from Flathub and Pop's `cosmic` remote            |
| `apps`        | Slack, AnyDesk, RustDesk, fastfetch, onefetch, Bun and Deno                    |
| `fonts`       | Iosevka Slab and Term Slab                                                     |
| `completions` | Bash completions into `~/.config/bash-completion/completions`                  |
| `assets`      | Wallpapers into `~/Pictures/wallpapers`                                        |
| `cosmic`      | Restores COSMIC settings from `config/cosmic/`                                 |
| `system`      | ufw rules, inotify limits, default terminal                                    |

## Layout

```
install.sh      Orchestrator — runs the steps above
lib/            Shared shell helpers (logging, apt, releases)
scripts/        One script per step, each runnable on its own
lists/          Everything that gets installed, one item per line
dot/            Files symlinked into ~
config/         COSMIC settings and the ssh config template
completions/    Hand-written bash completions
templates/      Starting points for new scripts and machine-local config
wallpapers/     Wallpapers
```

## Keeping it current

Snapshot live state back into the repo, then commit the diff:

```bash
./scripts/export-vscode-extensions.sh   # → lists/vscode-extensions.txt
./scripts/export-cosmic-config.sh       # → config/cosmic/
```

`update` (a function in `.bashrc`) upgrades everything in place: apt, flatpak,
mise runtimes, global npm packages, deno, bun, pipx and gh extensions.

## Notes

- **COSMIC, not GNOME.** Pop!\_OS 24.04 ships COSMIC, which stores settings as a
  file tree under `~/.config/cosmic/` rather than in dconf. The GNOME Shell
  extensions, `dconf` dumps and Orchis/Tela theming this repo used to install
  no longer apply and have been removed. `scripts/setup-cosmic.sh` is a no-op
  outside a COSMIC session.
- **mise replaces nvm and rbenv.** One tool for every runtime, one shell hook,
  and it reads `.nvmrc`, `.ruby-version` and `.tool-versions` on `cd` — so the
  old `alias cd='cdnvm'` override is gone.
- **Python tools go through pipx.** 24.04 marks the system interpreter
  PEP 668 externally-managed, so `pip install` into it is refused.
- `~/.bash.profile` is copied, not symlinked, and never overwritten. Put
  machine-local settings there; `.bashrc` sources it last.
- **Two flatpak remotes.** Most COSMIC applets are published to Pop's `cosmic`
  remote, not Flathub. Lines in `lists/flatpak-apps.txt` are `<app-id> [remote]`,
  defaulting to `flathub`.

## Reference

- [Browser extensions](./browser-extensions.md)
- [VS Code extensions](./vscode-extensions.md)
