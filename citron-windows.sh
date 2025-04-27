#!/bin/bash -ex

find_windeployqt() {
    if command -v windeployqt >/dev/null 2>&1; then
        echo "windeployqt"
        return
    fi

    QT_DIRS=(
        "/c/Qt"
        "C:/Qt"
        "/usr/local/Qt"
    )

    for base in "${QT_DIRS[@]}"; do
        if [ -d "$base" ]; then
            # Find windeployqt.exe inside Qt folder
            WINDEPLOYQT=$(find "$base" -name "windeployqt.exe" | head -n 1)
            if [ -n "$WINDEPLOYQT" ]; then
                echo "$WINDEPLOYQT"
                return
            fi
        fi
    done

    echo "Error: windeployqt not found!" >&2
    exit 1
}

git clone 'https://git.citron-emu.org/Citron/Citron.git' ./citron

cd ./citron
git submodule update --init --recursive

COUNT="$(git rev-list --count HEAD)"
HASH="$(git rev-parse --short HEAD)"
DATE="$(date +"%Y%m%d")"

case "$1" in
    msvc)
        echo "Making Citron for Windows (MSVC)"
        if ! echo "$PATH" | grep -q "/c/ProgramData/chocolatey/bin"; then
            export PATH="$PATH:/c/ProgramData/chocolatey/bin"
        fi
        echo "PATH is: $PATH"
        TARGET="Windows-MSVC"
        EXTRA_CXX_FLAGS="/MP"
        ;;
    msys2)
        echo "Making Citron for Windows (MSYS2)"
        echo "Patching bootstrap.sh to add shebang"
        sed -i '1s;^;#!/usr/bin/bash\n;' externals/libusb/libusb/bootstrap.sh
        chmod +x externals/libusb/libusb/bootstrap.sh
        TARGET="Windows-MSYS2"
        EXTRA_CXX_FLAGS=""
        ;;
esac
EXE_NAME="Citron-nightly-${DATE}-${COUNT}-${HASH}-${TARGET}"

mkdir build
cd build
cmake .. -G Ninja \
    -DCITRON_TESTS=OFF \
    -DCITRON_USE_PRECOMPILED_HEADERS=OFF \
    -DENABLE_QT_TRANSLATION=ON \
    -DUSE_DISCORD_PRESENCE=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER_LAUNCHER=ccache \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_CXX_FLAGS="$EXTRA_CXX_FLAGS"
ninja
ccache -s -v

# Use windeployqt to gather dependencies
EXE_PATH=$(find ./ -type f -name "*.exe" | head -n 1)
if [ ! -f "$EXE_PATH" ]; then
    echo "Error: .exe not found!"
    exit 1
fi
mkdir deploy
cp "$EXE_PATH" deploy/
WINDEPLOYQT_BIN=$(find_windeployqt)
"$WINDEPLOYQT_BIN" --no-compiler-runtime --release --dir deploy "$EXE_PATH"

if [ "$1" = "msys2" ]; then
    if command -v strip >/dev/null 2>&1; then
            strip -s deploy/*.exe || true
    fi        
fi

# Pack for upload
mkdir -p artifacts
mkdir "$EXE_NAME"
cp -r deploy/* "$EXE_NAME"
ZIP_NAME="$EXE_NAME.zip"

if [ "$1" = "msvc" ]; then
    powershell Compress-Archive "$EXE_NAME" "$ZIP_NAME"
else
    zip -r "$ZIP_NAME" "$EXE_NAME"
fi

mv "$ZIP_NAME" artifacts/

echo "Build completed successfully."
