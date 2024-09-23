# negineri dotfiles

dotfiles powerd by [chezmoi](https://www.chezmoi.io/)

## Requirements

- for mac
  - Xcode Command Line Tools
  - ssh keys
- for linux
  - curl
  - git

## setup

### for mac client

```text
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:negineri/dotfiles.git
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
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --promptDefaults --apply https://github.com/negineri/dotfiles.git
```

## profiles

- darwin_client
- linux_client
- linux_server
