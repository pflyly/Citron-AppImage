# Citron-AppImage-Optimized-for-Steamdeck

This repository makes builds with several flags of optimization especially for **Steamdeck**.

* [Latest Normal Optimized Nightly Release](https://github.com/pflyly/Citron-AppImage/releases/latest)

---------------------------------------------------------------

Is this fork, AppImage made using original appimage-builder of citron directly instead of upstream using [sharun](https://github.com/VHSgunzo/sharun).

**This AppImage aim only for Steamdeck, so we don't need to bundle every lib, which can keep the final appimage as small as possible.**

It is possible that this appimage may fail to work with appimagelauncher, I recommend these alternatives instead: 

* [AM](https://github.com/ivan-hc/AM) `am -i citron` or `appman -i citron`

* [dbin](https://github.com/xplshn/dbin) `dbin install citron.appimage`

* [soar](https://github.com/pkgforge/soar) `soar install citron`

This appimage works without fuse2 as it can use fuse3 instead, it can also work without fuse at all thanks to the [uruntime](https://github.com/VHSgunzo/uruntime)
