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

### for linux server

```text
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --promptDefaults --apply https://github.com/negineri/dotfiles.git
```

## profiles

- darwin_client
- linux_client
- linux_server
