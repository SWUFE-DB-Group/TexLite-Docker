#!/usr/bin/env bash
set -euo pipefail

repository_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repository_dir"

deployment_file="$repository_dir/deployment.json"
deployment_example="$repository_dir/deployment.example.json"

if [[ ! -f "$deployment_file" ]]; then
  cp "$deployment_example" "$deployment_file"
  echo "Created deployment.json from deployment.example.json." >&2
  echo "Edit deployment.json before starting if you need custom host settings or initial site information." >&2
fi

json_key_exists() {
  local key="$1"
  grep -Eq "^[[:space:]]*\"${key}\"[[:space:]]*:" "$deployment_file"
}

json_value() {
  local key="$1"
  awk -v wanted_key="$key" '
    {
      value = $0
      sub(/^[[:space:]]*/, "", value)
      prefix = "\"" wanted_key "\""
      if (index(value, prefix) != 1) next
      sub(/^[^:]*:[[:space:]]*/, "", value)
      sub(/[[:space:]]*,?[[:space:]]*$/, "", value)
      if (value ~ /^"/) {
        sub(/^"/, "", value)
        sub(/"$/, "", value)
      }
      print value
      exit
    }
  ' "$deployment_file"
}

required_json_value() {
  local key="$1"
  if ! json_key_exists "$key"; then
    echo "deployment.json is missing required key: $key" >&2
    exit 1
  fi
  json_value "$key"
}

expand_home_path() {
  case "$1" in
    "~") printf '%s' "$HOME" ;;
    "~/"*) printf '%s/%s' "$HOME" "${1#~/}" ;;
    /*) printf '%s' "$1" ;;
    *)
      echo "deployment.json paths must be absolute or start with ~/." >&2
      exit 1
      ;;
  esac
}

TEXLITE_BIND_ADDRESS="$(required_json_value host)"
TEXLITE_HOST_PORT="$(required_json_value port)"
TEXLITE_CONFIG_DIR="$(expand_home_path "$(required_json_value configDir)")"
TEXLITE_DATA_DIR="$(expand_home_path "$(required_json_value dataDir)")"
TEXLITE_INIT_SITE_NAME="$(required_json_value siteName)"
TEXLITE_INIT_ADMIN_EMAIL="$(required_json_value adminEmail)"
TEXLITE_INIT_USERNAME="$(required_json_value adminUsername)"
TEXLITE_INIT_DISPLAY_NAME="$(required_json_value adminDisplayName)"

[[ "$TEXLITE_BIND_ADDRESS" =~ ^[A-Za-z0-9.-]+$ ]] || {
  echo "deployment.json host must be an IPv4 address or hostname without a port." >&2
  exit 1
}
[[ "$TEXLITE_HOST_PORT" =~ ^[0-9]+$ ]] && (( 10#$TEXLITE_HOST_PORT >= 1 && 10#$TEXLITE_HOST_PORT <= 65535 )) || {
  echo "deployment.json port must be between 1 and 65535." >&2
  exit 1
}
for configured_value in "$TEXLITE_INIT_SITE_NAME" "$TEXLITE_INIT_ADMIN_EMAIL" "$TEXLITE_INIT_USERNAME" "$TEXLITE_INIT_DISPLAY_NAME"; do
  [[ "$configured_value" != *$'\n'* && "$configured_value" != *$'\r'* && "$configured_value" != *'"'* && "$configured_value" != *\\* ]] || {
    echo "deployment.json text values must not contain quotes, backslashes, or line breaks." >&2
    exit 1
  }
done

export TEXLITE_UID="$(id -u)"
export TEXLITE_GID="$(id -g)"
export TEXLITE_BIND_ADDRESS TEXLITE_HOST_PORT TEXLITE_CONFIG_DIR TEXLITE_DATA_DIR
export TEXLITE_INIT_SITE_NAME TEXLITE_INIT_ADMIN_EMAIL TEXLITE_INIT_USERNAME TEXLITE_INIT_DISPLAY_NAME

config_directory="$TEXLITE_CONFIG_DIR"
data_directory="$TEXLITE_DATA_DIR"

mkdir -p "$config_directory" "$data_directory"
chmod 700 "$config_directory" "$data_directory" 2>/dev/null || true

compose_command=(docker compose -f "$repository_dir/compose.yaml")

is_start=false
for argument in "$@"; do
  if [[ "$argument" == "up" ]]; then
    is_start=true
    break
  fi
done

if [[ "$is_start" == true && ! -f "$config_directory/texlite.config.json" && -z "${TEXLITE_INIT_PASSWORD:-}" ]]; then
  if [[ ! -t 0 ]]; then
    echo "First start requires an interactive terminal for the administrator password." >&2
    exit 1
  fi
  read -r -s -p "Initial administrator password (at least 8 characters): " TEXLITE_INIT_PASSWORD
  printf '\n'
  if [[ ${#TEXLITE_INIT_PASSWORD} -lt 8 ]]; then
    echo "The initial administrator password must contain at least 8 characters." >&2
    exit 1
  fi
  export TEXLITE_INIT_PASSWORD
fi

exec "${compose_command[@]}" "$@"
