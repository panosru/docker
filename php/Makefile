VERSION ?= latest

.PHONY: help
help:
help:
	@echo "Available commands:"
	@echo "  make build-production v=<version>                    - Build the production image"
	@echo "  make build-production-with-loaders v=<version>       - Build the production-with-loaders image"
	@echo "  make build-development v=<version>                   - Build the development image"
	@echo "  make build-development-with-loaders v=<version>      - Build the development-with-loaders image"
	@echo "  make push-production v=<version>                     - Push the production image to the repository"
	@echo "  make push-production-with-loaders v=<version>        - Push the production-with-loaders image to the repository"
	@echo "  make push-development v=<version>                    - Push the development image to the repository"
	@echo "  make push-development-with-loaders v=<version>       - Push the development-with-loaders image to the repository"
	@echo "  make build-all v=<version>                           - Build all images"
	@echo "  make build-all-with-loaders v=<version>              - Build all images, including those with loaders"
	@echo "  make push-all v=<version>                            - Push all images to the repository"
	@echo "  make push-all-with-loaders v=<version>               - Push all images, including those with loaders, to the repository"

.PHONY: build-production
build-production:
	if [ -z "$(v)" ]; then echo "Version is not set. Use 'make build-production v=<version>'"; exit 1; fi
	docker build --build-arg VERSION=$(v) -t panosru/php:$(v) --target production .

.PHONY: build-production-with-loaders
build-production-with-loaders:
	if [ -z "$(v)" ]; then echo "Version is not set. Use 'make build-production-with-loaders v=<version>'"; exit 1; fi
	docker build --build-arg VERSION=$(v) -t panosru/php:$(v)-with-loaders --target production-with-loaders .

.PHONY: build-development
build-development:
	if [ -z "$(v)" ]; then echo "Version is not set. Use 'make build-development v=<version>'"; exit 1; fi
	docker build --build-arg VERSION=$(v) -t panosru/php:$(v)-dev --target development .

.PHONY: build-development-with-loaders
build-development-with-loaders:
	if [ -z "$(v)" ]; then echo "Version is not set. Use 'make build-development-with-loaders v=<version>'"; exit 1; fi
	docker build --build-arg VERSION=$(v) -t panosru/php:$(v)-dev-with-loaders --target development-with-loaders .

.PHONY: push-production
push-production:
	if [ -z "$(v)" ]; then echo "Version is not set. Use 'make push-production v=<version>'"; exit 1; fi
	docker push panosru/php:$(v)

.PHONY: push-production-with-loaders
push-production-with-loaders:
	if [ -z "$(v)" ]; then echo "Version is not set. Use 'make push-production-with-loaders v=<version>'"; exit 1; fi
	docker push panosru/php:$(v)-with-loaders

.PHONY: push-development
push-development:
	if [ -z "$(v)" ]; then echo "Version is not set. Use 'make push-development v=<version>'"; exit 1; fi
	docker push panosru/php:$(v)-dev

.PHONY: push-development-with-loaders
push-development-with-loaders:
	if [ -z "$(v)" ]; then echo "Version is not set. Use 'make push-development-with-loaders v=<version>'"; exit 1; fi
	docker push panosru/php:$(v)-dev-with-loaders

.PHONY: build-all
build-all:
	make build-production v=$(v)
	make build-development v=$(v)

.PHONY: build-all-with-loaders
build-all-with-loaders:
	make build-all v=$(v)
	make build-production-with-loaders v=$(v)
	make build-development-with-loaders v=$(v)

.PHONY: push-all
push-all:
	make push-production v=$(v)
	make push-development v=$(v)

.PHONY: push-all-with-loaders
push-all-with-loaders:
	make push-all v=$(v)
	make push-production-with-loaders v=$(v)
	make push-development-with-loaders v=$(v)
