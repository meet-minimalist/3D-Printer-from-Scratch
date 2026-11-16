// Y carriage plate (MK2 shape) as a 2D cutting file for laser cutting. Export as DXF.
// Outline and cut-outs come from the MK2-2020 model (section at mid-thickness); holes are resized
// to 3.4 mm for M3, and the bed holes are moved to our MK2 heatbed spacing (bed_holes).
// Origin: plate centre. +Y is the rear of the printer. Material: 3 mm aluminium (mk2_carriage_t).
include <../config.scad>

old_bed = 104.5;                                   // MK42 bed hole position in the MK2 model
holes = concat(
    [for (x = [-1, 1], y = [-1, 1]) [x * bed_holes/2, y * bed_holes/2]],   // heatbed (via bed spacers)
    [[-95, -35], [-75, -35], [-95, 35], [-75, 35], [75, 0], [95, 0]],       // Y bearing holders
    [[0, -20], [0, 21]]);                                                    // Y belt holder

module y_carriage_plate() difference() {
    union() {
        projection(cut = true) translate([0, -248.48, 178.08])
            import("../../third_party/grabcad_files/prusa-i3-mk2-2020_stl/placed/i3_mk2_1___Y_AXIS_ASM_1___I3_CARRIAGE_1.stl");
        for (x = [-1, 1], y = [-1, 1]) translate([x * old_bed, y * old_bed]) circle(d = 3.2, $fn = 32);  // fill old holes
    }
    for (h = holes) translate(h) circle(d = m3_d, $fn = 48);
}

y_carriage_plate();
