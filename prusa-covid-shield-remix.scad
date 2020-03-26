// -*- mode: scad; c-basic-offset: 2; indent-tabs-mode:nil -*-
// Incoroprating some feedback from local healthcare providers
//   * weight-reducing of front-part if possible.
//   * Move the shield buttons up so that there is material behind the openings
//     of the shield-punches

// mm to move the pin up
vertical_pin_shift=7;  // mm
version="1.1";   // Keep it short, so that it only is on the flat end.

module baseline_headband() {
  // The distribted RC2 STL file is pretty shifted...
  translate([-844.5, 0, 0]) import("baseline/covid19_headband_rc2.stl", convexity=10);
}

module hole_punch(angle=0, r=6, from_bottom=0) {
  rotate([0, 0, angle]) translate([0, 70, from_bottom])
    rotate([-90, 0, 0]) cylinder(r=r, h=20, $fn=6);
}

// A headband that is lighter due to cutout-holes
module light_headband() {
  angle_distance=11;  // degrees at which we punch our weight-reduce hole.
  difference() {
    baseline_headband();
    for (i = [-5:1:+5]) {
      // Punch holes exect in places of need of stabiliity.
      if (abs(i) != 2) hole_punch(i * angle_distance);
    }
    translate([85.4, -38, 0.5]) {
      rotate([90, 0, -90]) linear_extrude(height=10) text("M", size=5, halign="center", font="style:Bold");
      translate([0, 0, -7]) rotate([90, 0, -90]) linear_extrude(height=10) text("N", size=6, halign="center", font="style:Bold");
    }
    translate([85.7, -60, -4]) rotate([90, 0, -90]) linear_extrude(height=10) text(version, size=8, halign="right", font="style:Bold");
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

module print_shield() {
  // Cut out the area with the pins and move them up.
  translate([0, 0, vertical_pin_shift]) intersection() {
    light_headband();
    for (x = pin_angle_distances) roi_block(x[0], x[1]);
  }

  // Now, take the _top_ part of the band by doing the same cut-out ont
  // the same band lying on its back and use that to fill the hole at
  // the bottom left from the pin being shifted up.
  // Using the rotational cut-out means we capture the taper the band
  // has and replicate it fully at the bottom.
  intersection() {
    rotate([0, 180, 0]) light_headband();
    for (x = pin_angle_distances) roi_block(x[0], x[1]);
  }

  // Combine the above that with the shield, but leave out the pin area
  // we were 'operating' on: that is now filled with our construct above.
  difference() {
    light_headband();
    for (x = pin_angle_distances) roi_block(x[0], x[1], extra=-1);
  }
}

// Places where we need support are the places where our region-of-interest
// blocks are. We use the STL generated from these to tell Prusa-Slicer where
// we want the support.
module support_modifier() {
  for (x = pin_angle_distances) roi_block(x[0], x[1]);
}

print_shield();
//support_modifier();
