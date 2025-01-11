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

7. **Cirrostratus** (Backup Server)
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

- [ ] Create tf files for all hosts
- [ ] Create custom image with sudo passwd
- [ ] Secrets
- [ ] tf environment variables
- [ ] Configure Swap on all servers with disko. Couldn't get this working for some reason
- [ ] Prevent init from running if the server is already initialized as it may cause data loss

# Commands

```bash

```

# Useful docs

Terrafom Proxmox provider:
https://registry.terraform.io/providers/Telmate/proxmox/latest/docs

# Useful information

This line can break disko:

```
# boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only
```

All proxmox vms require this too:

```
boot.initrd.availableKernelModules = [ "virtio_scsi" ];
```

# Backups

Cirrustratus is the backup server. It hosts a borg backup repositories that can be accessed via ssh (Therefore requires the ssh keys to be configured).
A very important note is that I have one borg repo per machine. [Explanation](https://borgbackup.readthedocs.io/en/stable/faq.html#can-i-backup-from-multiple-servers-into-a-single-repository)

To set up a borg nixos job, you can use the following:

```nix
TODO: Add borg backup job
```

To initialize an uninitialized borg repository, use the following command:

```bash
borg init --encryption=repokey-blake2 ${BACKUP REPO}@cirrustratus.lan
```

To backup from other machines (macos) use the following command ([docs](https://borgbackup.readthedocs.io/en/stable/usage/create.html)):
TODO: investigate the /./. looks weird and unintuitive
TODO: exclude ".\*" is not working

```bash
borg create --stats --progress ssh://${BACKUP REPO}@cirrustratus.lan/./.::${BACKUP NAME}_{now} ${FOLDER TO BACKUP} --exclude ~/Library --exclude ".*"
```

TODO: Test and add pruning

All backups are copied to Backblaze B2 using rclone periodically (at the moment every Monday at midnight), automated with systemd timers.
The command used is as follows:

```bash
rclone sync ${backupPath} remote:petermills-backups --config ${config.age.secrets.b2_backup.path}
```

[Hard-delete](https://rclone.org/b2/#b2-hard-delete) is disabled on the B2 bucket, so changes are persisted over time, however this will start to use more space over time. To clean this we can use rclone, instructions are [here](https://rclone.org/b2/#versions)

# Notes

Personal cloud

Services

- Backup location
  - Borg
- Notes
  - Nextcloud
- Reminders
  - Nextcloud
- Calendar
  - Nextcloud
- Media server
  - Jellyfin
  - Radarr
  - Sonarr
  - Prowlarr
  - Transmission
- VPN
  - Headscale
  - Tailscale
- Password manager
  - Vaultwarden
  - Bitwarden
- CDN - Strapi
  Infrastructure
- Logging/Monitoring
  - Grafana
  - Loki
  - Prometheus
- Notifications
  - ntfy.sh
- Auth
  - Authelia
- Mail
  - [TBC]
- Proxy
  - Nginx
- Other
  - Endlessh
- DNS
  - dnsmasq
- VPN
  - Wireguard
- Dev
  - VSCode server
  - Opentofu
  - Nix-anywhere

Devices

- Homelab
  - VMs
    - Cumulus
      - Dev
    - Nimbus
      - Media Server
    - Cirrus
      - Internal Proxy
      - DNS
    - Altostratus
      - Notes
      - Reminders
      - Calendar
      - Password Manager
      - Auth
    - Altocumulus
      - Logging/Monitoring
      - Notifications
    - Cirrostratus
      - Backups
- VPS
  - Stratus
    - VPN
    - External Proxy
    - Endlessh
- MacBook
- Mac mini
- Fire stick?
- iPhone

Network

- Groups
  - Internal
  - External
  - Personal

Core: (must share host) (Level 0)
Dev
Router
Logging/Monitoring

External: (can be on the internet, must accept inbound connections from the internet, connected to core with wireguard)
Satellite (VPS)

Stateful: ()
Media
Backup
DBs? (should I put databases separate)

Networks: (10.LEVEL.0.0/24)

- Level 0
  - a network on a single provider (proxmox, hetzner, aws) that is private, so neighbour servers can communicate
- Level 1
  - a wireguard network that connects

# New install config

1. Create iso using just buildiso x86_64-linux
2. Boot machine from USB
3. git clone https://github.com/petertjmills/nix-cloud
4. Use [disko install](https://github.com/nix-community/disko/blob/master/docs/disko-install.md)

- `nix run 'github:nix-community/disko/latest#disko-install' -- --flake <flake-url>#<flake-attr> --disk <disk-name> <disk-device>`
- Note: For some reason I have to clone first: it doesn't let me do `flake https://github.com.....` may be worth investigating

5. Reboot!

