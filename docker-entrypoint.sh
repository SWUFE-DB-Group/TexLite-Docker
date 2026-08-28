#!/bin/sh
set -eu

config_path="${TEXLITE_CONFIG:-/config/texlite.config.json}"

available_engines() {
  engines=""
  for engine in pdflatex xelatex lualatex; do
    if command -v "$engine" >/dev/null 2>&1; then
      engines="${engines}${engines:+,}${engine}"
    fi
  done
  printf '%s' "$engines"
}

create_initial_config() {
  if [ -z "${TEXLITE_INIT_PASSWORD:-}" ]; then
    echo "TexLite has not been initialized. Start it through scripts/compose.sh so it can request an administrator password." >&2
    exit 1
  fi
  if [ "${#TEXLITE_INIT_PASSWORD}" -lt 8 ]; then
    echo "TEXLITE_INIT_PASSWORD must contain at least 8 characters." >&2
    exit 1
  fi

  engines="$(available_engines)"
  if [ -z "$engines" ]; then
    echo "No supported LaTeX engine was found in the selected TeX Live image." >&2
    exit 1
  fi

  export TEXLITE_DOCKER_ENGINES="$engines"
  node /usr/local/lib/texlite-docker/create-config.mjs "$config_path"
}

command="${1:-serve}"
case "$command" in
  serve)
    if [ ! -f "$config_path" ]; then
      create_initial_config
      if ! texlite init; then
        rm -f "$config_path"
        echo "Initialization failed; the generated configuration was removed so you can correct the problem and retry." >&2
        exit 1
      fi
      echo "TexLite initialized." >&2
    fi
    unset TEXLITE_INIT_PASSWORD
    exec texlite serve
    ;;
  init)
    if [ ! -f "$config_path" ]; then
      create_initial_config
    fi
    exec texlite init
    ;;
  *)
    exec texlite "$@"
    ;;
esac
