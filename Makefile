VERSION ?= $(shell git describe --exact-match --tags 2> /dev/null || git rev-parse --short HEAD)
DOCKER_REGISTRY ?= gcr.io/linkerd-io
REPO = $(DOCKER_REGISTRY)/proxy-init
SUPPORTED_ARCHS = linux/amd64,linux/arm64,linux/arm/v7

###############
# Go
###############
.PHONY: build
build:
	go build -o out/linkerd2-proxy-init main.go

.PHONY: run
run:
	go run main.go

.PHONY: test
test:
	go test -v ./...

.PHONY: integration-test
integration-test: image
	cd integration_test && ./run_tests.sh

###############
# Docker
###############
.PHONY: image
image:
	DOCKER_BUILDKIT=1 docker build -t $(REPO):latest -t $(REPO):$(VERSION) .

.PHONY: images
images:
	docker buildx build \
		--platform $(SUPPORTED_ARCHS) \
		--output "type=image,push=false" \
		--tag $(REPO):$(VERSION) \
		--tag $(REPO):latest \
		.

.PHONY: push
push: images
	docker buildx build \
		--platform $(SUPPORTED_ARCHS) \
		--output "type=image,push=true" \
		--tag $(REPO):$(VERSION) \
		--tag $(REPO):latest \
		.

.PHONY: inspect-manifest
inspect-manifest:
	docker run --rm mplatform/mquery $(REPO):$(VERSION)
	docker run --rm mplatform/mquery $(REPO):latest
