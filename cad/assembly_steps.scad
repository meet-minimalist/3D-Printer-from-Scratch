// Step-by-step exploded build views. Render one step with:  openscad -D step=N -o step_N.png assembly_steps.scad
// Method (after the "exploded views" teardown guide): each step shows only the NEW parts, in colour, moved out
// along the axis on which they are fitted; dashed trails lead back to their final place. Parts fitted in
// earlier steps are shown as transparent grey (% background). Bench steps show a sub-assembly on its own.
include <config.scad>
include <lib/vitamins.scad>
use <assembly.scad>              // side(), on_left_outer_face()
use <assembly_mk2.scad>
use <parts/frame_parts.scad>

step = 1;
rx = 60; rz = 35;                // camera rotation of this step (set by guide/render_steps.py) - labels face the camera
bs = 12;                         // label size (mm)
GHOST = "#d9dde2";              // parts fitted in earlier steps
$fn = 24;
$lbl = undef;

// Frame hardware (corner_bracket, bracket_at, t_plate, rubber_foot, mos_module) is in lib/vitamins.scad;
// the bracket positions (brk_base, brk_up, brk_top) are in assembly_mk2.scad, shared with the full model.

// ---------- Assembly trails (dashed) ----------
module trail(a, off) {
    l = norm(off);
    if (l > 1) {
        u = off / l; n = floor(l / 8);
        color("#333") for (i = [0 : 2 : n - 1]) hull() { translate(a + u * i * 8) sphere(d = bs / 7, $fn = 6); translate(a + u * min(l, i * 8 + 5)) sphere(d = bs / 7, $fn = 6); }
    }
}
// Numbered label that faces the camera, above point p.
eye = [sin(rx) * sin(rz), -sin(rx) * cos(rz), cos(rx)];      // unit vector toward the camera
module badge(p, n) translate(p + [0, 0, bs * 1.6] + eye * bs * 5) rotate([rx, 0, rz]) {
    color("#e8730c") cylinder(d = bs * 2.3, h = 0.8, $fn = 40);
    color("white") translate([0, 0, 0.8]) linear_extrude(0.8) text(str(n), size = bs, font = "Liberation Sans:style=Bold", halign = "center", valign = "center");
}
// Reference points of the new parts, read by guide/make_guide.py to aim the camera.
module pt(p) let(q = p[0] > 0 ? p - [$sq, 0, 0] : p) echo(str("PT|", q[0], "|", q[1], "|", q[2]));
// Both ends of a long part (rod, screw, belt), before and after the explode offset, for camera aiming.
module ends(a, b, o, e) if (e > 0 || $ctx) { pt(a); pt(b); pt(a + e * o); pt(b + e * o); }
$ctx = false;                    // true: context parts of a bench step also aim the camera
$sq = 0;                         // bench step 12: move the right-hand parts this far to the left (closer together)
module ex(o, r, e) translate(r[0] > 0 ? [-$sq, 0, 0] : [0, 0, 0]) ex0(o, r, e) children();
module ex0(o, r, e) { if ($ctx) pt(r); translate(e * o) children(); if (e > 0) { trail(r, o); pt(r); pt(r + o); if ($lbl != undef) { badge(r + o, $lbl); pt(r + o + [0, 0, 45]); } } }

up_y = gantry_y;                                       // uprights centre Y
brace_mid = brace_top + brace_l / 2 * [cos(brace_a), -sin(brace_a)];

// ---------- Groups: geometry, explode offset (o) and trail reference (r) for each instance ----------
X_GROUPS = ["xem", "xei", "xeb", "znut", "xmot", "xpul", "xid", "xsw", "xrod", "xcar", "xcb", "xbelt"];
module G(id, e = 0, ov = undef) {
    function O(v) = ov != undef ? ov : v;
    if (id == "sideL" || id == "sideR") { s = id == "sideL" ? -1 : 1;
        ex(O([s * 80, 0, 0]), [s * side_x, 0, ext/2], e) translate([s * side_x, -side_l/2, ext/2]) rotate([-90, 0, 0]) extrusion(side_l); }
    if (id == "crossF" || id == "crossR") { s = id == "crossF" ? -1 : 1;
        ex(O([0, s * 80, 0]), [0, s * cross_y, ext/2], e) translate([-cross_l/2, s * cross_y, ext/2]) rotate([0, 90, 0]) extrusion(cross_l); }
    if (id == "brk_base") for (b = brk_base()) { sx = b[3]; sy = b[4];
        ex(O([-sx * 35, -sy * 35, 45]), b[0] + [-sx * 10, -sy * 10, 0], e) bracket_at(b[0], b[1], b[2]); }
    if (id == "feet") for (f = foot_pos())
        ex(O([0, 0, -45]), f + [0, 0, -16], e) translate(f) rubber_foot();
    if (id == "upL" || id == "upR") { s = id == "upL" ? -1 : 1;
        ex(O([0, 0, 120]), [s * side_x, up_y, ext + upright_l / 2], e) translate([s * side_x, up_y, ext]) extrusion(upright_l); }
    if (id == "brk_up") for (b = brk_up())
        ex(O([0, 45, 25]), b[0] + [-10, 10, 10], e) bracket_at(b[0], b[1], b[2]);
    if (id == "top")
        ex(O([0, 0, 90]), [0, up_y, top_z + ext/2], e) translate([-cross_l/2, up_y, top_z + ext/2]) rotate([0, 90, 0]) extrusion(cross_l);
    if (id == "brk_top") for (b = brk_top()) { s = b[3];
        ex(O([-s * 40, 0, -45]), [s * (cross_l/2 - 10), up_y, top_z - 10], e) bracket_at(b[0], b[1], b[2]); }
    if (id == "tplate") for (s = [-1, 1])
        ex(O([0, 45, 0]), [s * 200, up_y + ext/2 + 1.5, 520], e) t_plate(s);
    if (id == "braceL" || id == "braceR") { s = id == "braceL" ? -1 : 1;
        ex(O([s * 70, 0, 0]), [s * side_x, brace_mid[0], brace_mid[1]], e)
            translate([s * side_x, brace_top[0], brace_top[1]]) rotate([270 - brace_a, 0, 0]) extrusion(brace_l); }
    if (id == "gussetL" || id == "gussetR") { s = id == "gussetL" ? -1 : 1;
        for (pt = [[brace_top[0], brace_top[1]], [brace_bot[0] - 20, ext / 2]])
            if (e > 0) { trail([s * (side_x + ext/2 + 2.5), pt[0], pt[1]], O([s * 130, 0, 0])); pt([s * (side_x + 132.5), pt[0], pt[1]]); }
        if (e > 0 && $lbl != undef) badge([s * (side_x + ext/2 + 132.5), brace_top[0], brace_top[1]], $lbl);
        translate(e * O([s * 130, 0, 0])) color(gc("#f07818")) side(s) on_left_outer_face() { brace_gusset_top(); brace_gusset_bottom(); } }
    // MK2 printed parts and their hardware
    if (id == "zbot")  for (c = mk2_centres(["Z-AXIS-BOTTOM"])) ex(O([0, -70, 0]), c, e) mk2_part([c[0] < 0 ? "BOTTOM-LEFT" : "BOTTOM-RIGHT"]);
    if (id == "zmot")  for (c = mk2_centres(["W_THREADED_SHAFT"])) ex(O([0, 0, -80]), c + [0, 0, -23], e) mk2_part([c[0] < 0 ? "W_THREADED_SHAFT_1" : "W_THREADED_SHAFT_2"]);
    if (id == "zcoup") for (s = [-1, 1]) ex(O([0, 0, 55]), z_screw_pos(s) + [0, 0, 15], e) z_coupler(s);
    if (id == "yclamp") for (c = mk2_centres(["Uchyceni"])) ex(O([0, 0, 35]), c, e) translate(-c) translate(c) mk2_part(["Uchyceni"]);
    if (id == "yrod")  for (s = [-1, 1]) { ends([s * mk2_y_rod_x, -y_rod_l/2, y_rod_z], [s * mk2_y_rod_x, y_rod_l/2, y_rod_z], O([0, 0, 80]), e); ex(O([0, 0, 80]), [s * mk2_y_rod_x, 0, y_rod_z], e) y_rod(s); }
    if (id == "ymm")   ex(O([0, -70, 40]), y_motor_face() + [-15, 10, 0], e) y_motor_mount();
    if (id == "ymot")  ex(O([80, 0, 0]), y_motor_face() + [23, 0, 0], e) mk2_part(["Y_AXIS_ASM_1___MOTOR"]);
    if (id == "ypul")  for (c = mk2_centres(["PULLEY_GT2_16T_2"])) ex(O([-90, -40, 0]), c, e) mk2_part(["PULLEY_GT2_16T_2"]);
    if (id == "yidh")  for (c = mk2_centres(["=Part6_1"])) ex(O([0, 0, 55]), c, e) mk2_part(["=Part6_1"]);
    if (id == "yid")   for (c = mk2_centres(["IDLER_GT2_20T_2"])) ex(O([0, 60, 110]), c, e) mk2_part(["IDLER_GT2_20T_2"]);
    if (id == "ycar")  for (c = mk2_centres(["I3_CARRIAGE"])) ex(O([0, 0, 110]), c, e) mk2_part(["I3_CARRIAGE"]);
    if (id == "ybr")   for (c = mk2_centres(["Y_AXIS_ASM_1___LM8UU"])) ex(O([0, 0, 50]), c, e) mk2_part(["Y_AXIS_ASM_1___LM8UU"]);
    if (id == "ybh")   for (c = mk2_centres(["y_bearing_holder"])) ex(O([0, 0, -40]), c, e) mk2_part(["y_bearing_holder"]);
    if (id == "ybelth") for (c = mk2_centres(["Y-BELT-HOLDER"])) ex(O([0, 0, -55]), c, e) mk2_part(["Y-BELT-HOLDER"]);
    if (id == "ybelt") { ends([0, -side_l/2, y_pulley_z], [0, side_l/2, y_pulley_z], O([0, 0, 35]), e); ex(O([0, 0, 35]), [0, 0, y_pulley_z], e) y_belt(); }
    if (id == "bspc")  ex(O([0, 0, 45]), [bed_holes/2, bed_y_pos() + bed_holes/2, 50], e) bed_spacers();
    if (id == "bspr")  ex(O([0, 0, 85]), [bed_holes/2, bed_y_pos() + bed_holes/2, 70], e) bed_springs();
    if (id == "hbed")  ex(O([0, 0, 130]), [0, bed_y_pos(), 80], e) heatbed_only();
    // X axis (built on the bench, then fitted)
    if (id == "xem")   ex(O([0, 0, 0]), x_end_motor_centre(), e) x_end_motor();
    if (id == "xei")   for (c = mk2_centres(["X-END-IDLER"])) ex(O([0, 0, 0]), c, e) mk2_part(["X-END-IDLER"]);
    if (id == "xeb")   for (c = mk2_centres(["LM8UU_BEARING_3", "LM8UU_BEARING_5"])) ex(O([0, 0, 55]), c, e) mk2_part([c[0] < 0 ? "LM8UU_BEARING_3" : "LM8UU_BEARING_5"]);
    if (id == "znut")  for (c = mk2_centres(["Z_NUT"])) ex(O([0, 0, 115]), c, e) mk2_part([c[0] < 0 ? "Z_NUT_1" : "Z_NUT_2"]);
    if (id == "xmot")  for (c = mk2_centres(["X_AXIS_ASM_1___MOTOR"])) ex(O([0, 80, 0]), c + [0, 23, 0], e) mk2_part(["X_AXIS_ASM_1___MOTOR"]);
    if (id == "xpul")  for (c = mk2_centres(["PULLEY_GT2_16T_1"])) ex(O([0, -55, 0]), c, e) mk2_part(["PULLEY_GT2_16T_1"]);
    if (id == "xid")   for (c = mk2_centres(["IDLER_GT2_20T_1"])) ex(O([0, -50, 0]), c, e) mk2_part(["IDLER_GT2_20T_1"]);
    if (id == "xsw")   for (c = mk2_centres(["ASM_1_ASM_1_1___SS_3GPT_BASE"])) ex(O([0, -35, -25]), c, e) mk2_part(["ASM_1_ASM_1_1___SS_3GPT"]);
    if (id == "xrod")  for (i = [0, 1]) { ends(x_rod_pos(i), x_rod_pos(i) + [mk2_x_rod_l, 0, 0], O([170, 0, 0]), e); ex(O([170, 0, 0]), x_rod_pos(i) + [mk2_x_rod_l / 2, 0, 0], e) x_rod(i); }
    if (id == "xcar")  for (c = mk2_centres(["X-CARRIAGE"])) ex(O([0, 95, 0]), c, e) mk2_part(["X-CARRIAGE"]);
    if (id == "xcb")   for (c = mk2_centres(["=LM8UU_BEARING_1", "LM8UU_BEARING_2", "LM8UU_BEARING_4"])) ex(O([0, 45, 0]), c, e)
                           translate(-c) translate(c) mk2_part(["=LM8UU_BEARING_1", "LM8UU_BEARING_2", "LM8UU_BEARING_4"]);
    if (id == "xbelt") { ends(x_rod_pos(0) + [-40, 0, 21], x_rod_pos(0) + [mk2_x_rod_l + 30, 0, 21], O([0, -40, 0]), e); ex(O([0, -40, 0]), x_rod_pos(0) + [mk2_x_rod_l / 2, 0, 21], e) x_belt(); }
    // Z rods and lead screws, fitted from the top
    if (id == "zrod")  for (s = [-1, 1]) { ends(z_rod_pos(s), z_rod_pos(s) + [0, 0, z_rod_l], O([0, 0, 260]), e); ex(O([0, 0, 260]), z_rod_pos(s) + [0, 0, z_rod_l], e) z_rod(s); }
    if (id == "zscr")  for (s = [-1, 1]) { ends(z_screw_pos(s) + [0, 0, 16], z_screw_pos(s) + [0, 0, 16 + z_screw_l], O([0, 0, 320]), e); ex(O([0, 0, 320]), z_screw_pos(s) + [0, 0, 16 + z_screw_l], e) z_screw(s); }
    if (id == "ztop")  for (c = mk2_centres(["Z-AXIS-TOP"])) ex(O([0, 0, 120]), c, e) mk2_part([c[0] < 0 ? "Z-AXIS-TOP_RIGHT-M_2" : "Z-AXIS-TOP_RIGHT-M_1"]);
    // Extruder
    if (id == "ebody") for (c = mk2_centres(["EXTRUDER-BODY"])) ex(O([0, 0, 70]), c, e) mk2_part(["EXTRUDER-BODY"]);
    if (id == "emot")  for (c = mk2_centres(["Assembly_1_1___MOTOR"])) ex(O([0, -90, 0]), c + [0, -23, 0], e) mk2_part(["Assembly_1_1___MOTOR"]);
    if (id == "egear") for (c = mk2_centres(["EXTRUDER_GEAR"])) ex(O([0, -45, 0]), c, e) mk2_part(["EXTRUDER_GEAR"]);
    if (id == "eidl")  for (c = mk2_centres(["EXTRUDER-IDLER"])) ex(O([60, 0, 0]), c, e) mk2_part(["EXTRUDER-IDLER"]);
    if (id == "ebear") for (c = mk2_centres(["625_BEARING"])) ex(O([95, 0, 0]), c, e) mk2_part(["625_BEARING", "5X16SH"]);
    if (id == "ehot")  for (c = mk2_centres(["E3D"])) ex(O([0, 0, -70]), c, e) mk2_part(["E3D"]);
    if (id == "ecov")  for (c = mk2_centres(["EXTRUDER-COVER"])) ex(O([0, -110, 0]), c, e) mk2_part(["EXTRUDER-COVER"]);
    if (id == "efan")  for (c = mk2_centres(["30MM_FAN"])) ex(O([-60, 0, 0]), c, e) mk2_part(["30MM_FAN"]);
    if (id == "enoz")  for (c = mk2_centres(["FAN-NOZZLE"])) ex(O([0, 0, -60]), c, e) mk2_part(["FAN-NOZZLE"]);
    if (id == "eblow") for (c = mk2_centres(["turbine"])) ex(O([0, -170, 0]), c, e) mk2_part(["turbine", "=top_1", "bottom_"]);
    // Electronics
    if (id == "psu")   ex(O([90, 0, 0]), [side_x + ext/2 + 2, -side_l/2 + 112, 57], e) translate([side_x + ext/2 + 2, -side_l/2 + 5, 0]) psu();
    if (id == "mos")   ex(O([70, 0, 0]), mos_pos() + [12, 30, 25], e) translate(mos_pos()) mos_module();
    if (id == "ctrl")  ex(O([-70, 0, 0]), [-side_x - ext/2 - 4, -side_l/2 + 65, 67], e) translate([-side_x - ext/2 - 4, -side_l/2 + 10, 25]) controller();
    if (id == "rpi")   ex(O([-70, 0, 0]), [-side_x - ext/2 - 4, -side_l/2 + 172, 58], e) translate([-side_x - ext/2 - 4, -side_l/2 + 130, 30]) rpi();
}

// ---------- Steps: [new groups, bench (only show the listed context), context groups, X axis offset override] ----------
STEPS = [
    [["sideL", "sideR", "crossF", "crossR", "brk_base"], false],                        // 1 base frame
    [["feet"], false],                                                                  // 2 feet
    [["upL", "upR", "brk_up"], false],                                                  // 3 uprights
    [["top", "brk_top", "tplate"], false],                                              // 4 top bar
    [["braceL", "braceR", "gussetL", "gussetR"], false],                                // 5 braces
    [["zbot", "zmot", "zcoup"], false],                                                 // 6 Z bottom + motors
    [["yclamp", "yrod", "ybr"], false],                                                 // 7 Y rods + Y bearings
    [["ymm", "ymot", "ypul", "yidh", "yid"], false],                                    // 8 Y motor + idler
    [["ycar", "ybh", "ybelth"], false],                                                 // 9 Y carriage
    [["ybelt"], false],                                                                 // 10 Y belt
    [["bspc", "bspr", "hbed"], false],                                                  // 11 heatbed
    [["xem", "xei", "xeb", "znut", "xmot", "xpul", "xid", "xsw"], true, [], undef, 300],   // 12 X-ends (bench, shown 300 mm closer)
    [["xrod", "xcar", "xcb", "xbelt"], true, ["xem", "xei", "xeb", "znut", "xmot", "xpul", "xid", "xsw"]],   // 13 X axis (bench)
    [X_GROUPS, false, [], [0, 0, 160]],                                                 // 14 fit X axis
    [["zrod", "zscr", "ztop"], false],                                                  // 15 Z rods + screws
    [["ebody", "emot", "egear", "eidl", "ebear"], true, ["xcar", "xcb", "xrod"]],        // 16 extruder drive
    [["ehot", "ecov", "efan", "enoz", "eblow"], true, ["xcar", "xcb", "xrod", "ebody", "emot", "egear", "eidl", "ebear"]], // 17 hotend + fans
    [["psu", "mos", "ctrl", "rpi"], false],                                             // 18 electronics
    [[], false],                                                                        // 19 complete printer
];
// Step in which each group is fitted to the printer (X axis groups count as fitted in step 14).
function fitted(id) = len([for (x = X_GROUPS) if (x == id) x]) > 0 ? 14
    : [for (k = [0 : len(STEPS) - 1]) if (len([for (g = STEPS[k][0]) if (g == id) g]) > 0) k + 1][0];
ALL = [for (k = [0 : len(STEPS) - 1]) for (g = STEPS[k][0]) g];
function uniq(l) = [for (i = [0 : len(l) - 1]) if (len([for (j = [0 : 1 : i - 1]) if (l[j] == l[i]) j]) == 0) l[i]];

// Label number of each new group (same number = same part type, as in the guide's parts table).
LABELS = [[1, 1, 2, 2, 3], [1], [1, 1, 2], [1, 2, 3], [1, 1, 2, 2]];
function lbl(k) = step <= len(LABELS) ? LABELS[step - 1][k] : k + 1;

S = STEPS[step - 1];
if (S[1]) {                                                    // bench step: context + new parts only
    for (g = S[2]) G(g, $gc = GHOST, $ctx = true);
    for (k = [0 : 1 : len(S[0]) - 1]) G(S[0][k], 1, $lbl = lbl(k), $sq = len(S) > 4 ? S[4] : 0);
} else {
    for (g = uniq(ALL)) if (fitted(g) < step) { if (step == len(STEPS)) G(g); else G(g, $gc = GHOST); }
    for (k = [0 : 1 : len(S[0]) - 1]) G(S[0][k], 1, len(S) > 3 ? S[3] : undef, $lbl = len(S) > 3 ? (k == 0 ? 1 : undef) : lbl(k));
}
