#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."

# Compile the actual Foundation-only components without launching the app or contacting SDK servers.
crailglitun_build_dir=$(mktemp -d "${TMPDIR:-/tmp}/Crailglitun-integrations.XXXXXX")
trap 'rm -rf "$crailglitun_build_dir"' EXIT
crailglitun_sources=(
  Crailglitun/Experience/CrailglitunExperienceJavaScript.swift
  Crailglitun/Experience/CrailglitunExperienceURLResolver.swift
  Crailglitun/AppIntegrations/Attribution/Models/*.swift
  Crailglitun/AppIntegrations/Attribution/Support/AttributionConfiguration.swift
  Crailglitun/AppIntegrations/Attribution/Support/CrailglitunAttributionResolutionState.swift
  Crailglitun/AppIntegrations/Attribution/FirstOpen/FirstOpenAttributionClient.swift
  Crailglitun/AppIntegrations/Attribution/FirstOpen/CrailglitunFirstOpenResponseDecoder.swift
  scripts/verify_crailglitun_integrations.swift
)
for crailglitun_configuration in Debug Release; do
  crailglitun_flags=()
  if [[ "$crailglitun_configuration" == Debug ]]; then
    crailglitun_flags=(-D DEBUG)
  else
    crailglitun_flags=(-O)
  fi
  xcrun swiftc -swift-version 5 -default-isolation MainActor \
    -module-cache-path "$crailglitun_build_dir/module-cache" \
    "${crailglitun_flags[@]}" "${crailglitun_sources[@]}" \
    -o "$crailglitun_build_dir/checks"
  echo "Running $crailglitun_configuration compatibility checks"
  "$crailglitun_build_dir/checks"
done
