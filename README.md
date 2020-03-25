Testing variants based on feedback from our local healthcare community.

This is based on:
https://www.prusaprinters.org/prints/25857-prusa-protective-face-shield-rc2
License: CC-BY-NC

### Slicer project file
A 3mf file is provided, so it can be loaded into slicer right away:

```
git clone https://github.com/hzeller/prusa-covid19-shield-remix.git
cd prusa-covid19-shield-remix
prusa-slicer prusa-covid-shield-remix.3mf
```

### GCode
There is also [gcode directly sliced for Prusa MK3(s)](prusa-covid-shield-remix-print_shield_0.3mm_PETG_MK3S.gcode)

### Development

For building, use the Makefile to create all the artifacts from the *.scad
file

```
make
```