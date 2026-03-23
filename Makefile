DOCKERHUB_USER ?= okunev
IMAGE_NAME ?= tor-proxy
TAG ?= latest
PLATFORMS ?= linux/amd64,linux/arm64

IMAGE := $(DOCKERHUB_USER)/$(IMAGE_NAME)

.PHONY: buildx-init
buildx-init:
	@docker buildx create --name multiarch --driver docker-container --use 2>/dev/null || docker buildx use multiarch
	@docker buildx inspect --bootstrap

.PHONY: build
build:
	docker build -t $(IMAGE):$(TAG) .

.PHONY: buildx-push
buildx-push: buildx-init
	docker buildx build \
		--platform $(PLATFORMS) \
		-t $(IMAGE):$(TAG) \
		--push \
		.
