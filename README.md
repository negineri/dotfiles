# negineri dotfiles

dotfiles powerd by [chezmoi](https://www.chezmoi.io/)

## Requirements

- for mac
  - Xcode Command Line Tools
- for linux
  - curl
  - git
  - unzip (for client)

## setup

### for mac client

```text
PATH="$HOME/bin:$HOME/.local/bin:$PATH" sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:negineri/dotfiles.git
open ~/.config/chrome-extensions
```

#### mac client after

- [Installation :: Better BibTeX for Zotero](https://retorque.re/zotero-better-bibtex/installation/)
- [Bitwarden (Browser Integration)](https://apps.apple.com/jp/app/bitwarden/id1352778147?mt=12)
- [Amphetamine](https://apps.apple.com/jp/app/amphetamine/id937984704?mt=12)
- [Battery Monitor](https://apps.apple.com/jp/app/battery-monitor-health-info/id836505650?mt=12)
- [LINE](https://apps.apple.com/jp/app/line/id539883307?mt=12)

### for linux server

```text
PATH="$HOME/bin:$HOME/.local/bin:$PATH" sh -c "$(curl -fsLS get.chezmoi.io)" -- init --promptDefaults --apply https://github.com/negineri/dotfiles.git
```

## profiles

- darwin_client
- debian_client
- debian_server
