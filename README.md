# Nix Cloud

1. **Cumulus** (Dev Server)
   - **Explanation**: Cumulus clouds are associated with fair weather, symbolizing a positive and dynamic environment, much like a development server.

2. **Nimbus** (Media Server)
   - **Explanation**: Nimbus clouds are rain-bearing and relate to the idea of streaming or distributing content, which fits the role of a media server.

3. **Cirrus** (Reverse Proxy Server)
   - **Explanation**: Cirrus clouds are high-altitude and thin, symbolizing clarity and efficient communication, akin to how a reverse proxy optimizes client-server interactions.

4. **Stratus** (VPN Server)
   - **Explanation**: Stratus clouds cover large areas, representing the widespread and secure connectivity provided by a VPN service.

5. **Altostratus** (Web Server)
   - **Explanation**: Altostratus clouds form a uniform layer across the sky, similar to the consistent and broad availability of a web server.

6. **Altocumulus** (Logging/Monitoring Server)
   - **Explanation**: Altocumulus clouds are structured and appear in patterns, mirroring the organized collection and analysis of logs and monitoring data.

7. **Cirrustratus** (Backup Server)
   - **Explanation**: Cirrustratus clouds cover large portions of the sky and often precede weather changes, symbolizing preparedness and long-term reliability, which aligns with the function of a backup server. 

This list provides cloud names tailored to specific server roles, each with symbolic ties to the nature of the cloud and the server's function.


## Cumulus

Cumulus is a dev server designed to build this Nix config and deploy the various services to the servers.

It runs the VSCode server from [here](https://github.com/nix-community/nixos-vscode-server)
To get it started I had to do:
```bash
ln -sfT /run/current-system/etc/systemd/user/auto-fix-vscode-server.service ~/.config/systemd/user/auto-fix-vscode-server.service
systemctl --user enable auto-fix-vscode-server.service
systemctl --user start auto-fix-vscode-server.service
```

## TODOs

- [] Create tf files for all hosts
- [] Create custom image with sudo passwd
- [] Secrets
- [] tf environment variables
- [] Configure Swap on all servers with disko. Couldn't get this working for some reason