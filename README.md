Testing variants based on feedback from our local healthcare community.

This is based on:
https://www.prusaprinters.org/prints/25857-prusa-protective-face-shield-rc2
License: CC-BY-NC

A 3mf file is provided, so it can be loaded into slicer right away:

```
git clone https://github.com/hzeller/prusa-covid19-shield-remix.git
cd prusa-covid19-shield-remix
prusa-slicer prusa-covid-shield-remix.3mf
```

For building, use the Makefile to create all the artifacts from the *.scad
file

```
make
```