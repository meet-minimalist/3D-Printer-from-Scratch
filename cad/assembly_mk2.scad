// Prusa i3 MK2 printed parts (from the "Prusa i3 MK2 2020 aluminum profile" GrabCAD model) on our 2020 frame.
// Open in OpenSCAD and press F5. Change "pos" in config.scad to move the axes.
// MK2 meshes are imported at their MK2 assembly position and moved by group (see mk2_shift).
include <config.scad>
include <lib/vitamins.scad>
include <mk2/mk2_items.scad>
use <assembly.scad>                   // frame()
use <parts/frame_parts.scad>
use <parts/bed_spacer.scad>
use <parts/y_motor_mount_mk2.scad>

mk2_dir = "../third_party/grabcad_files/prusa-i3-mk2-2020_stl/placed/";
printed = "#f07818";

// ---------- MK2 reference points (MK2 assembly coordinates) ----------
m_base_top  = -196.2;                 // top face of the base bars
m_upright   = [160, 312];             // |X| and Y of the upright centres
m_top_bot   = 134;                    // bottom face of the top bar
m_front     = 91.1;                   // front face of the front bar
m_rear      = 431.2;                  // rear face of the rear bar
m_bed_y     = 248.48;                 // Y carriage centre
m_bed_bot   = -175.6;                 // heatbed bottom (on the Y carriage)
m_nozzle    = [18.64, -39.5, 261.51];  // nozzle tip [X, Z, Y] (heatsink axis; the heater block makes the bbox wider in Y)
m_xe_bot    = -18.57;                 // lowest point of the X-ends
m_x_rods    = [287, -8, 37];          // X rods [Y, Z bottom, Z top]
m_x_rod_x0  = -191;                   // X rod left end
m_z_axis    = [165, 182, 272.47];     // |X| of Z screw, |X| of Z rod, Y of both
m_z_face    = -163.17;                // Z motor face
m_y_belt    = [390.02, 125.5, -204.21];   // Y pulley Y, Y idler Y, belt centre Z
m_x_belt    = [-214, 163.5, 13.05];   // X pulley X, X idler X, belt centre Z

dz0     = ext - m_base_top;                               // 216.2
dy_g    = gantry_y - m_upright[1];
dz_top  = top_z - m_top_bot;
nozzle_y = m_nozzle[2] + dy_g;
bed_y   = nozzle_y - pos[1];                              // pos Y = nozzle position on the bed
bed_surf = m_bed_bot + dz0 + mk2_bed_raise + 4;            // our heatbed is 3 mm + 1 mm sheet
dz_x    = bed_surf + pos[2] - m_nozzle[1];                  // nozzle tip on the bed at pos Z = 0
z_face  = m_z_face + dz0 + mk2_z_raise;                    // our Z motor face

function sx(side) = side == "L" ? -1 : side == "R" ? 1 : 0;

function mk2_shift(g, s) =
    g == "base_front" ? [sx(s) * (side_x - m_upright[0]), -side_l/2 - m_front, dz0] :
    g == "base_rear"  ? [sx(s) * (side_x - m_upright[0]),  side_l/2 - m_rear,  dz0] :
    g == "y_front"    ? [0, -side_l/2 - m_front, dz0] :
    g == "y_rear"     ? [0,  side_l/2 - m_rear,  dz0] :
    g == "adapter"    ? [sx(s) * (side_x - m_upright[0]), dy_g, dz0] :
    g == "zb"         ? [sx(s) * (side_x - m_upright[0]), dy_g, dz0 + mk2_z_raise] :
    g == "top"        ? [sx(s) * (side_x - m_upright[0]), dy_g, dz_top] :
    g == "xe"         ? [sx(s) * (side_x - m_upright[0]), dy_g, dz_x] :
    g == "xc"         ? [pos[0] - m_nozzle[0], dy_g, dz_x] :
    g == "bed"        ? [0, bed_y - m_bed_y, dz0] :
    g == "yr"         ? [0,  side_l/2 - m_rear, dz0] :
    [0, 0, 0];

function has(n, k) = len([for (i = [0 : 1 : len(n) - len(k)]) if (substr(n, i, len(k)) == k) i]) > 0;   // step 1: empty range when k is longer
function substr(s, i, l) = l == 0 ? "" : str(s[i], substr(s, i + 1, l - 1));
function printed_part(n) = has(n, "X-END") || has(n, "X-CARRIAGE") || has(n, "EXTRUDER-") || has(n, "FAN-NOZZLE")
    || has(n, "Z-AXIS") || has(n, "HOLDER") || has(n, "y_bearing") || has(n, "Uchyceni") || has(n, "Part")
    || has(n, "CABLE_COVER");

module shaft_dir(d) {
    if (d[2] < 0) rotate([180, 0, 0]) children();
    else if (d[1] > 0) rotate([-90, 0, 0]) children();
    else if (d[1] < 0) rotate([90, 0, 0]) children();
    else if (d[0] > 0) rotate([0, 90, 0]) children();
    else if (d[0] < 0) rotate([0, -90, 0]) children();
    else children();
}

// MK2 meshes left out: the Y motor holder (2 screws, replaced by y_motor_mount_mk2), its Y switch,
// and the heatbed cable cover (made for the 254 mm MK42 bed, nothing to attach to on our bed).
// The MK2 X-end motor (3 motor screws) is replaced by mk2/x_end_motor_4screw.stl (4 screws).
// The printed MK2 frame connectors (print files 17-23: feet, base corners, top gussets, top corners, Z adapters)
// are not used: the frame is joined with the owner's cast corner brackets and T-plates (frame_hardware()).
mk2_left_out = ["Y-MOTOR-HOLDER", "HEATBED_CABLE_COVER", "Y_AXIS_ASM_1___SS_3GPT", "X-END-MOTOR",
    "=Part_1_2", "=Part_1_20", "=Part_1_14", "=Part_1_21",          // 17 frame foot
    "=Part_1_3", "=Part_1_5", "=Part_1_7", "=Part_1_10",            // 18 frame base corner
    "=Part_1_12", "=Part_1_6",                                      // 19 frame top gusset
    "=Part_1_22", "=Part_1_15",                                     // 20, 21 frame top corner
    "=Part_1_8", "=Part_1_9"];                                      // 22, 23 frame Z adapter
function left_out(n) = len([for (k = mk2_left_out) if (mk2_match(n, k)) k]) > 0;

module mk2_parts() for (it = mk2_items) if (!left_out(it[1])) {
    t = mk2_shift(it[2], it[3]);
    if (it[0] == "mesh")
        translate(t) color(printed_part(it[1]) ? printed : it[1] == "i3_mk2_1___Y_AXIS_ASM_1___I3_CARRIAGE_1" ? "lightgray" : "#888")
            import(str(mk2_dir, it[1], ".stl"));
    else
        translate(it[4] + t) shaft_dir(it[5]) nema17();           // our 47 mm motor in place of the MK2 motor
}

// ---------- Single parts, for the step-by-step build guide (assembly_steps.scad) ----------
// key: substring of the MK2 mesh name, or "=name" for an exact name. col: colour (undef = normal colour).
function mk2_match(n, key) = key[0] == "=" ? n == substr(key, 1, len(key) - 1) : has(n, key);
function mk2_hit(n, keys) = len([for (k = keys) if (mk2_match(n, k)) k]) > 0;
module mk2_part(keys, col) for (it = mk2_items) if (!left_out(it[1]) && mk2_hit(it[1], keys)) {
    t = mk2_shift(it[2], it[3]);
    if (it[0] == "mesh")
        translate(t) color(gc(col != undef ? col : mk2_colour(it[1]))) import(str(mk2_dir, it[1], ".stl"));
    else
        translate(it[4] + t) shaft_dir(it[5]) nema17();
}
function mk2_colour(n) = printed_part(n) ? printed : has(n, "PULLEY") || has(n, "IDLER_GT2") || has(n, "GEAR") ? "gold"
    : has(n, "LM8UU") || has(n, "625_BEARING") ? "steelblue" : has(n, "Z_NUT") ? "#c9a74a" : has(n, "CARRIAGE") ? "lightgray"
    : has(n, "FAN") || has(n, "turbine") || has(n, "top_1") || has(n, "bottom_") ? "#333" : "#888";
// Centres of the matching items in our frame (for assembly trails).
function mk2_centres(keys) = [for (it = mk2_items) if (!left_out(it[1]) && mk2_hit(it[1], keys))
    (it[0] == "mesh" ? (it[4] + it[5]) / 2 : it[4]) + mk2_shift(it[2], it[3])];

function z_screw_pos(s) = [s * (m_z_axis[0] + side_x - m_upright[0]), m_z_axis[2] + dy_g, z_face];
function z_rod_pos(s)   = [s * (m_z_axis[1] + side_x - m_upright[0]), m_z_axis[2] + dy_g, z_face];
function x_rod_pos(i)   = [m_x_rod_x0 - (side_x - m_upright[0]), m_x_rods[0] + dy_g, m_x_rods[1 + i] + dz_x];
function bed_y_pos()    = bed_y;
function y_motor_face() = m_y_motor + mk2_shift("yr", "C");

module z_coupler(s) translate(z_screw_pos(s) + [0, 0, 3]) coupler();
module z_screw(s)   translate(z_screw_pos(s) + [0, 0, 16]) threaded_rod(z_screw_l);
module z_rod(s)     translate(z_rod_pos(s)) rod(z_rod_l);
module x_rod(i)     translate(x_rod_pos(i)) rotate([0, 90, 0]) rod(mk2_x_rod_l);
module y_rod(s)     translate([s * mk2_y_rod_x, -y_rod_l/2, y_rod_z]) rotate([-90, 0, 0]) rod(y_rod_l);
module x_belt() {
    xb = m_x_belt; xl = m_x_belt[0] - (side_x - m_upright[0]); xr = m_x_belt[1] + (side_x - m_upright[0]);
    for (dz = [-6, 6]) belt([xl, m_x_rods[0] + dy_g, xb[2] + dz_x + dz], [xr, m_x_rods[0] + dy_g, xb[2] + dz_x + dz], [1, 6, 1.4]);
}
module y_belt() {
    yb = m_y_belt;
    for (dz = [-6, 6]) belt([0, yb[0] + side_l/2 - m_rear, yb[2] + dz0 + dz], [0, yb[1] - side_l/2 - m_front, yb[2] + dz0 + dz], [6, 1, 1.4]);
}
module bed_spacers(col) translate([0, bed_y, 0]) for (sx = [-1, 1], sy = [-1, 1])
    translate([sx * bed_holes/2, sy * bed_holes/2, m_bed_bot + dz0]) color(gc(col != undef ? col : printed)) bed_spacer();
module bed_springs() translate([0, bed_y, 0]) for (sx = [-1, 1], sy = [-1, 1])
    translate([sx * bed_holes/2, sy * bed_holes/2, m_bed_bot + dz0 + bed_spacer_h]) spring(bed_surf - 4 - (m_bed_bot + dz0) - bed_spacer_h);
module heatbed_only() translate([0, bed_y, bed_surf - 4]) heatbed();

module axes() {
    // Z: our coupler + 500 mm lead screw (the MK2 used motors with a built-in screw), 500 mm rods
    for (s = [-1, 1]) {
        translate([s * (m_z_axis[0] + side_x - m_upright[0]), m_z_axis[2] + dy_g, z_face]) {
            translate([0, 0, 3]) coupler();
            translate([0, 0, 16]) threaded_rod(z_screw_l);
        }
        translate([s * (m_z_axis[1] + side_x - m_upright[0]), m_z_axis[2] + dy_g, z_face]) rod(z_rod_l);
    }
    // X rods
    for (z = [m_x_rods[1], m_x_rods[2]])
        translate([m_x_rod_x0 - (side_x - m_upright[0]), m_x_rods[0] + dy_g, z + dz_x]) rotate([0, 90, 0]) rod(mk2_x_rod_l);
    // Y rods, full 500 mm between the front and rear bars
    for (s = [-1, 1]) translate([s * mk2_y_rod_x, -y_rod_l/2, y_rod_z]) rotate([-90, 0, 0]) rod(y_rod_l);
    // belts
    xb = m_x_belt; xl = m_x_belt[0] - (side_x - m_upright[0]); xr = m_x_belt[1] + (side_x - m_upright[0]);
    for (dz = [-6, 6]) belt([xl, m_x_rods[0] + dy_g, xb[2] + dz_x + dz], [xr, m_x_rods[0] + dy_g, xb[2] + dz_x + dz], [1, 6, 1.4]);
    yb = m_y_belt;
    for (dz = [-6, 6]) belt([0, yb[0] + side_l/2 - m_rear, yb[2] + dz0 + dz], [0, yb[1] - side_l/2 - m_front, yb[2] + dz0 + dz], [6, 1, 1.4]);
}

module bed() translate([0, bed_y, 0]) {
    hb = bed_surf - 4;
    for (sx = [-1, 1], sy = [-1, 1]) translate([sx * bed_holes/2, sy * bed_holes/2, m_bed_bot + dz0]) {
        color(printed) bed_spacer();
        translate([0, 0, bed_spacer_h]) spring(hb - (m_bed_bot + dz0) - bed_spacer_h);
    }
    translate([0, 0, hb]) heatbed();
}

// ---------- Frame hardware: cast corner brackets, T-plates, feet ----------
// Each bracket: [p, n1, n2, sx, sy] (see bracket_at() in lib/vitamins.scad).
// Only 8 brackets fit: the upright front faces are taken by the Z motors, and the other faces of the
// upright and top-bar joints are flat (the bars are flush), so they take T-plates, not brackets.
function brk_base() = [for (sx = [-1, 1], sy = [-1, 1]) let(n1 = [0, -sy, 0], n2 = [-sx, 0, 0])
    [[sx * (side_x - ext/2), sy * (cross_y - ext/2), cross(n1, n2)[2] < 0 ? ext : 0], n1, n2, sx, sy]];   // inside base corners
function brk_up()  = [for (s = [-1, 1])
    [[s > 0 ? side_x + ext/2 : -side_x + ext/2, gantry_y + ext/2, ext], [0, 0, 1], [0, 1, 0], s, 0]];      // upright rear faces
function brk_top() = [for (s = [-1, 1])
    [[s * (cross_l/2), s > 0 ? gantry_y - ext/2 : gantry_y + ext/2, top_z], [0, 0, -1], [-s, 0, 0], s, 0]]; // under the top bar
function foot_pos() = [for (sx = [-1, 1], sy = [-1, 1]) [sx * side_x, sy * cross_y, 0]];
// Heatbed MOS module: right outer face, between the PSU and the right Z motor (short, thick wires to the PSU).
function mos_pos() = [side_x + ext/2 + 2, -side_l/2 + 222, 20];

module frame_hardware() {
    for (b = concat(brk_base(), brk_up(), brk_top())) bracket_at(b[0], b[1], b[2]);
    for (s = [-1, 1]) t_plate(s);
    for (f = foot_pos()) translate(f) rubber_foot();
}

module electronics() {
    translate([side_x + ext/2 + 2, -side_l/2 + 5, 0]) psu();
    translate(mos_pos()) mos_module();
    translate([-side_x - ext/2 - 4, -side_l/2 + 10, 25]) controller();
    translate([-side_x - ext/2 - 4, -side_l/2 + 130, 30]) rpi();
}

m_y_motor = [18.0, 390.02, -204.21];      // Y motor face centre (shaft along -X)
module y_motor_mount(col) translate(m_y_motor + mk2_shift("yr", "C")) color(gc(col != undef ? col : printed)) y_motor_mount_mk2();

module x_end_motor(col) translate(mk2_shift("xe", "L")) color(gc(col != undef ? col : printed)) import("mk2/x_end_motor_4screw.stl");
function x_end_motor_centre() = [-214, 278, 12] + mk2_shift("xe", "L");

frame();
frame_hardware();
mk2_parts();
y_motor_mount();
x_end_motor();
axes();
bed();
electronics();

// Collision check at Z = 0: the X-ends must stay above the Z couplers.
xe_low = m_xe_bot + bed_surf - m_nozzle[1];
echo(str("X-end lowest point at Z0 = ", xe_low, " mm; coupler top = ", z_face + 28, " mm; clearance = ", xe_low - z_face - 28, " mm"));
// Z max: the Z nut on top of the X-end (MK2 Z 47.3) reaches the Z-top part (bottom at the top bar bottom).
z_max = m_top_bot + dz_top - (47.3 - m_nozzle[1]) - bed_surf;
echo(str("Z travel = ", z_max, " mm"));
