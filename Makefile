SHELL := /bin/bash
# Check for required command tools to build or stop immediately
EXECUTABLES = git go find pwd
K := $(foreach exec,$(EXECUTABLES),\
        $(if $(shell which $(exec)),some string,$(error "No $(exec) in PATH")))

ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

BINARY=pam-keycloak-oidc
VERSION=1.1.7
BUILD=`git rev-parse HEAD`
PLATFORMS=darwin linux windows
ARCHITECTURES=amd64 arm64

# Setup linker flags option for build that inter-operate with variable names in src code
LDFLAGS=-ldflags "-X main.Version=${VERSION} -X main.Build=${BUILD}"

all: clean build_all

.PHONY: build
build: ## Build the binary for the local architecture
	go build ${LDFLAGS} -o ${BINARY}

.PHONY: build_all
build_all: ## Build the binary for all architectures
	$(foreach GOOS, $(PLATFORMS),\
		$(foreach GOARCH, $(ARCHITECTURES),\
			$(shell GOOS=$(GOOS); GOARCH=$(GOARCH); [[ $(GOOS) == "windows" ]] && EXT=".exe"; go build -v -o $(BINARY).$(GOOS)-$(GOARCH)$${EXT})))
	$(info All compiled!)

.PHONY: package
package: ## Create both a tar.gz and a .zip file excluding the files listed in the .gitignore and .tar.gz files respectively
	mkdir -p ./tmp
	git ls-files -co --exclude-standard > files.txt
	rm -f ./tmp/*
	while IFS= read -r file; do if [ -e "$$file" ]; then tar -czvf ./tmp/source_code.tar.gz "$$file"; fi; done < files.txt
	while IFS= read -r file; do if [ -e "$$file" ]; then zip -r ./tmp/source_code.zip "$$file"; fi; done < files.txt
	rm files.txt

# Remove only what we've created
clean:
	@find ${ROOT_DIR} -name '${BINARY}[.?][a-zA-Z0-9]*[-?][a-zA-Z0-9]*' -delete

.PHONY: help
help: ## Get help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'
