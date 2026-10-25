#!/bin/bash
# 在 macOS 上从源码编译 librime（只在 CI 上跑）：
#   1. iOS arm64 静态库  → Vendor/librime/{include,lib}
#   2. macOS 本机 rime_deployer → Vendor/host/，用来在 CI 里预编译雾凇词库
# 两者同一份源码，保证词库二进制格式一致。
set -euxo pipefail

RIME_VERSION="${RIME_VERSION:-1.17.0}"
IOS_MIN="${IOS_MIN:-16.0}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$ROOT/build/librime-src"
HOST="$WORK/prefix-host"
IOS="$WORK/prefix-ios"
OUT="$ROOT/Vendor/librime"
OUT_HOST="$ROOT/Vendor/host"

command -v ninja >/dev/null || brew install ninja
export CMAKE_GENERATOR=Ninja

rm -rf "$WORK"
git clone --depth 1 --branch "$RIME_VERSION" \
  --recurse-submodules --shallow-submodules \
  https://github.com/rime/librime "$WORK"
cd "$WORK"

# boost 只用头文件
export BOOST_ROOT="$WORK/deps/boost"
./install-boost.sh

# ---------- 1. macOS 本机：依赖 + librime（带 rime_deployer） ----------
make -f deps.mk glog leveldb marisa-trie opencc yaml-cpp prefix="$HOST" build=build-host

cmake -S . -B build-host \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="$HOST" \
  -DBOOST_ROOT="$BOOST_ROOT" -DBoost_NO_BOOST_CMAKE=TRUE \
  -DBUILD_TEST=OFF \
  -DBUILD_MERGED_PLUGINS=OFF \
  -DENABLE_EXTERNAL_PLUGINS=OFF \
  -DALSO_LOG_TO_STDERR=ON
cmake --build build-host

rm -rf "$OUT_HOST"
mkdir -p "$OUT_HOST/bin" "$OUT_HOST/lib" "$OUT_HOST/share"
cp build-host/bin/rime_deployer "$OUT_HOST/bin/"
cp -a build-host/lib/librime*.dylib "$OUT_HOST/lib/"
cp -R "$HOST/share/opencc" "$OUT_HOST/share/"
# 运行时用 DYLD_LIBRARY_PATH=Vendor/host/lib 找到 librime.dylib
DYLD_LIBRARY_PATH="$OUT_HOST/lib" "$OUT_HOST/bin/rime_deployer" --help || true

# ---------- 2. iOS arm64：依赖 + librime 静态库 ----------
IOS_FLAGS=(
  -DCMAKE_SYSTEM_NAME=iOS
  -DCMAKE_OSX_SYSROOT=iphoneos
  -DCMAKE_OSX_ARCHITECTURES=arm64
  -DCMAKE_OSX_DEPLOYMENT_TARGET="$IOS_MIN"
  -DCMAKE_MACOSX_BUNDLE=OFF
  -DCMAKE_BUILD_TYPE=Release
  -DBUILD_SHARED_LIBS=OFF
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON
  -DCMAKE_INSTALL_PREFIX="$IOS"
  -DCMAKE_PREFIX_PATH="$IOS"
  -DCMAKE_FIND_ROOT_PATH="$IOS"
  -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH
  -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH
  -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH
  -DCMAKE_CXX_FLAGS="-I$IOS/include"
)

ios_dep() {
  local name="$1"; shift
  cmake -S "deps/$name" -B "deps/$name/build-ios" "${IOS_FLAGS[@]}" "$@"
}

ios_dep yaml-cpp \
  -DYAML_CPP_BUILD_CONTRIB=OFF -DYAML_CPP_BUILD_TESTS=OFF -DYAML_CPP_BUILD_TOOLS=OFF
cmake --build deps/yaml-cpp/build-ios --target install

ios_dep leveldb \
  -DLEVELDB_BUILD_TESTS=OFF -DLEVELDB_BUILD_BENCHMARKS=OFF \
  -DHAVE_CRC32C=OFF -DHAVE_SNAPPY=OFF -DHAVE_TCMALLOC=OFF
cmake --build deps/leveldb/build-ios --target install

ios_dep marisa-trie \
  -DBUILD_TESTING=OFF -DENABLE_TOOLS=OFF -DENABLE_NATIVE_CODE=OFF
cmake --build deps/marisa-trie/build-ios --target install

# OpenCC：交叉编译时它会尝试运行自己编出的工具生成词典，所以只编库，手动安装头文件。
ios_dep opencc \
  -DUSE_SYSTEM_MARISA=ON \
  -DBUILD_OPENCC_JIEBA_PLUGIN=OFF -DENABLE_GTEST=OFF -DENABLE_BENCHMARK=OFF \
  -DBUILD_DOCUMENTATION=OFF -DBUILD_PYTHON=OFF
cmake --build deps/opencc/build-ios --target libopencc
mkdir -p "$IOS/include/opencc" "$IOS/lib"
cp deps/opencc/src/*.hpp deps/opencc/src/opencc.h "$IOS/include/opencc/"
find deps/opencc/build-ios/src -maxdepth 1 \( -name '*.h' -o -name '*.hpp' \) -exec cp {} "$IOS/include/opencc/" \;
find deps/opencc/build-ios -name 'libopencc.a' -exec cp {} "$IOS/lib/" \;

cmake -S . -B build-ios "${IOS_FLAGS[@]}" \
  -DBUILD_STATIC=ON \
  -DBUILD_TEST=OFF \
  -DENABLE_LOGGING=OFF \
  -DBUILD_MERGED_PLUGINS=ON \
  -DENABLE_EXTERNAL_PLUGINS=OFF \
  -DBOOST_ROOT="$BOOST_ROOT" -DBoost_NO_BOOST_CMAKE=TRUE -DBoost_INCLUDE_DIR="$BOOST_ROOT" \
  -DCMAKE_CXX_FLAGS="-I$IOS/include -I$BOOST_ROOT -DBOOST_DLL_USE_STD_FS" \
  -DYamlCpp_INCLUDE_PATH="$IOS/include" -DYamlCpp_NEW_API="$IOS/include" \
  -DYamlCpp_LIBRARY="$IOS/lib/libyaml-cpp.a" \
  -DLevelDb_INCLUDE_PATH="$IOS/include" -DLevelDb_LIBRARY="$IOS/lib/libleveldb.a" \
  -DMarisa_INCLUDE_PATH="$IOS/include" -DMarisa_LIBRARY="$IOS/lib/libmarisa.a" \
  -DOpencc_INCLUDE_PATH="$IOS/include" -DOpencc_LIBRARY="$IOS/lib/libopencc.a"
cmake --build build-ios --target rime-static

rm -rf "$OUT"
mkdir -p "$OUT/include" "$OUT/lib"
cp src/rime_api.h "$OUT/include/"
cp build-ios/lib/librime.a "$OUT/lib/"
for lib in yaml-cpp leveldb marisa opencc; do
  cp "$IOS/lib/lib$lib.a" "$OUT/lib/"
done
for lib in "$OUT"/lib/*.a; do
  lipo -info "$lib"
done
echo "$RIME_VERSION" > "$OUT/VERSION"
ls -lh "$OUT/lib" "$OUT_HOST/bin" "$OUT_HOST/lib"
