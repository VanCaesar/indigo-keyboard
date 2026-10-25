#!/bin/bash
# 把 .app 打成未签名 IPA（Sideloadly 侧载时再签名）
set -euo pipefail
app="$1"
out="$2"
work="$(mktemp -d)"
mkdir -p "$work/Payload"
cp -R "$app" "$work/Payload/"
out_abs="$(cd "$(dirname "$out")" && pwd)/$(basename "$out")"
rm -f "$out_abs"
(cd "$work" && zip -qry "$out_abs" Payload)
ls -lh "$out_abs"
du -sh "$work/Payload"/*.app/PlugIns/* 2>/dev/null || true
