#!/usr/bin/env bash

set -euo pipefail

readonly required_odin='odin version dev-2026-08-nightly:902106f'
readonly required_sdl='3.4.14'

actual_odin="$(odin version)"
if [[ "${actual_odin}" != "${required_odin}" ]]; then
	printf 'Odin mismatch. Required: %s; found: %s\n' "${required_odin}" "${actual_odin}" >&2
	exit 1
fi

actual_sdl="$(pkg-config --modversion sdl3)"
if [[ "${actual_sdl}" != "${required_sdl}" ]]; then
	printf 'SDL3 mismatch. Required: %s; found: %s\n' "${required_sdl}" "${actual_sdl}" >&2
	exit 1
fi

printf 'Dependency versions match the project lock.\n'
