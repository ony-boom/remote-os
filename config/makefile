COLMENA := nix run .\#apps.x86_64-linux.colmena

.PHONY: all local

# Deploy to VPS
all:
	$(COLMENA) apply

# Deploy to local machine
local:
	$(COLMENA) apply-local
