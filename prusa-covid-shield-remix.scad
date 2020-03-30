// -*- mode: scad; c-basic-offset: 2; indent-tabs-mode:nil -*-
// Incoroprating some feedback from local healthcare providers
//   * weight-reducing of front-part if possible.
//   * Move the shield buttons up so that there is material behind the openings
//     of the shield-punches

$fn=32;
e=0.01;

// Running version number. Should align with v1.x release.
// Intermediate git release WIP add a '
version_number="5";

support_column_foot_thickness=1.2;  // support-column: this much extra wide foot
support_wall=0.5; // Use 0.5 if slicer can detect thin walls.
support_column_radius=4.5;

pin_diameter=5;  // mm
print_layer_height=0.3;   // Layer thickness we're printing

// Experimental stacking.
default_stack_height = 3;
stack_separation=print_layer_height;

// Size of the band depending on if we request it to be 'thin'
function get_band_thick(is_thin) = is_thin ? 15 : 20;

module maker_nexus_baseline_headband(version_text, is_thin=false) {
  file = str("baseline/RC2-nexusized-", (is_thin ? "thin":"normal"), ".stl");
  offset = -get_band_thick(is_thin) / 2;
  difference() {
    translate([0, 20, offset]) import(file, convexity=10);
    // Maker nexus version number.
    translate([87, -25, 0]) union() {
      translate([0, 0, 1]) rotate([90, 0, 90]) linear_extrude(height=1) text("M", size=5, halign="center", font="style:Bold");
      translate([0, 0, -6]) rotate([90, 0, 90]) linear_extrude(height=1) text("N", size=6, halign="center", font="style:Bold");
      translate([0, 4, -4]) rotate([90, 0, 90]) linear_extrude(height=1)
        text(str(version_text, version_number),
             size=8, halign="left", font="style:Bold");
    }

    // Prusa + Adafruit Attribution
    translate([-87, -12, -5]) rotate([90, 0, -90]) union() {
      translate([0, 3.5, 0]) linear_extrude(height=1) text("Prusa", size=8, halign="center", font="style:Bold");
      translate([-0.4, -1.5, 0]) linear_extrude(height=1) text("+Adafruit", size=4, halign="center", font="style:Bold");
    }

    translate([75, -25, -12]) rotate([90, 0, 90]) scale([-0.12, 0.12, 0.1]) surface("img/maker-nexus.png");
  }
}

// Support for the pins.
module support_column(angle=0, dist=0, wall_thick=support_wall,
                      is_first=true, is_last=true, is_thin=false) {
  r=support_column_radius;
  // distances were originally calibrated for r=5mm
  dist=dist-(5-support_column_radius);
  band_thick = get_band_thick(is_thin);
  level_thick=0.6;
  support_platform = (get_band_thick(is_thin) - pin_diameter)/2 - print_layer_height;
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
pin_angle_distances = [ [18.5, 94], [-18.5, 94], [69, 100.5], [-69, 100.5]];

module print_shield(version_text, do_punches=true, pin_support=false,
                    is_thin=false, is_first=true, is_last=true) {
  maker_nexus_baseline_headband(version_text, is_thin);
  // Add support for the pins.
  if (pin_support) {
    for (x = pin_angle_distances) support_column(x[0], x[1],
                                                 is_thin=is_thin,
                                                 is_last=is_last,
                                                 is_first=is_first);
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

// Local testing call. Can be left in, it will be ignored in the Makefile.
thin_shield_with_support();
//print_stack(3, is_thin=true);
