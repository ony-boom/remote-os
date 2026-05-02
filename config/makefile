COLMENA ?= nix --accept-flake-config run .\#apps.x86_64-linux.colmena

.PHONY: all local update-local update

## Deploy to VPS
all:
	$(COLMENA) apply

boot:
	$(COLMENA) apply boot

## Deploy to local machine
local:
	$(COLMENA) apply-local
