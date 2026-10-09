#!/usr/bin/env bash
# Shared helpers: literal .env loader (no $ expansion) and authenticated curl.
load_env() {
  local f="${1:-.env}" line k v
  while IFS= read -r line || [ -n "$line" ]; do
    [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]] || continue
    k="${line%%=*}"; v="${line#*=}"
    v="${v%\"}"; v="${v#\"}"; v="${v%\'}"; v="${v#\'}"
    export "$k=$v"
  done < "$f"
}
lm() { curl -sS -u "${LM_USER}:${LM_TOKEN}" "$@"; }
