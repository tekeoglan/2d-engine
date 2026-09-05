#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd -- "${script_dir}/.." && pwd)"

cd "${project_root}"
mkdir -p build

odin build games/pong \
	-debug \
	-out:build/pong-debug \
	-collection:engine=./engine
