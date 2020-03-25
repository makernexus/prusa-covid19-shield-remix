// Testing some weight-reducing as feedback from local healthcare community.
angle_distance=11;  // degrees

module orig_rc2() {
     // The distribted RC2 STL file is pretty shifted...
     translate([-845, 0, 0]) import("covid19_headband_rc2.stl", convexity=10);
}

module hole_punch(angle=0, r=6, from_bottom=2) {
     rotate([0, 0, angle]) translate([0, 70, from_bottom])
	  rotate([-90, 0, 0]) cylinder(r=r, h=20, $fn=6);
}

module shield_pin_cutout(above) {
     translate([0, 0, above ? +5 : -5]) cube([10, 15, 10], center=true);
}

module light_rc2() {
     difference() {
	  orig_rc2();
	  for (i = [-5:1:+5]) {
	       // Punch holes exect in places of need of stabiliity.
	       if (abs(i) != 2) hole_punch(i * angle_distance);
	  }
     }
}

module _cutout_block(angle, dist, above) {
     rotate([0, 0, angle]) translate([0, dist, 0]) shield_pin_cutout(above);
}

module cutout_block_above(angle, dist) { _cutout_block(angle, dist, true); }
module cutout_block_bottom(angle, dist) { _cutout_block(angle, dist, false); }

// The angle and distance the pins are roughly. There we just move them
// up and replace the bottom part with what we found above.
pin_angle_distances = [ [22, 80], [-22, 80], [75, 95], [-75, 95]];

// Cut out the area with the pins and move them up.
translate([0, 0, 7]) intersection() {
     light_rc2();
     for (x = pin_angle_distances) cutout_block_bottom(x[0], x[1]);
}

// Now cut out the area _above_ the pins and move them down.
translate([0, 0, -10]) intersection() {
     light_rc2();
     for (x = pin_angle_distances) cutout_block_above(x[0], x[1]);
}

// Combine that with the shield, but leave out the original pin area which
// is now replace with our construct above.
difference() {
     light_rc2();
     for (x = pin_angle_distances) cutout_block_bottom(x[0], x[1]);
}
