#!/bin/sh

set -ex

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="$(uname -m)"

URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"
EXTRA_FLAGS="-O3 -pipe -fno-plt -flto=auto -Wno-error"
case "$1" in
    steamdeck)
        echo "Making Citron Optimized Build for Steam Deck"
        ARCH_FLAGS="-march=znver2 -mtune=znver2"
        TARGET="Steamdeck"
	OPTIMIZE_FLAGS=(-DCITRON_ENABLE_LTO=ON \
 			-DCMAKE_CXX_FLAGS="$ARCH_FLAGS $EXTRA_FLAGS -mfpmath=both" \
    			-DCMAKE_C_FLAGS="$ARCH_FLAGS $EXTRA_FLAGS" \
       			-DCMAKE_EXE_LINKER_FLAGS="-Wl,-O3 -Wl,--as-needed" )
        ;;
    rog)
        echo "Making Citron Optimized Build for ROG Ally X"
        ARCH_FLAGS="-march=znver4 -mtune=znver4"
        TARGET="ROG_Ally_X"
	OPTIMIZE_FLAGS=(-DCITRON_ENABLE_LTO=ON \
 			-DCMAKE_CXX_FLAGS="$ARCH_FLAGS $EXTRA_FLAGS -mfpmath=both" \
    			-DCMAKE_C_FLAGS="$ARCH_FLAGS $EXTRA_FLAGS" \
       			-DCMAKE_EXE_LINKER_FLAGS="-Wl,-O3 -Wl,--as-needed" )
        ;;
    common)
        echo "Making Citron Optimized Build for Modern CPUs"
        ARCH_FLAGS="-march=x86-64-v3"
        ARCH="${ARCH}_v3"
        TARGET="Common"
	OPTIMIZE_FLAGS=(-DCITRON_ENABLE_LTO=ON \
 			-DCMAKE_CXX_FLAGS="$ARCH_FLAGS $EXTRA_FLAGS -mfpmath=both" \
    			-DCMAKE_C_FLAGS="$ARCH_FLAGS $EXTRA_FLAGS" \
       			-DCMAKE_EXE_LINKER_FLAGS="-Wl,-O3 -Wl,--as-needed" )
        ;;
    check)
        echo "Checking build"
	ARCH_FLAGS=""
 	CCACHE="ccache"
  	OPTIMIZE_FLAGS=("")
        ;;
esac

UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"

# BUILD CITRON, fallback to mirror if upstream repo fails to clone
if ! git clone 'https://git.citron-emu.org/Citron/Citron.git' ./citron; then
	echo "Using mirror instead..."
	rm -rf ./citron || true
	git clone 'https://github.com/pkgforge-community/git.citron-emu.org-Citron-Citron.git' ./citron
fi

cd ./citron
COUNT="$(git rev-list --count HEAD)"
HASH="$(git rev-parse --short HEAD)"
DATE="$(date +"%Y%m%d")"
git submodule update --init --recursive -j$(nproc)

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
  	-DCMAKE_C_COMPILER_LAUNCHER="$CCACHE" \
   	-DCMAKE_CXX_COMPILER_LAUNCHER="$CCACHE" \
    	"${OPTIMIZE_FLAG}"

ninja -j$(nproc)
echo "$HASH" >~/hash
echo "$(cat ~/hash)"

# Use citron appimage-builder.sh to generate AppDir
cd ..
chmod +x ./appimage-builder.sh
./appimage-builder.sh citron ./build
rm -rf ./build/deploy-linux/citron*.AppImage # Delete the generated appimage, cause it's useless now
cp /usr/lib/libSDL3.so* ./build/deploy-linux/AppDir/usr/lib/ # Copying libsdl3 to target AppDir

# Prepare uruntime
cd ..
wget -q "$URUNTIME" -O ./uruntime
chmod +x ./uruntime

# Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
./uruntime --appimage-addupdinfo "$UPINFO"

# Turn AppDir into appimage
echo "Generating AppImage..."
./uruntime --appimage-mkdwarfs -f --set-owner 0 --set-group 0 --no-history --no-create-timestamp --compression zstd:level=22 -S26 -B32 \
		--header uruntime -i ./citron/build/deploy-linux/AppDir -o Citron-nightly-"${DATE}"-"${COUNT}"-"${HASH}"-"${TARGET}"-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage

echo "All Done!"
