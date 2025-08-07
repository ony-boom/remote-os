COLMENA ?= nix run .\#apps.x86_64-linux.colmena

.PHONY: all local update-local update

## Deploy to VPS
all:
	$(COLMENA) apply

## Deploy to local machine
local:
	$(COLMENA) apply-local

## Pull latest Git changes, update flake inputs, and deploy locally
update-local:
	git pull --ff-only
	nix flake update
	$(COLMENA) apply-local
