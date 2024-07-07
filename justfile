# when running make this run command "nixos-rebuild switch --flake ."

default:
  just -l --unsorted

this:
	nixos-rebuild switch --flake .

_confirm:
	@read -p "Are you sure you want to deploy? This will reset the drive. [y/N] " confirm; \
	if [ "$$confirm" != "y" ]; then \
		echo "Deployment canceled."; \
		exit 1; \
	fi

deploy HOST SSH: _confirm
	nix run github:nix-community/nixos-anywhere -- --flake .#{{HOST}} {{SSH}}

# nixos-rebuild --target-host root@192.168.86.212 switch --flake .#nimbus