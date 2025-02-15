#!/usr/bin/env python3
import argparse
import os
import subprocess
import sys
import shutil

secrets_dir = "/mnt/secrets"
masterkey_dir = os.path.join(secrets_dir, "masterkey")
public_keys_output_dir = "./secrets/public-keys"


def main():
    # parse args
    parser = argparse.ArgumentParser(description='Generate ssh keys for hosts')
    parser.add_argument('hosts', nargs='+', help='List of hostnames to generate SSH keys for')
    parser.add_argument('--full-refresh', action='store_true', help='Overwrite existing keys')
    parser.add_argument('--dry-run', action='store_true', help='Do not write anything to disk')
    parser.add_argument('--output-dir', default=masterkey_dir, help='Output directory for SSH keys')
    args = parser.parse_args()

    if not os.path.isdir(masterkey_dir):
        print(f"Error: Master key dir is missing: {masterkey_dir}. Drive may not be mounted or secrets-dir is incorrect.")
        sys.exit(1)

    if not args.dry_run and not os.path.exists(public_keys_output_dir):
        os.makedirs(public_keys_output_dir, exist_ok=True)

    for host in args.hosts:
        private_key_path = os.path.join(args.output_dir, f"{host}_id_ed25519")
        public_key_path = os.path.join(args.output_dir, f"{host}_id_ed25519.pub")
        public_keys_dest_path = os.path.join(public_keys_output_dir, f"{host}_id_ed25519.pub")

        if not args.full_refresh and os.path.exists(private_key_path):
            print(f"Keys for {host} already exist at {args.output_dir}. Skipping generation. Use --full-refresh to regenerate.")
            continue

        command = ['ssh-keygen', '-t', 'ed25519', '-N', '', '-f', private_key_path]

        if args.dry_run:
            print(f"Dry-run: would execute: {' '.join(command)}")
        else:
            print(f"Generating keys for {host} in {args.output_dir}")
            subprocess.run(command, check=True, capture_output=True)

            # Set permissions to 600 for private key and 644 for public key
            os.chmod(private_key_path, 0o600)
            os.chmod(public_key_path, 0o644)

            # copy public keys to ./secrets/public-keys
            shutil.copy2(public_key_path, public_keys_dest_path)
            print(f"Public key copied to {public_keys_dest_path}")

            # if hostname = name then copy the key to ~/.ssh
            hostname = os.uname().nodename
            if hostname == host:
                home_ssh_dir = os.path.expanduser("~/.ssh")
                if not os.path.exists(home_ssh_dir):
                    os.makedirs(home_ssh_dir, exist_ok=True)
                home_private_key_path = os.path.join(home_ssh_dir, "id_ed25519")
                home_public_key_path = os.path.join(home_ssh_dir, "id_ed25519.pub")
                shutil.copy2(private_key_path, home_private_key_path)
                shutil.copy2(public_key_path, home_public_key_path)
                print(f"Keys copied to ~/.ssh/ because hostname '{hostname}' matches host '{host}'")

    print("SSH key generation completed.")


if __name__ == "__main__":
    main()