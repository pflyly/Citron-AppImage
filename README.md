# Citron-AppImage-Optimized-for-Steamdeck

This repository makes builds with several flags of optimization especially for **Steamdeck**.

Another **PGO** optimization Build will be built locally via Citron_PGO_maker.sh script(which can be found in this repo) on a Steamdeck Oled and add to the relase page manually.

Due the complexity of PGO two phase building, it can't be built automatically through CI for now.

* [Latest Nightly Release](https://github.com/pflyly/Citron-AppImage/releases/tag/nightly)
* [Latest Stable Release](https://github.com/pflyly/Citron-AppImage/releases/latest)


---------------------------------------------------------------

AppImage made using [sharun](https://github.com/VHSgunzo/sharun), which makes it extremely easy to turn any binary into a portable package without using containers or similar tricks.

**This AppImage bundles everything and should work on any linux distro, even on musl based ones.**

It is possible that this appimage may fail to work with appimagelauncher, I recommend these alternatives instead: 

* [AM](https://github.com/ivan-hc/AM) `am -i citron` or `appman -i citron`

* [dbin](https://github.com/xplshn/dbin) `dbin install citron.appimage`

* [soar](https://github.com/pkgforge/soar) `soar install citron`

This appimage works without fuse2 as it can use fuse3 instead, it can also work without fuse at all thanks to the [uruntime](https://github.com/VHSgunzo/uruntime)
