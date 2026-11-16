// Prusa i3 (2020 frame) - full assembly. Open in OpenSCAD and press F5.
// Change "pos" in config.scad (or use -D pos=[x,y,z]) to move the axes.
include <config.scad>
include <lib/vitamins.scad>
use <parts/x_end.scad>
use <parts/x_carriage.scad>
use <parts/z_mounts.scad>
use <parts/y_parts.scad>
use <parts/frame_parts.scad>
use <parts/extruder_mount.scad>

printed = "#f07818";

xend_z = bed_top - nozzle_z - xend_rod_z + pos[2];   // X-end bottom
bed_y  = -pos[1];                                    // bed centre Y

// Left-side part as modelled; right side mirrored.
module side(s) if (s < 0) children(); else mirror([1, 0, 0]) children();

// Maps 2D gusset shapes ([Y, Z] plane) onto the outer face of the left frame side.
module on_left_outer_face() translate([-side_x - ext/2 - 5, 0, 0]) rotate([90, 0, 90]) children();

module frame() {
    for (s = [-1, 1]) {
        translate([s * side_x, -side_l/2, ext/2]) rotate([-90, 0, 0]) extrusion(side_l);
        translate([-cross_l/2, s * cross_y, ext/2]) rotate([0, 90, 0]) extrusion(cross_l);
        translate([s * side_x, gantry_y, ext]) extrusion(upright_l);
        translate([s * side_x, brace_top[0], brace_top[1]]) rotate([270 - brace_a, 0, 0]) extrusion(brace_l);
        color(printed) side(s) on_left_outer_face() { brace_gusset_top(); brace_gusset_bottom(); }
    }
    translate([-cross_l/2, gantry_y, top_z + ext/2]) rotate([0, 90, 0]) extrusion(cross_l);
}

module z_axis() for (s = [-1, 1]) {
    translate([s * z_screw_x, z_plane_y, 0]) {
        translate([0, 0, z_motor_top]) nema17();
        translate([0, 0, z_motor_top + 5]) coupler();
        translate([0, 0, z_motor_top + 15]) threaded_rod(z_screw_l);
        color(printed) side(s) {
            translate([0, 0, z_motor_top]) z_motor_mount();
            translate([0, 0, top_z]) z_top_holder();
        }
    }
    translate([s * (z_screw_x + z_rod_off), z_plane_y, z_motor_top + 3]) rod(z_rod_l);
}

module x_axis() {
    for (s = [-1, 1]) translate([s * z_screw_x, z_plane_y, xend_z]) {
        t8_nut();
        for (k = [0, 1]) translate([s * z_rod_off, 0, xend_h * (2*k + 1)/4]) lm8uu();
    }
    color(printed) {
        translate([-z_screw_x, z_plane_y, xend_z]) x_end_motor();
        translate([z_screw_x, z_plane_y, xend_z]) mirror([1, 0, 0]) x_end_idler();
    }
    for (dz = [0, x_rod_dist])
        translate([-x_rod_l/2, x_rod_y, xend_z + xend_rod_z + dz]) rotate([0, 90, 0]) rod(x_rod_l);

    mx = -z_screw_x + x_motor_x;
    ix = z_screw_x - x_idler_x;
    bz = xend_z + belt_z;
    translate([mx, z_plane_y - 39, bz]) rotate([-90, 0, 0]) nema17();
    translate([mx, x_rod_y - 10.5, bz]) rotate([-90, 0, 0]) gt2_pulley();
    translate([ix, x_rod_y - 4.25, bz]) rotate([-90, 0, 0]) gt2_idler();
    for (dz = [-pulley_r, pulley_r]) belt([mx, x_rod_y, bz + dz], [ix, x_rod_y, bz + dz], [1, 6, 1.4]);

    translate([pos[0], x_rod_y, xend_z + xend_rod_z]) {
        color(printed) { x_carriage(); hotend_clamp(); }
        for (dz = [0, x_rod_dist], dx = [-13, 13]) translate([dx, 0, dz]) rotate([0, 90, 0]) lm8uu();
        translate([0, hotend_y, hotend_top]) v6_hotend();
    }
}

module y_axis() {
    for (s = [-1, 1]) {
        translate([s * y_rod_x, -y_rod_l/2, y_rod_z]) {
            rotate([-90, 0, 0]) rod(y_rod_l);
            color(printed) y_rod_holder();
        }
        translate([s * y_rod_x, y_rod_l/2, y_rod_z]) color(printed) rotate(180) y_rod_holder();
    }
    color(printed) {
        translate([0, -side_l/2, 0]) y_motor_mount();
        translate([0, side_l/2, 0]) y_idler();
    }
    my = -side_l/2 + y_motor_y;
    iy = side_l/2 + y_idler_y;
    translate([14, my, y_pulley_z]) rotate([0, -90, 0]) nema17();
    translate([10.5, my, y_pulley_z]) rotate([0, -90, 0]) gt2_pulley();
    translate([-4.25, iy, y_pulley_z]) rotate([0, 90, 0]) gt2_idler();
    for (dz = [-pulley_r, pulley_r]) belt([0, my, y_pulley_z + dz], [0, iy, y_pulley_z + dz], [6, 1, 1.4]);

    translate([0, bed_y, 0]) {
        for (sx = [-1, 1], sy = [-1, 1]) translate([sx * y_rod_x, sy * 60, y_rod_z]) {
            color(printed) y_bearing_holder();
            rotate([90, 0, 0]) lm8uu();
        }
        color(printed) translate([0, 0, carriage_plate_z]) y_belt_clamp();
        color("lightgray") translate([-115, -115, carriage_plate_z]) cube([230, 230, 3]);
        for (sx = [-1, 1], sy = [-1, 1])                 // MK2 bed: 4 corner holes
            translate([sx * bed_holes/2, sy * bed_holes/2, carriage_plate_z + 3]) spring(bed_top - 4 - carriage_plate_z - 3);
        translate([0, 0, bed_top - 4]) heatbed();
    }
}

module electronics() {
    translate([side_x + ext/2 + 2, -side_l/2 + 5, 0]) psu();
    translate([-side_x - ext/2 - 4, -side_l/2 + 10, 25]) controller();
    translate([-side_x - ext/2 - 4, -side_l/2 + 130, 30]) rpi();
    // extruder (feeder) motor on the top bar
    translate([e_motor_x, gantry_y, top_z + ext]) {
        translate([0, 0, e_motor_z]) rotate([90, 0, 0]) nema17();
        color(printed) extruder_mount();
    }
}

module endstops() {
    translate([-z_screw_x + 15, x_rod_y - 30, xend_z + 20]) rotate(90) endstop();          // X min
    translate([-y_rod_x - 30, -y_rod_l/2 + 16, ext]) endstop();                           // Y min
    translate([-side_x + ext/2, z_plane_y + 10, z_motor_top + 60]) rotate(90) endstop(); // Z min
}

frame();
z_axis();
x_axis();
y_axis();
electronics();
endstops();
