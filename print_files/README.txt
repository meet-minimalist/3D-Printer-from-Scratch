Prusa i3 (MK2 parts on a 2020 frame) - files for 3D printing
=============================================================

26 STL files, 45 pieces in total. The quantity is in each file name (_x2 = print 2).
SET THE QUANTITY ON THE ORDER WEBSITE: it does not read the _x2 / _x4 in the file name.

Folders
- 1_order_now_machine_parts (19 files, 31 pieces): axes, extruder, motor mounts, brace gussets. Order these.
- 2_optional_frame_connectors (7 files, 14 pieces): feet, corner blocks, top gussets.
  Cheaper: use aluminium 2020 corner brackets, joining plates and rubber feet instead
  (see Prusa_i3_build_list.xlsx), and print these later on your own printer if you want them.
Full list with notes: PRINT_LIST.csv. Pictures of all parts: preview.png.
- laser_cut/y_carriage_plate_3mm_aluminium.dxf: Y carriage plate, 3 mm aluminium, 220 x 220 mm,
  12 holes of 3.4 mm. Upload to the Robu laser cutting service (or any laser cutting shop).
- 3_optional_y_carriage_printed/27_y_carriage_printed_x1.stl: printed alternative to the aluminium plate
  (PETG, 3 mm base + 5 mm ribs on top). Print flat, ribs up, no supports. 220 x 220 mm: the printer bed
  must be at least 230 x 230 mm. Use 30-40 % infill and 4 walls.

Print settings (all parts)
- Material: PETG (not PLA: the parts near the motors and the heatbed get warm)
- Quality option on the order website: "0.2 mm Standard Quality" (0.4 mm nozzle)
- Perimeters (walls): 4, top/bottom layers: 5
- Infill: 40 % (gyroid or grid). 30 % also works (Prusa uses 20-30 %), but 40 % makes the motor mounts and the printed Y carriage stiffer for a small extra cost.
- Supports: avoid. Supports are hard to remove from PETG (Robu "Basics of 3D Printing", p. 31).

Orientation
- All files are already placed flat on the bed. Do not rotate them.
  - 01_x_end_motor: no supports needed. The motor plate is a solid 3.5 mm square down to the bed.
  - 03_x_carriage, 04_extruder_body: check the slicer preview for overhangs above 45 deg;
    if needed, use "supports on build plate only".
  - 19_frame_top_gusset (optional): print 2 the same; turn one over at assembly for the other side.

Checked against the Robu guide (pp. 20-23)
- Overhangs: our own parts (11, 16, 24, 25, 26) have no overhangs above 45 deg in the given orientation.
- Walls: our own parts have walls of 1.7 mm or more (guide: 0.8 mm minimum, 1.5 mm recommended).
- Corners: flat parts 24/25 have 4 mm corner radii; part 11 has 3 mm (limited by the motor screw holes).
- Clearance: our holes are 0.2-0.4 mm larger than the screws (guide: 0.15 mm tight, 0.3 mm loose).

After printing (holes print slightly undersize, guide p. 21)
- Clean the holes with a drill by hand: 3.2-3.4 mm for M3, 5.5 mm for M5.
- Bearing pockets (LM8UU, 15 mm) and rod holes (8 mm): sand lightly until the part slides on;
  do not drill them oversize.

Before you print everything
- Print 01_x_end_motor and 15_y_rod_clamp first. Check the fit of the LM8UU bearings,
  the 8 mm rods and the T8 brass nut. If holes are too tight, ask for "hole compensation"
  (XY hole expansion approx. 0.1-0.2 mm) in the slicer.
