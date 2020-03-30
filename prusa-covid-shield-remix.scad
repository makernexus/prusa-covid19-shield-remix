// -*- mode: scad; c-basic-offset: 2; indent-tabs-mode:nil -*-
// Incoroprating some feedback from local healthcare providers
//   * weight-reducing of front-part if possible.
//   * Move the shield buttons up so that there is material behind the openings
//     of the shield-punches

$fn=32;
e=0.01;

// Running version number. Should align with v1.x release.
// Intermediate git release WIP add a '
version_number="4";

front_hole_r = 5.5;   // TODO: if we use that with thinner bands: needs adjust

support_column_foot_thickness=1.2;  // support-column: this much extra wide foot
support_wall=0.5; // Use 0.5 if slicer can detect thin walls.

// mm to move the pin up
vertical_pin_shift=7;  // mm

print_layer_height=0.3;   // Layer thickness we're printing

// Experimental stacking.
default_stack_height = 3;
provide_stack_separation_support=false;    // very experimental.
stack_separation=(provide_stack_separation_support ? 4 : 1)
  * print_layer_height;  // With support, 4 layers if printing at 0.30mm;

// Support between stack layers
stack_support_width=support_wall;
perforation_fan_angle=4.1;
perforation_height=stack_separation;
support_column_radius=4.5;

// Size of the band depending on if we request it to be 'thin'
function get_band_thick(is_thin) = is_thin ? 15 : 20;

module baseline_headband() {
  // The distribted STL file is pretty shifted...
  translate([7.8, 9, 2.5]) import("baseline/covid19_headband_rc3.stl", convexity=10);
}

module maker_nexus_baseline_headband(version_text, height_scale=1.0) {
  difference() {
    scale([1, 1, height_scale]) baseline_headband();

    // Maker nexus version number.
    translate([85.4, -37, 0.5]) {
      rotate([90, 0, -90]) linear_extrude(height=10) text("M", size=5, halign="center", font="style:Bold");
      translate([0, 0, -7]) rotate([90, 0, -90]) linear_extrude(height=10) text("N", size=6, halign="center", font="style:Bold");
    }
    translate([85.7, -60, -4]) rotate([90, 0, -90]) linear_extrude(height=10)
      text(str(version_text, version_number),
           size=8, halign="right", font="style:Bold");
  }
}

module hole_punch(angle=0, r=front_hole_r, dist=70) {
  rotate([0, 0, angle]) translate([0, dist, 0])
    rotate([-90, 0, 0]) cylinder(r=r, h=20, $fn=6);
}

// A headband that is lighter due to cutout-holes
module light_headband(version_text="", is_thin=false,
                      do_front_punches=true, do_back_punches=true) {
  h_scale = get_band_thick(is_thin) / get_band_thick(false);
  angle_distance=11;  // degrees at which we punch our weight-reduce hole.
  difference() {
    maker_nexus_baseline_headband(version_text=version_text,
                                  height_scale=h_scale);
    if (do_front_punches) {
      for (i = [-4:1:+4]) {
        // Punch holes exect in places of need of stabiliity.
        if (abs(i) != 2) hole_punch(i * angle_distance, r=front_hole_r, dist=70);
      }

      if (do_back_punches) {
        translate([0, -40, 0]) for (i = [-7:1:+7]) {
          hole_punch(i * 10, r=front_hole_r-0.5, dist=68);
        }
      }
    }
  }
}

// Support for the pins.
module support_column(angle=0, dist=0, wall_thick=support_wall,
                      is_first=true, is_last=true, is_thin=false) {
  r=support_column_radius;
  // distances were originally calibrated for r=5mm
  dist=dist-(5-support_column_radius);
  band_thick = get_band_thick(is_thin);
  relative_below = (get_band_thick(false) - band_thick) / 2;
  level_thick=0.6;
  support_platform=vertical_pin_shift - print_layer_height - relative_below;
  h=is_last ? support_platform : band_thick + stack_separation;

  color("yellow") rotate([0, 0, angle]) translate([0, dist, -band_thick/2])
    rotate([0, 0, 180]) {
    intersection() {
      translate([-r, -r-2.5, 0]) cube([2*r, 2*r, h]);
      union() {
        difference() {
          union() {
            cylinder(r=r, h=h);  // Column
            translate([-r, 0, 0]) cube([2*r, 0.5*r, h]); // .. flattened
          }
          translate([0, 0, -e]) union() {  // Remove inside
            translate([0, 0, 0]) cylinder(r=r-wall_thick, h=h+2*e);
            translate([-(r-wall_thick), 0, 0]) cube([2*(r-wall_thick), r, h+2*e]);
          }
        }

        // The 'shelf' part.
        translate([0, -0.5, support_platform-level_thick]) {
          translate([-r, 0, 0]) cube([2*r, 3, level_thick]);
          cylinder(r=r-wall_thick, h=level_thick);
        }
      }
    }


    // Some stability foot if we're first. Don't make it entirely solid, as
    // that seems to be too well connected to the build-bed.
    foot_width=support_column_foot_thickness/2;
    if (is_first) intersection() {
      translate([-15/2, -7.5, 0]) cube([15, 10, 1]);
      union() {
        difference() {
          cylinder(r=r+foot_width, h=0.3);
          translate([0, 0, -e]) cylinder(r=r-foot_width-wall_thick, h=0.3+2*e);
        }
        translate([-(r+foot_width), 1, 0]) cube([2*(r+foot_width), 1.5, 0.3]);
      }
    }
  }
}

// The angle and distance the pins. We only need some rough position,
// as we just use this as a cut-out where we do the material-move operation.
// There we just move the bottom part up and replace the bottom part with
// what we found above (angles, positions determined empirically)
pin_angle_distances = [ [21.5, 80], [-21.5, 80], [76, 93], [-76, 93]];

module shield_pin_vertical_cutout(extra=0) {
  b_size = 10 + extra;
  translate([0, 0, -10+b_size/2]) cube([b_size, 15, b_size], center=true);
}

// A region of interest at the given angle and distance.
module roi_block(angle, dist, extra=0) {
  rotate([0, 0, angle]) translate([0, dist, 0])
    shield_pin_vertical_cutout(extra);
}

module print_shield(version_text, do_punches=true, pin_support=false,
                    is_thin=false, is_first=true, is_last=true) {
  // Cut out the area with the pins and move them up so that they are
  // centered around the zero plane. We take them from the baseline headband
  // not from the 'squished' one for the scaled version.
  translate([0, 0, vertical_pin_shift]) intersection() {
    baseline_headband();  // Baseline has the right sized pins.
    for (x = pin_angle_distances) roi_block(x[0], x[1]);
  }

  // Now, take the _top_ part of the band by doing the same cut-out ont
  // the same band lying on its back and use that to fill the hole at
  // the bottom left from the pin being shifted up.
  // Using the rotational cut-out means we capture the taper the band
  // has and replicate it fully at the bottom.
  intersection() {
    rotate([0, 180, 0]) light_headband(is_thin=is_thin);
    for (x = pin_angle_distances) roi_block(x[0], x[1]);
  }

  // Combine the above that with the shield, but leave out the pin area
  // we were 'operating' on: that is now filled with our construct above.
  difference() {
    light_headband(version_text, is_thin=is_thin,
                   do_front_punches=do_punches, do_back_punches=do_punches);
    for (x = pin_angle_distances) roi_block(x[0], x[1], extra=-1);
  }

  // Add support for the pins.
  if (pin_support) {
    for (x = pin_angle_distances) support_column(x[0], x[1]+3,
                                                 is_thin=is_thin,
                                                 is_last=is_last,
                                                 is_first=is_first);
  }
}

module perforation_fan(wide=stack_support_width, high=perforation_height) {
    start = 35;  // Start right at the edge of the end of the bracket.
    sweep = 110;
    for (a = [-start:perforation_fan_angle:start+sweep/2]) rotate([0, 0, a]) #cube([120, wide, high]);
    for (a = [start+180:-perforation_fan_angle:180-sweep]) rotate([0, 0, a]) #cube([120, wide, high]);
}

module perforation_tail(wide=stack_support_width, high=perforation_height) {
    for (offset = [0:2:6]) translate([-120, -61+offset, 0]) #cube([105*2, wide, high]);
}


module perforation(is_thin=false) {
  h=perforation_height;
  place_on_top = get_band_thick(is_thin) / 2;
  color("yellow") render() translate([0, 0, h-10+place_on_top]) intersection() {
    baseline_headband();
    translate([0, 0, 10-h]) perforation_fan(high=h);
   }
  color("yellow") render() translate([0, 0, h-10+place_on_top]) intersection() {
    baseline_headband();
    translate([0, 0, 10-h]) perforation_tail(high=h);
  }
}

// Print a stack of face-shields.
module print_stack(count=default_stack_height, is_thin=false) {
  stack_distance = get_band_thick(is_thin) + stack_separation;
  base_version = str("s", is_thin ? "t" : "");
  for (i = [0:1:count-e]) {
    translate([0, 0, i*stack_distance]) {
      is_first = (i == 0);
      is_last = (i == (count - 1));
      print_shield(base_version, pin_support=true,
                   is_first=is_first, is_last=is_last,
                   is_thin=is_thin, do_punches=!is_thin);
      if (provide_stack_separation_support && !is_last) perforation(is_thin);
    }
  }
}


/* Some functions which we use to generate named
 * STLs directly in the Makefile
 */
module normal_shield_no_support() {
  print_shield("N", do_punches=false, pin_support=false);
}
module normal_shield_with_support() {
  print_shield("N", do_punches=false, pin_support=true);
}
module thin_shield_no_support() {
  print_shield("T", do_punches=false, pin_support=false, is_thin=true);
}
module thin_shield_with_support() {
  print_shield("T", do_punches=false, pin_support=true, is_thin=true);
}

module normal_stack_with_support() {
  print_stack(default_stack_height, is_thin=false);
}
module thin_stack_with_support() {
  print_stack(default_stack_height, is_thin=true);
}
module thin_stack6_with_support() {
  print_stack(6, is_thin=true);
}

// Local testing call. Can be left in, it will be ignored in the Makefile.
normal_shield_with_support();
//print_stack(3, is_thin=true);
