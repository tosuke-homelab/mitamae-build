#!/bin/bash

set -e

if [ -n "${DEBUG}" ]; then
  set -x
fi

TOKEN=()
ENDPOINT=()
PLATFORM=()

_detect_os() {
  case "$(uname -s)" in
    Darwin) echo "darwin" ;;
    Linux) echo "linux" ;;
    *) echo "Unsupported operating system: $(uname -s)" 1>&2; exit 1 ;;
  esac
}

_detect_arch() {
  case "$(uname -m)" in
    amd64|x86_64) echo "amd64 386" | tr " " "\n" ;;
    arm64|aarch64) echo "arm64/v8" ;;
    mips) echo "mips" ;;
    mips64) echo mips64 mips | tr " " "\n" ;;
    *) echo "Unsupported processor architecture: $(uname -m)" 1>&2; exit 1 ;;
  esac
}

_detect_platform() {
  local os="$(_detect_os | jq -cR '{ os: . }' | jq -sc .)"
  local arch="$(_detect_arch | jq -cR 'split("/") | { architecture: .[0] } + ({ variant: (.[1] // empty) } // {})' | jq -sc .)"
  jq -nc --argjson os "$os" --argjson arch "$arch" '[$os, $arch] | combinations | .[0] + .[1]' | jq -s .
}

_login() {
  local host="$1"
  if [[ "${host}" == "docker.io" ]]; then
    host="registry-1.docker.io"
  fi
  local name="$2"
  local scope="repository:${name}:pull"
  local uri="https://${host}/token?service=$(echo $host | jq -Rr '@uri')&scope=$(echo $scope | jq -Rr '@uri')"
  curl -fsSL "$uri" | jq -r .token
  if [[ $? -ne 0 ]]; then
    echo "Failed to login to $host" 1>&2
    exit 1
  fi
}

_fetch_manifest() {
  local digest="$1"
  
  echo "Fetching manifest for $digest" 1>&2

  local hash="$(echo $digest | cut -d: -f2)"
  if [[ -z "$hash" ]]; then
    echo "Invalid digest: $digest" 1>&2
    exit 1
  fi

  local manifest_file="$(mktemp)"

  curl -fsSL \
    -o "$manifest_file" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Accept: application/vnd.oci.image.manifest.v1+json,application/vnd.oci.image.index.v1+json" \
    "${ENDPOINT}/manifests/${digest}"
  if [[ $? -ne 0 ]]; then
    echo "Failed to fetch manifest for $digest" 1>&2
    rm -f "$manifest_file"
    exit 1
  fi

  sha256sum -c <(echo "${hash}  -") <"$manifest_file" 1>&2
  if [[ $? -ne 0 ]]; then
    echo "Invalid manifest for $digest" 1>&2
    rm -f "$manifest_file"
    exit 1
  fi
  local manifest="$(jq -c "." <"$manifest_file")"

  case "$(jq -r .mediaType <<< "$manifest")" in
    "application/vnd.oci.image.manifest.v1+json") jq -c "." <<< "$manifest" ;;
    "application/vnd.oci.image.index.v1+json")
      manifest="$(jq -nc --argjson index "$manifest" --argjson platform "$PLATFORM" \
        '[ $platform, $index.manifests ]
         | combinations
         | select(.[0].os == .[1].platform.os and .[0].architecture == .[1].platform.architecture and .[0].variant == .[1].platform.variant)
         | .[1]' \
      | head -n1)"
      if [[ -z "$manifest" ]]; then
        echo "No matching platform" 1>&2
        exit 1
      fi      

      _fetch_manifest "$(jq -r .digest <<< "$manifest")"
    ;;
    *) echo "Unsupported manifest type: $type" 1>&2; exit 1 ;;
  esac
}

main() {
  local target="$(echo $1 | jq -cR 'capture("(?<host>[^/]+)/(?<name>.+)@(?<digest>sha256:.+)")')"
  if [[ -z "$target" ]]; then
    echo "Usage: $0 <host>/<name>@<digest>" 1>&2
    exit 1
  fi
  local host="$(echo $target | jq -r .host)"
  local name="$(echo $target | jq -r .name)"
  local digest="$(echo $target | jq -r .digest)"

  ENDPOINT="https://${host}/v2/${name}"

  echo "Logging in to $host" 1>&2
  TOKEN="$(_login $host $name)"

  PLATFORM="$(_detect_platform)"

  local layer
  _fetch_manifest "$digest" \
  | jq -c '.layers[] | select(.annotations."org.opencontainers.image.title" != null)' \
  | while read layer; do
    local name="$(jq -r '.annotations."org.opencontainers.image.title"' <<< "$layer")"
    echo "Fetching layer $name" 1>&2

    local digest="$(jq -r '.digest' <<< "$layer")"
    local hash="$(cut -d: -f2 <<< "$digest")"
    
    local tmp="$(mktemp)"
    curl -fsSL \
      -o "$tmp" \
      -H "Authorization: Bearer ${TOKEN}" \
      "${ENDPOINT}/blobs/${digest}"
    if [[ $? -ne 0 ]]; then
      echo "Failed to fetch layer $name" 1>&2
      rm -f "$tmp"
      exit 1
    fi

    sha256sum -c <(echo "${hash}  -") <"$tmp" 1>&2
    if [[ $? -ne 0 ]]; then
      echo "Invalid layer $name" 1>&2
      rm -f "$tmp"
      exit 1
    fi

    mv "$tmp" "$name"
  done

}

main $1