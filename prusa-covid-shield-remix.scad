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


// at 100%, 0.3mm draft mode: 43.99g, 2:31h print time.
// vs. 48.47, 2:35h
difference() {
     orig_rc2();
     for (i = [-5:1:+5]) {
	  // Punch holes exect in places of need of stabiliity.
	  if (abs(i) != 2) hole_punch(i * angle_distance);
     }
}
