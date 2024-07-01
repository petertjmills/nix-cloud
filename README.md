# Nix Cloud

## Cumulus

Cumulus is a dev server desigined to build this Nix config and deploy the various services to the servers.

It runs the VSCode server from [here](https://github.com/nix-community/nixos-vscode-server)
To get it started I had to do:
```bash
ln -sfT /run/current-system/etc/systemd/user/auto-fix-vscode-server.service ~/.config/systemd/user/auto-fix-vscode-server.service
systemctl --user enable auto-fix-vscode-server.service
systemctl --user start auto-fix-vscode-server.service
```

