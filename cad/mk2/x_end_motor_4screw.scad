// MK2 X-end motor with a solid motor plate and 4 motor screws. The MK2 part holds the motor with
// 3 screws on an open frame; this fills the plate to a solid square (only the motor boss hole stays open)
// and takes it down to the X-end bottom, so it prints without supports.
// Coordinates are the MK2 assembly position.
// Render (F6) and export as x_end_motor_4screw.stl (used by assembly_mk2.scad and prep_print.py).
include <../config.scad>

xm_face   = [-214.0, 295.97, 13.05];     // motor face centre, shaft along -Y
xm_plate  = [292.4, 295.9];              // Y range of the MK2 motor plate (3.5 mm)
xm_x      = [-239, -194.5];              // X range: 2.3 mm wall outside the outer holes, joins the X-end body
xm_bottom = -18.57;                      // X-end bottom face (on the print bed)
xm_top    = xm_face[2] + nema_w/2 + 0.5; // just above the motor body; joins the MK2 top band
xm_boss   = nema_boss + 1;               // 23: the motor boss, and room for the pulley flange (16) to turn

difference() {
    union() {
        import("../../third_party/grabcad_files/prusa-i3-mk2-2020_stl/placed/X-END-MOTOR_1.stl");
        translate([xm_x[0], xm_plate[0], xm_bottom])
            cube([xm_x[1] - xm_x[0], xm_plate[1] - xm_plate[0], xm_top - xm_bottom]);
    }
    translate([xm_face[0], xm_plate[0] - 1, xm_face[2]]) rotate([-90, 0, 0]) {
        cylinder(d = xm_boss, h = 10);
        for (x = [-1, 1], z = [-1, 1])
            translate([x * nema_hole/2, -z * nema_hole/2, 0]) cylinder(d = m3_d, h = 10);
    }
}
