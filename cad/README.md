# Prusa i3 with 2020 frame – OpenSCAD model

Parametric CAD for a Prusa i3 type printer built from 8 × 590 mm 2020 bars,
6 × 500 mm smooth rods, 2 × T8 lead screws (500 mm), 5 × NEMA17 and a 214 × 214 mm MK2 heatbed.

## Files

| File | Content |
|---|---|
| `config.scad` | All dimensions. Change values here only. |
| `assembly.scad` | Full printer. Open in OpenSCAD and press F5. |
| `lib/vitamins.scad` | Models of bought parts. Motor, pulley, coupler, T8 nut and endstop use meshes from `vendor/`. |
| `vendor/*.stl` | Bought parts converted from the owner's GrabCAD STEP files (preview only, do not print). |
| `parts/x_end.scad` | X-end motor and X-end idler |
| `parts/x_carriage.scad` | X carriage (V6 groove mount) and hotend clamp |
| `parts/z_mounts.scad` | Z motor mounts and Z top rod holders (left and right) |
| `parts/y_parts.scad` | Y motor mount, Y idler, Y rod holder, Y bearing holder, Y belt clamp |
| `parts/frame_parts.scad` | Brace gussets and endstop holder |
| `parts/extruder_mount.scad` | Feeder motor mount on the top bar |
| `build.ps1` | Exports all STL files to `stl/` and images to `images/` |

To move the axes in the preview, change `pos = [x, y, z]` in `config.scad`.

## Parts to print (PETG, 0.2 mm layers, 4 perimeters, 40 % infill)

| STL | Qty | Notes |
|---|---|---|
| x_end_motor | 1 | Print standing up (as modelled) |
| x_end_idler | 1 | Print standing up (as modelled) |
| x_carriage | 1 | Lay the flat front plate on the bed |
| hotend_clamp | 1 | |
| z_motor_mount_left / right | 1 + 1 | |
| z_top_holder_left / right | 1 + 1 | |
| y_motor_mount | 1 | |
| y_idler | 1 | |
| y_rod_holder | 4 | |
| y_bearing_holder | 4 | Bearing snaps in from below |
| y_belt_clamp | 1 | |
| brace_gusset_top | 2 | Same part for left and right |
| brace_gusset_bottom | 2 | Same part for left and right |
| endstop_holder | 3 | |
| extruder_mount | 1 | Print with the base flat on the bed. NEMA17 + MK8 feeder, 2 × M5 T-nuts on the top bar |

Total: 25 parts.

## Frame cut list

| Bars | Cut | Use |
|---|---|---|
| 2 | 520 mm | Base sides (Y) |
| 2 | 400 mm | Base front and rear |
| 2 | 520 mm | Uprights |
| 1 | 400 mm | Top bar |
| 1 | 2 × 290 mm | Diagonal braces |

Smooth rods: Y 2 × 500 mm and Z 2 × 500 mm (do not cut). X 2 × 390 mm (cut).
Lead screws: 2 × 500 mm (do not cut).

## Main dimensions

- Build volume: approximately 205 × 205 × 300 mm
- Outer size: approximately 440 (W) × 600 (D, with Y motor and idler) × 540 (H) mm, plus the PSU on the right side
- Z rod to Z screw: 18 mm. X rod spacing: 45 mm.

## Version 2: Prusa i3 MK2 parts on this frame (current plan)

`assembly_mk2.scad` puts the original Prusa i3 MK2 printed parts (from the GrabCAD model
"Prusa i3 MK2 2020 aluminum profile") on this 2020 frame. Open it in OpenSCAD and press F5.
The MK2 parts are proven, made for 2020, and fit the T8 flange nut, the E3D V6 and a 625 idler bearing.

| File | Content |
|---|---|
| `assembly_mk2.scad` | Full printer with MK2 parts. Prints the X-end/coupler clearance and the Z travel in the console. |
| `mk2/mk2_items.scad` | Generated list of MK2 meshes and motor positions (do not edit) |
| `mk2/mk2_gen.py`, `mk2/step_tree.py` | Scripts: STEP -> STL meshes, and the list above |
| `mk2/prep_print.py` | Lays the MK2 parts flat and writes `stl_mk2/` |
| `parts/bed_spacer.scad` | Bed spacer (new part) |

Changes for your parts:
- Z-bottom parts are mounted 17 mm higher on the uprights (`mk2_z_raise`), because your motors are 47 mm long (MK2: 30 mm).
- The MK2 used motors with a built-in lead screw. Here a 5-8 coupler and the 500 mm T8 screw are used.
  The coupler makes the Z axis start higher, so the bed is raised 36 mm (`mk2_bed_raise`) with 4 printed bed spacers.
  Result: 3.5 mm clearance between X-end and coupler at Z = 0, and approximately 350 mm Z travel.
- X rods: 471 mm (cut from 500). Y and Z rods: 500 mm, not cut. Lead screws: 500 mm, not cut.
- The diagonal braces stay as 2020 bars with our gussets (the MK2-2020 model uses 8 mm rods).
- The MK2 extruder is direct drive (motor on the X carriage). `parts/extruder_mount.scad` is not needed.

### Parts to print (`stl_mk2/`, PETG; check each part in the slicer before you print)

| STL | Qty | | STL | Qty |
|---|---|---|---|---|
| x_end_motor | 1 | | y_motor_mount_mk2 (`stl/`, new: 4 motor screws) | 1 |
| x_end_idler | 1 | | y_idler_holder | 1 |
| x_carriage | 1 | | y_belt_holder | 1 |
| extruder_body | 1 | | y_bearing_holder | 3 |
| extruder_cover | 1 | | y_rod_clamp | 4 |
| extruder_idler | 1 | | | |
| fan_nozzle | 1 | | frame_foot | 4 |
| z_bottom_left | 1 | | frame_base_corner | 4 |
| z_bottom_right | 1 | | frame_top_gusset | 2 |
| z_top | 2 | | frame_top_corner_left / right | 1 + 1 |
| bed_spacer (`stl/`) | 4 | | frame_z_adapter_left / right | 1 + 1 |
| brace_gusset_top / bottom (`stl/`) | 2 + 2 | | endstop_holder (`stl/`, for Z) | 1 |

Notes:
- The orientation in `stl_mk2/` is automatic (largest face down). The X-ends print standing, as on the MK2.
  Some parts (extruder body, X carriage) can need supports or a different orientation: check in the slicer.
- Not used from the MK2: the Y motor holder (it holds the motor with only 2 screws; replaced by
  `parts/y_motor_mount_mk2.scad`, 4 x M3 into the motor and 4 x M5 into the rear bar) and the heatbed cable
  cover (made for the 254 mm MK42 bed). Use a zip tie on the bed cable.
- Endstops: the MK2 X-end holds a small micro switch (approx. 20 x 10 x 6 mm). Remove the switch from one
  endstop board, or buy a bare switch. For Y and Z, use endstop boards with `endstop_holder`
  (Y: on the base side bar, hit by the Y carriage; Z: on the left upright, hit by the X-end).
- The MK2 uses 16T pulleys. Your 20T pulleys also work: set `rotation_distance: 40` in Klipper.

## Limits of this model (version 1)

- The parts are a first design. They are not tested on a real printer. Print one X-end and
  check the fit of the bearings, rods and nut before you print all the parts.
- The X carriage bearings snap in (the pocket wraps 3 mm past the rod axis) and 2 zip ties hold each bearing.
  The X-end bearings push in from the ends and zip ties clamp them. The bearing pockets use press fit plus zip ties. If your printer prints holes too small,
  increase `clr` or `lm_d` in `config.scad`.
- The X-end holds the T8 brass nut: the nut body goes up into the bore, and 4 × M3 × 12 self-tapping
  screws hold the flange to the bottom face.
- The endstop positions in the assembly are approximate. Check them when you design the final mounts.
- Not included yet: part cooling fan duct, probe mount, spool holder, cable chains, electronics box.
- The belt clamps have a plain slot. Use zip ties on the belt ends, or add teeth later.
