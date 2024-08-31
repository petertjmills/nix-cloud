# when running make this run command "nixos-rebuild switch --flake ."

default:
  just -l --unsorted

this:
	nixos-rebuild switch --flake .

_confirm:
	@read -p "Are you sure you want to run this command? [y/N] " confirm; \
	if [ "$$confirm" != "y" ]; then \
		echo "Deployment canceled."; \
		exit 1; \
	fi

init HOST SSH:
	nix run github:nix-community/nixos-anywhere -- --flake .#{{HOST}} {{SSH}}

# nixos-rebuild --target-host root@192.168.86.212 switch --flake .#nimbus

deploy HOST SSH:
	nixos-rebuild switch --flake .#{{HOST}} --target-host {{SSH}}

# nixos-generators can cross compile and use different image formats!
# Maybe move away from iso in the future?
buildiso PLATFORM:
  nix run nixpkgs#nixos-generators -- --format iso --flake .#{{PLATFORM}} -o ./isos/results/{{PLATFORM}}