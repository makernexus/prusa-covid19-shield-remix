// -*- mode: scad; c-basic-offset: 2; indent-tabs-mode:nil -*-
// Incoroprating some feedback from local healthcare providers
//   * weight-reducing of front-part if possible.
//   * Move the shield buttons up so that there is material behind the openings
//     of the shield-punches

$fn=32;
e=0.01;

// Running version number. Should align with v1.x release.
// Intermediate git release WIP add a '
version_number="3'";

front_hole_r = 5.5;   // TODO: if we use that with thinner bands: needs adjust

// mm to move the pin up
vertical_pin_shift=7;  // mm

// Experimental.
default_stack_height = 3;
stack_separation=0.3*4; // 4 layers if printing at 0.30mm;
provide_stack_separation_support=true;  // very experimental.

// supports
support_width=0.75;  // Calipers say that 0.5mm is S3D's thickness.  Add 0.25 more for safety.
perforation_fan_angle=4;  // was 8
perforation_height=stack_separation;
support_column_radius=4;

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
module light_headband(version_text="", h_scale=1,
                      do_front_punches=true, do_back_punches=true) {
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
module support_column(angle=0, dist=0, wall_thick=support_width,
                      is_first=true, is_last=true, is_thin=false) {
  r=support_column_radius;
  // distances were originally calibrated for r=5mm
  dist=dist-(5-support_column_radius);
  band_thick = get_band_thick(is_thin);
  level_thick=0.6;
  support_platform=vertical_pin_shift-0.3 - (is_thin ? 2.5 : 0);
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
    foot_width=0.6;
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
  // Cut out the area with the pins and move them up.
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
    rotate([0, 180, 0]) light_headband(h_scale=is_thin ? 0.75 : 1.0);
    for (x = pin_angle_distances) roi_block(x[0], x[1]);
  }

  // Combine the above that with the shield, but leave out the pin area
  // we were 'operating' on: that is now filled with our construct above.
  difference() {
    light_headband(version_text, h_scale=is_thin ? 0.75 : 1.0,
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

module perforation_fan(wide=support_width, high=perforation_height) {
  for (a = [-40:perforation_fan_angle:180+40]) rotate([0, 0, a]) cube([120, wide, high]);
}

module perforation_grid(wide=support_width, high=perforation_height) {
    space = 2.5;
    size = 200;
    for (i = [-size/2:space:size/2]) {
			translate([-size/2, i, 0]) {
				cube([size, wide, high]);  
            };
            translate([i, -size/2, 0]) {
				cube([wide, size, high]);
            };
	}
}
  
module perforation() {
  h=perforation_height;
  color("yellow") render() translate([0, 0, h]) intersection() {
    baseline_headband();
    translate([0, 0, 10-h]) perforation_fan(high=h);
    //translate([0, 0, 10-h]) perforation_grid(high=h);
  }
}

// Print a stack of face-shields.
module print_stack(count=default_stack_height, is_thin=false) {
  stack_distance = get_band_thick(is_thin) + stack_separation;
  for (i = [0:1:count-e]) {
    translate([0, 0, i*stack_distance]) {
      is_first = (i == 0);
      is_last = (i == (count - 1));
      print_shield("☰", pin_support=true,
                   is_first=is_first, is_last=is_last,
                   is_thin=is_thin, do_punches=!is_thin);
      if (provide_stack_separation_support && !is_last) perforation();
    }
  }
}

//-- Some functions which we use to generate named STLs directly from these.

module normal_shield_no_support() {
  print_shield("N", do_punches=true, pin_support=false);
}
module normal_shield_with_support() {
  print_shield("N", do_punches=true, pin_support=true);
}
module thin_shield_no_support() {
  print_shield("T", do_punches=false, pin_support=false, is_thin=true);
}
module thin_shield_with_support() {
  print_shield("T", do_punches=false, pin_support=true, is_thin=true);
}

module normal_stack3_with_support() {
  print_stack(3, is_thin=false);
}
module thin_stack3_with_support() {
  print_stack(3, is_thin=true);
}

normal_shield_with_support();
//print_stack(3, is_thin=false);
