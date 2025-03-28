#!/bin/sh

set -ex

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="$(uname -m)"

REPO="https://git.citron-emu.org/Citron/Citron.git"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"

if [ "$ARCH" = 'x86_64' ]; then
	if [ "$1" = 'v3' ]; then
		echo "Making optimized build of citron for Steamdeck"
		ARCH_FLAGS="-march=znver2 -mtune=znver2 -O3 -ffast-math -flto=auto"
	fi
fi

UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"

# BUILD CITRON, fallback to mirror if upstream repo fails to clone
if ! git clone 'https://git.citron-emu.org/Citron/Citron.git' ./citron; then
	echo "Using mirror instead..."
	rm -rf ./citron || true
	git clone 'https://github.com/pkgforge-community/git.citron-emu.org-Citron-Citron.git' ./citron
fi

(
	cd ./citron
	if [ "$DEVEL" = 'true' ]; then
                COMM_COUNT="$(git rev-list --count HEAD)"
		COMM_HASH="$(git rev-parse --short HEAD)"
                BUILD_DATE="$(date +"%Y%m%d")"
		echo "Making nightly build"
		VERSION="nightly"
                COUNT="${COMM_COUNT}"
                HASH="${COMM_HASH}"
                DATE="${BUILD_DATE}"
	else
		CITRON_TAG=$(git describe --tags)
		BUILD_DATE="$(date +"%Y%m%d")"
		echo "Making stable \"$CITRON_TAG\" build"
		git checkout "$CITRON_TAG"
                COMM_COUNT="$(git rev-list --count HEAD)"
                COMM_HASH="$(git rev-parse --short HEAD)"
		VERSION="$(echo "$CITRON_TAG" | awk -F'-' '{print $1}')"
                COUNT="${COMM_COUNT}"
                HASH="${COMM_HASH}"
                DATE="${BUILD_DATE}"
	fi
	git submodule update --init --recursive -j$(nproc)

	#Replaces 'boost::asio::io_service' with 'boost::asio::io_context' for compatibility with Boost.ASIO versions 1.74.0 and later
	find src -type f -name '*.cpp' -exec sed -i 's/boost::asio::io_service/boost::asio::io_context/g' {} \;

	mkdir build
	cd build
	cmake .. -GNinja \
		-DCITRON_USE_BUNDLED_VCPKG=OFF \
		-DCITRON_USE_BUNDLED_QT=OFF \
		-DUSE_SYSTEM_QT=ON \
		-DCITRON_USE_BUNDLED_FFMPEG=OFF \
		-DCITRON_TESTS=OFF \
		-DCITRON_CHECK_SUBMODULES=OFF \
		-DCITRON_USE_LLVM_DEMANGLE=OFF \
                -DCITRON_USE_BUNDLED_SDL2=ON \
 		-DCITRON_USE_EXTERNAL_SDL2=OFF \
		-DCITRON_ENABLE_LTO=ON \
		-DENABLE_QT_TRANSLATION=ON \
		-DUSE_DISCORD_PRESENCE=OFF \
		-DBUNDLE_SPEEX=ON \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_CXX_FLAGS="$ARCH_FLAGS -Wno-error -Wno-comment" \
		-DCMAKE_C_FLAGS="$ARCH_FLAGS" \
		-DCMAKE_SYSTEM_PROCESSOR="$(uname -m)" \
		-DCMAKE_BUILD_TYPE=Release
	ninja
	sudo ninja install
	echo "$VERSION" >~/version
        echo "$COUNT" >~/count
        echo "$HASH" >~/hash
        echo "$DATE" >~/date
)
rm -rf ./citron
VERSION="$(cat ~/version)"
COUNT="$(cat ~/count)"
HASH="$(cat ~/hash)"
DATE="$(cat ~/date)"

# NOW MAKE APPIMAGE
mkdir ./AppDir
cd ./AppDir

cp -v /usr/share/applications/org.citron_emu.citron.desktop ./citron.desktop
cp -v /usr/share/icons/hicolor/scalable/apps/org.citron_emu.citron.svg ./citron.svg
ln -s ./citron.svg ./.DirIcon

if [ "$DEVEL" = 'true' ]; then
	sed -i 's|Name=citron|Name=citron nightly|' ./citron.desktop
	UPINFO="$(echo "$UPINFO" | sed 's|latest|nightly|')"
fi

# Bundle all libs
wget --retry-connrefused --tries=30 "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
xvfb-run -a -- ./lib4bin -p -v -e -s -k \
	/usr/bin/citron* \
	/usr/lib/libGLX* \
	/usr/lib/libGL.so* \
	/usr/lib/libEGL* \
	/usr/lib/dri/* \
	/usr/lib/libvulkan* \
	/usr/lib/libXss.so* \
	/usr/lib/libdecor-0.so* \
        /usr/lib/libSDL3.so* \
	/usr/lib/qt6/plugins/audio/* \
	/usr/lib/qt6/plugins/bearer/* \
	/usr/lib/qt6/plugins/imageformats/* \
	/usr/lib/qt6/plugins/iconengines/* \
	/usr/lib/qt6/plugins/platforms/* \
	/usr/lib/qt6/plugins/platformthemes/* \
	/usr/lib/qt6/plugins/platforminputcontexts/* \
	/usr/lib/qt6/plugins/styles/* \
	/usr/lib/qt6/plugins/xcbglintegrations/* \
	/usr/lib/qt6/plugins/wayland-*/* \
	/usr/lib/pulseaudio/* \
	/usr/lib/pipewire-0.3/* \
	/usr/lib/spa-0.2/*/* \
	/usr/lib/alsa-lib/*

# Prepare sharun
ln ./sharun ./AppRun
./sharun -g

# turn appdir into appimage
cd ..
wget -q "$URUNTIME" -O ./uruntime
chmod +x ./uruntime

# Keep the mount point (speeds up launch time)
sed -i 's|URUNTIME_MOUNT=[0-9]|URUNTIME_MOUNT=0|' ./uruntime

#Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
./uruntime --appimage-addupdinfo "$UPINFO"

echo "Generating AppImage..."
./uruntime --appimage-mkdwarfs -f \
	--set-owner 0 --set-group 0 \
	--no-history --no-create-timestamp \
	--compression zstd:level=22 -S24 -B16 \
	--header uruntime \
	-i ./AppDir -o Citron-"$VERSION"-"${DATE}"-"${COUNT}"-"${HASH}"-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage
echo "All Done!"
