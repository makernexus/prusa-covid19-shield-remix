MakerNexus local modifications
------------------------------

At [MakerNexus], we're working on making as many face-shields as possible;
They will be in dire demand very soon and we got requests of thousands of them.
MakerNexus is coordinating the contact with the local hospitals and
as well the effort of non-Members of the maker-space to 3D print. We
have enough shield material to laser-cut, but of course 3D printing is the
slow part of manufacturing.

Please check out the [project page] if you are in the San Francisco
Bay Area and want to help.

We are using the [Prusa-rc3] design, but needed some modifications requested
by the local healthcare community.

### Design goals

When reviewing, the local healthcare providers requested

   * Weight-reduce front-part if possible.
   * Move the shield pins up so that there is material behind the openings
     of the shield-punches

Moving up the shield-pin requires a little bit of support material, but it
is not a problem to generate the necessary STL file where the supports should
be and use that in the Prusa slicer as support modifier.

### Download

Choose what bests fits your circumstances. GCode is 'ready to go', 3mf allows
printer adjustments, *.stl allows to use in your own slicer.

Simply get the [latest release](https://github.com/hzeller/prusa-covid19-shield-remix/releases). Current release is 1.0.

#### Release content
  * prusa-covid-shield-remix-print_shield_0.3mm_PETG_MK3S.gcode: GCode for MK3S printer for PETG 0.3mm, 3 shells, 30% infill - You can use this directly in your Prusa MK3/MK3S printer. I change the print speed to 130% on the printer and the output is still excellent. Print time ~4:30h with 130% speed.
  * prusa-covid-shield-remix.3m 3MF file to load in slicer. Contains support-material setup.
  * [The STL file](./prusa-covid-shield-remix-print_shield.stl). If you use this file in your slicer, you have to add support under the face-shield pins manually (there is also the [`prusa-covid-shield-remix-support_modifier.stl`](./prusa-covid-shield-remix-support_modifier.stl) file which provides the exact block places where supports need to be if your slicer can use that).

#### Latest in github. Possibly next release.
 * [normal_shield_no_support.stl](./normal_shield_no_support.stl) and
   [normal_shield_with_support.stl](./normal_shield_with_support.stl): normal
   shield, with upright hex-hole orientation.
 * [short_shield_no_support.stl](./short_shield_no_support.stl) and
   [short_shield_with_support.stl](./short_shield_with_support.stl): shield that
   is 15mm instead of 20mm high for faster printing.
 * [normal_shield.3mf](./normal_shield.3mf) and
   [short_shield.3mf](./short_shield.3mf) for direct use in prusa-slicer
 * [normal_shield_0.3mm_PETG_MK3S.gcode](./normal_shield_0.3mm_PETG_MK3S.gcode)
   and
   [short_shield_0.3mm_PETG_MK3S.gcode](./short_shield_0.3mm_PETG_MK3S.gcode)

### Code

A simple OpenSCAD file that take the original STL and does the necessary
surgical changes.

### Slicer project file
A 3mf file is provided, so it can be loaded into slicer right away:

```
git clone https://github.com/hzeller/prusa-covid19-shield-remix.git
cd prusa-covid19-shield-remix
prusa-slicer prusa-covid-shield-remix.3mf
```

Support is needed, but only minimally, and it breaks off easily. The STL for
the support enforcers is also generated from the OpenSCAD file.

![Showing weight reducing holes and support material](img/minimal-support.png)

### GCode
There is also [gcode directly sliced for Prusa MK3(s)](prusa-covid-shield-remix-print_shield_0.3mm_PETG_MK3S.gcode) that prints two headbands on the
build-plate.

### Development

For building, use the Makefile to create all the artifacts from the *.scad
file

```
make
```

### License

License: [CC-BY-NC]

This is based on the Prusa design
https://www.prusaprinters.org/prints/25857-prusa-protective-face-shield-rc2

[MakerNexus]: https://www.makernexus.com/
[prusa-rc3]: https://www.prusaprinters.org/prints/25857-prusa-protective-face-shield-rc3
[CC-BY-NC]: https://creativecommons.org/licenses/by-nc/4.0/
[project page]: http://makernexuswiki.com/index.php?title=3D_printed_face_shields
[prusa-slicer]: https://www.prusa3d.com/prusaslicer/