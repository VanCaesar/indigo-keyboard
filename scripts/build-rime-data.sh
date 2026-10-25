#!/bin/bash
# 用 CI 里编出的 rime_deployer 预编译雾凇拼音（只在 CI 上跑），
# 输出 Vendor/RimeData/，作为键盘扩展的只读 shared_data_dir：
#   build/            预编译好的 *.bin 和合并后的 *.yaml（prebuilt_data_dir）
#   opencc/           emoji 与简繁转换
#   custom_phrase.txt、en_dicts/cn_en.txt   运行时读的文本库
# 键盘里不跑部署，避免占用内存和启动时间。
set -euxo pipefail

RIME_ICE_REF="${RIME_ICE_REF:-2026.06.30}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$ROOT/build/rime-data"
HOST="$ROOT/Vendor/host"
OUT="$ROOT/Vendor/RimeData"

rm -rf "$WORK"
mkdir -p "$WORK"
git clone --depth 1 --branch "$RIME_ICE_REF" https://github.com/iDvel/rime-ice "$WORK/rime-ice"

SHARED="$WORK/shared"
USERDIR="$WORK/user"
STAGING="$WORK/staging"
mkdir -p "$SHARED" "$USERDIR" "$STAGING"

ICE="$WORK/rime-ice"
cp "$ICE"/*.yaml "$ICE/custom_phrase.txt" "$SHARED/"
cp -R "$ICE/cn_dicts" "$ICE/en_dicts" "$ICE/opencc" "$SHARED/"
# v0.1 没有 lua 插件，用雾凇自带的无 lua 方案
cp "$ICE/others/no_lua_schema/rime_ice.schema.yaml" "$SHARED/"

# 我们的默认设置：只保留全拼方案
cp "$ROOT/Rime/default.custom.yaml" "$USERDIR/"

DYLD_LIBRARY_PATH="$HOST/lib" "$HOST/bin/rime_deployer" --build "$USERDIR" "$SHARED" "$STAGING"

ls -lh "$STAGING"
test -f "$STAGING/rime_ice.prism.bin"
test -f "$STAGING/rime_ice.table.bin"
test -f "$STAGING/rime_ice.schema.yaml"
test -f "$STAGING/default.yaml"

rm -rf "$OUT"
mkdir -p "$OUT/build" "$OUT/opencc" "$OUT/en_dicts"
cp "$STAGING"/*.bin "$STAGING"/*.yaml "$OUT/build/"
cp "$SHARED/custom_phrase.txt" "$OUT/"
cp "$SHARED/en_dicts/cn_en.txt" "$OUT/en_dicts/"
cp "$SHARED"/opencc/* "$OUT/opencc/"

# 简繁转换：s2t.json 及其引用的 ocd2
OPENCC_SHARE="$HOST/share/opencc"
cp "$OPENCC_SHARE/s2t.json" "$OUT/opencc/"
for f in $(grep -o '"[A-Za-z_]*\.ocd2"' "$OPENCC_SHARE/s2t.json" | tr -d '"' | sort -u); do
  cp "$OPENCC_SHARE/$f" "$OUT/opencc/"
done

echo "rime-ice $RIME_ICE_REF, librime $(cat "$ROOT/Vendor/librime/VERSION")" > "$OUT/VERSION"
du -sh "$OUT" "$OUT"/*
ls -lh "$OUT/build"
