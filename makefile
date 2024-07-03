# when running make this run command "nixos-rebuild switch --flake ."

this:
	nixos-rebuild switch --flake .

confirm:
	@read -p "Are you sure you want to deploy? This will reset the drive. [y/N] " confirm; \
	if [ "$$confirm" != "y" ]; then \
		echo "Deployment canceled."; \
		exit 1; \
	fi

deploy: confirm
	@read -p "Enter the host: " host; \
	read -p "Enter the ssh key: " ssh; \
	nix run github:nix-community/nixos-anywhere -- --flake .#$$host $$ssh

.PHONY: deploy