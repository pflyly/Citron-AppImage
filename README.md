# Citron-Optimized-AppImage

![GitHub Release](https://img.shields.io/github/v/release/pflyly/Citron-AppImage?label=Current%20Release)
![GitHub Downloads](https://img.shields.io/github/downloads/pflyly/Citron-AppImage/total?logo=github&label=GitHub%20Downloads) 
![CI Build Status](https://github.com//pflyly/Citron-AppImage/actions/workflows/build-nightly.yml/badge.svg)

This repository makes builds with several flags of optimization especially for **Steamdeck** & **ROG ALLY X** & **Modern CPUs**(Common Build).

* [Latest Optimized Nightly Release](https://github.com/pflyly/Citron-AppImage/releases/latest)

---------------------------------------------------------------

In this fork, AppImage is made using original appimage-builder.sh of citron directly instead of upstream using [sharun](https://github.com/VHSgunzo/sharun).

It is possible that this appimage may fail to work with appimagelauncher, I recommend these alternatives instead: 

* [AM](https://github.com/ivan-hc/AM) `am -i citron` or `appman -i citron`

* [dbin](https://github.com/xplshn/dbin) `dbin install citron.appimage`

* [soar](https://github.com/pkgforge/soar) `soar install citron`

This appimage works without fuse2 as it can use fuse3 instead, it can also work without fuse at all thanks to the [uruntime](https://github.com/VHSgunzo/uruntime)
