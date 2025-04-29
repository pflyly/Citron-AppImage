<h1 align="left">
  <br>
  <a href="https://citron-emu.org"><img src="https://git.citron-emu.org/citron/emu/-/raw/master/dist/citron.ico" width="200"></a>
  <br>
  <b>Citron Nightly Release</b>
  <br>
</h1>

[![GitHub Release](https://img.shields.io/github/v/release/pflyly/Citron-AppImage?label=Current%20Release)](https://github.com/pflyly/Citron-AppImage/releases/latest)
[![GitHub Downloads](https://img.shields.io/github/downloads/pflyly/Citron-AppImage/total?logo=github&label=GitHub%20Downloads)](https://github.com/pflyly/Citron-AppImage/releases/latest)
[![CI Build Status](https://github.com//pflyly/Citron-AppImage/actions/workflows/build-nightly.yml/badge.svg)](https://github.com/pflyly/Citron-AppImage/releases/latest)

> [!IMPORTANT]
> This repository now makes nightly release of citron for Linux, Android and Windows.
>  
> For Linux we make AppImage with several flags of optimization especially for **Steamdeck** & **ROG ALLY X** & **Modern CPUs**(Common Build).
> 
> Windows version is built via MSVC.
> 
> **Android can't build for latest commit, only [one version](https://github.com/pflyly/Citron-Nightly/releases/tag/2025-04-25-48eed78d1) is available for now.**

* [**Latest Nightly Release Here**](https://github.com/pflyly/Citron-AppImage/releases/latest)

---------------------------------------------------------------

It is possible that this appimage may fail to work with appimagelauncher, I recommend these alternatives instead: 

* [AM](https://github.com/ivan-hc/AM) `am -i citron` or `appman -i citron`

* [dbin](https://github.com/xplshn/dbin) `dbin install citron.appimage`

* [soar](https://github.com/pkgforge/soar) `soar install citron`

This appimage works without fuse2 as it can use fuse3 instead, it can also work without fuse at all thanks to the [uruntime](https://github.com/VHSgunzo/uruntime)
