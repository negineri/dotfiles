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
PATH="$HOME/bin:$HOME/.local/bin:$PATH" sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/negineri/dotfiles.git
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

### for windows client

```text
winget install -e --id twpayne.chezmoi
winget install -e --id Git.Git
# restart shell
chezmoi init --apply https://github.com/negineri/dotfiles.git
```

#### windows client after

- mount the network drive N: on WSL Debian at `/mnt/n` (`nofail` keeps WSL booting while N: is disconnected; run `sudo mount /mnt/n` after reconnecting)

```text
wsl -d Debian -u root -- sh -c 'mkdir -p /mnt/n && grep -q "^N: " /etc/fstab || echo "N: /mnt/n drvfs defaults,uid=1000,gid=1000,nofail 0 0" >> /etc/fstab'
wsl -d Debian -u root -- mount /mnt/n
```

## profiles

- windows_client
- darwin_client
- debian_client
- debian_server
