#!/bin/sh -ex

git clone 'https://git.citron-emu.org/Citron/Citron.git' ./citron

cd ./citron
git submodule update --init --recursive

COUNT="$(git rev-list --count HEAD)"
HASH="$(git rev-parse --short HEAD)"
DATE="$(date +"%Y%m%d")"
EXE_NAME="Citron-nightly-${DATE}-${COUNT}-${HASH}-android-universal"

case "$1" in
    msvc_optimize)
        echo "Making Citron Optimized Build for Windows"
        CMAKE_EXE_LINKER_FLAGS="-Wl,-O3 -Wl,--as-needed"
        CMAKE_CXX_FLAGS="-march=znver2 -mtune=znver2 -O3 -pipe -fno-plt -flto=auto -Wno-error -mfpmath=both"
        CMAKE_C_FLAGS="-march=znver2 -mtune=znver2 -O3 -pipe -fno-plt -flto=auto -Wno-error"
        CITRON_ENABLE_LTO=ON
        TARGET="Windows(MSVC)"
        ;;
    msvc_check)
        echo "Checking build"
        CITRON_USE_PRECOMPILED_HEADERS=OFF
        TARGET="Check(MSVC)"
        CCACHE="ccache"
        ;;
esac

mkdir build
cd build
cmake .. -GNinja \
    -DCITRON_USE_BUNDLED_VCPKG=ON \
    -DCITRON_USE_BUNDLED_QT=OFF \
    -DUSE_SYSTEM_QT=ON \
    -DCITRON_TESTS=OFF \
    -DCITRON_CHECK_SUBMODULES=OFF \
    -DCITRON_USE_LLVM_DEMANGLE=OFF \
    -DCITRON_USE_FASTER_LD=ON \
    -DENABLE_QT_TRANSLATION=ON \
    -DUSE_DISCORD_PRESENCE=OFF \
    -DSDL_PIPEWIRE=OFF \
    -DBUNDLE_SPEEX=ON \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_SYSTEM_PROCESSOR=x86_64 \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER_LAUNCHER="${CCACHE:-}" \
    -DCMAKE_CXX_COMPILER_LAUNCHER="${CCACHE:-}" \
    ${CITRON_ENABLE_LTO:+-DCITRON_ENABLE_LTO=$CITRON_ENABLE_LTO} \
    ${CITRON_USE_PRECOMPILED_HEADERS:+-DCITRON_USE_PRECOMPILED_HEADERS=$CITRON_USE_PRECOMPILED_HEADERS} \
    ${CMAKE_EXE_LINKER_FLAGS:+-DCMAKE_EXE_LINKER_FLAGS="$CMAKE_EXE_LINKER_FLAGS"} \
    ${CMAKE_CXX_FLAGS:+-DCMAKE_CXX_FLAGS="$CMAKE_CXX_FLAGS"} \
    ${CMAKE_C_FLAGS:+-DCMAKE_C_FLAGS="$CMAKE_C_FLAGS"}
ninja -j$(nproc)







