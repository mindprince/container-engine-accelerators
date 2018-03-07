# Copyright 2015 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and

GO := go
pkgs  = $(shell $(GO) list ./... | grep -v vendor)

all: presubmit

test:
	@echo ">> running tests"
	@$(GO) test -short -race $(pkgs)

format:
	@echo ">> formatting code"
	@$(GO) fmt $(pkgs)

vet:
	@echo ">> vetting code"
	@$(GO) vet $(pkgs)

presubmit: vet
	@echo ">> checking go formatting"
	@./build/check_gofmt.sh .
	@echo ">> checking file boilerplate"
	@./build/check_boilerplate.sh

TAG?=$(shell git rev-parse HEAD)
REGISTRY?=gcr.io/google-containers
IMAGE_PLUGIN=nvidia-gpu-device-plugin
IMAGE_DRIVER=nvidia-driver-server
IMAGE_DOWNLOADER=nvidia-driver-downloader

build:
	go build cmd/nvidia_gpu/nvidia_gpu.go
	go build cmd/driver_server/driver_server.go

container-plugin:
	docker build --pull -t ${REGISTRY}/${IMAGE_PLUGIN}:${TAG} .

push-plugin:
	gcloud docker -- push ${REGISTRY}/${IMAGE_PLUGIN}:${TAG}

container-driver:
	docker build --pull -f Dockerfile.driver_server -t ${REGISTRY}/${IMAGE_DRIVER}:${TAG} .

push-driver:
	gcloud docker -- push ${REGISTRY}/${IMAGE_DRIVER}:${TAG}

container-downloader:
	docker build --pull -f Dockerfile.downloader -t ${REGISTRY}/${IMAGE_DOWNLOADER}:${TAG} .

push-downloader:
	gcloud docker -- push ${REGISTRY}/${IMAGE_DOWNLOADER}:${TAG}

.PHONY: all format test vet presubmit build container-plugin push-plugin container-driver push-driver container-downloader push-downloader
