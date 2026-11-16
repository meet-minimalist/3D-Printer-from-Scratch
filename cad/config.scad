// Prusa i3 with 2020 frame - global parameters. All dimensions in mm.
// Origin: centre of the base frame, Z = 0 on the table.
// X = left/right, Y = front/back (front is -Y), Z = up.

$fn = 48;
clr = 0.2;                        // printing clearance

// ---------- Bought parts ----------
// Measured from the owner's parts (GrabCAD model -> STEP files in vendor/).
ext        = 20;                  // 2020 profile size
rod_d      = 8;                   // smooth rods
lm_d       = 15;                  // LM8UU outer diameter
lm_l       = 24;                  // LM8UU length
screw_d    = 8;                   // Z lead screw T8-2-D8 (invoice #5396)
t8_flange  = [22, 3.5];           // T8 brass nut flange [d, thickness]
t8_body    = [10.2, 10];          // T8 nut body below the flange [d, length]
t8_boss_h  = 1.5;                 // small boss on the other side of the flange
t8_holes   = [16, 3.5];           // 4 flange holes [circle d, hole d]
nema_w     = 42.3;                // NEMA17 body
nema_l     = 47;                  // 42BYGHW811 body length
nema_hole  = 31;                  // NEMA17 bolt spacing
nema_boss  = 22;                  // NEMA17 centre boss
m3_d       = 3.4;
m3_nut     = 6.4;                 // M3 nut across corners
m5_d       = 5.5;
m5_head    = 10;
pulley_r   = 6.37;                // GT2 20T pitch radius
v6_len     = 62.5;                // E3D V6 type hotend, top to nozzle tip

// ---------- Frame (cut list) ----------
cross_l    = 400;                 // front, rear and top bars
side_l     = 520;                 // base side bars (Y direction)
upright_l  = 520;
brace_l    = 290;
side_x     = cross_l/2 + ext/2;   // 210: centre X of side bars and uprights
cross_y    = side_l/2 - ext/2;    // 250: centre Y of front and rear bars
gantry_y   = 85;                  // centre Y of uprights and top bar
top_z      = upright_l;           // 520: bottom of top bar
brace_a    = 60;                  // brace angle from horizontal
brace_top  = [gantry_y + ext/2 + 10, 278];   // [Y, Z] of brace top end centre
brace_bot  = brace_top + brace_l * [cos(brace_a), -sin(brace_a)];

// ---------- Y axis ----------
y_rod_x    = 75;                  // Y rods at +/- this X
y_rod_z    = 30;
y_rod_l    = 500;
y_belt_z   = 36;                  // top run of the Y belt
y_pulley_z = y_belt_z - pulley_r;
y_motor_y  = -26;                 // Y motor axis, from front face of front bar
y_idler_y  = 26;                  // Y idler axis, from rear face of rear bar
carriage_plate_z = y_rod_z + lm_d/2 + 3;   // 40.5: bottom of aluminium Y plate
bed_size   = [214, 214];          // MK2 heatbed
bed_holes  = 208.5;               // heatbed mounting hole spacing
bed_top    = 60;                  // top of build surface

// ---------- Z axis ----------
z_screw_x  = 165;                 // Z screws at +/- this X
z_rod_off  = 18;                  // Z smooth rod is this far outboard of the screw
z_plane_y  = gantry_y - ext/2 - 23;   // 52
z_motor_top = nema_l + 5;         // 52: motor face; the motor body stays 5 mm above the table
z_rod_l    = 500;
z_screw_l  = 500;                 // do not cut the lead screws

// ---------- X axis ----------
x_rod_y    = z_plane_y - 22;      // 30
x_rod_dist = 45;
x_rod_l    = 390;
xend_h     = 62;
xend_rod_z = 8.5;                 // bottom X rod, from X-end bottom
belt_z     = xend_rod_z + x_rod_dist/2;   // X belt centre, from X-end bottom
x_motor_x  = -50;                 // X motor axis, from Z screw (outboard)
x_idler_x  = -42;                 // X idler axis, from Z screw (outboard)
hotend_y   = -30;                 // hotend axis, from X rod plane
nozzle_z   = -45;                 // nozzle tip, from bottom X rod
hotend_top = nozzle_z + v6_len;   // 17.5

// ---------- Extruder (feeder) ----------
e_motor_x  = -100;                // feeder motor axis X, on top of the top bar
e_motor_z  = 6 + nema_w/2;        // motor axis above the top bar (5 mm base + 1 mm gap)

// ---------- MK2 parts on our frame (assembly_mk2.scad) ----------
// The MK2-2020 GrabCAD parts keep their shape; these values move them onto this frame.
mk2_motor_l   = 30;                       // Z motor body length in the MK2 model
mk2_z_raise   = nema_l - mk2_motor_l;     // 17: Z-bottom parts sit higher on the uprights for 47 mm motors
mk2_bed_raise = 36;                       // bed spacers: X-end must clear the Z couplers at Z = 0
mk2_carriage_t = 3;                       // Y carriage plate: 3 mm aluminium (the MK2 model plate is 5 mm)
bed_spacer_h  = mk2_bed_raise - 12 + (5 - mk2_carriage_t);   // 26: printed spacer; the spring takes 12 mm
mk2_y_rod_x   = 85;                       // MK2 Y rod clamps
mk2_x_rod_l   = 471;                      // X rods for this frame (cut from 500)

// ---------- Preview position: [nozzle X, nozzle Y on bed, Z height] ----------
pos = [0, 0, 0];
