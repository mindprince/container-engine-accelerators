#!/bin/sh

set -o errexit
set -o pipefail
set -u
set -x

ROOT_OS_RELEASE="${ROOT_OS_RELEASE:-/root/etc/os-release}"
NVIDIA_DRIVER_VERSION="${NVIDIA_DRIVER_VERSION:-384.111}"

if [[ ! -f "${ROOT_OS_RELEASE}" ]]; then
  echo "File ${ROOT_OS_RELEASE} not found, /etc/os-release from COS host must be mounted."
  exit 1
fi
. "${ROOT_OS_RELEASE}"
echo "Running on COS build id ${BUILD_ID}"

if curl -LfsS --connect-timeout 1 "driver-download-service:8080/${BUILD_ID}/${NVIDIA_DRIVER_VERSION}" -o nvidia.tgz; then
  tar -xzvf nvidia.tgz
fi
