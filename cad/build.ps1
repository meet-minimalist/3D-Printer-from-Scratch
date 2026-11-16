# Exports every printed part to stl/ and renders preview images to images/.
# Usage (PowerShell 7):  ./build.ps1          or   ./build.ps1 -SkipImages
param([switch]$SkipImages)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$osc = 'C:\Program Files\OpenSCAD\openscad.com'
New-Item -ItemType Directory -Force stl, images | Out-Null

# file, part, output name, quantity to print
$parts = @(
    @('parts/x_end.scad',       'motor',             'x_end_motor',        1),
    @('parts/x_end.scad',       'idler',             'x_end_idler',        1),
    @('parts/x_carriage.scad',  'carriage',          'x_carriage',         1),
    @('parts/x_carriage.scad',  'clamp',             'hotend_clamp',       1),
    @('parts/z_mounts.scad',    'motor_mount',       'z_motor_mount_left', 1),
    @('parts/z_mounts.scad',    'motor_mount_right', 'z_motor_mount_right',1),
    @('parts/z_mounts.scad',    'top_holder',        'z_top_holder_left',  1),
    @('parts/z_mounts.scad',    'top_holder_right',  'z_top_holder_right', 1),
    @('parts/y_parts.scad',     'motor_mount',       'y_motor_mount',      1),
    @('parts/y_parts.scad',     'idler',             'y_idler',            1),
    @('parts/y_parts.scad',     'rod_holder',        'y_rod_holder',       4),
    @('parts/y_parts.scad',     'bearing_holder',    'y_bearing_holder',   4),
    @('parts/y_parts.scad',     'belt_clamp',        'y_belt_clamp',       1),
    @('parts/frame_parts.scad', 'gusset_top',        'brace_gusset_top',   2),
    @('parts/frame_parts.scad', 'gusset_bottom',     'brace_gusset_bottom',2),
    @('parts/frame_parts.scad', 'endstop_holder',    'endstop_holder',     3),
    @('parts/extruder_mount.scad', 'all',             'extruder_mount',     1),
    @('parts/bed_spacer.scad',  'all',               'bed_spacer',         4),
    @('parts/y_motor_mount_mk2.scad', 'all',         'y_motor_mount_mk2',  1),
    @('parts/y_carriage_printed.scad', 'all',        'y_carriage_printed', 1)
)

foreach ($p in $parts) {
    $out = "stl/$($p[2]).stl"
    $log = & $osc -o $out -D "part=`"$($p[1])`"" $p[0] 2>&1 | Out-String
    $simple = if ($log -match 'Simple:\s+no|WARNING') { 'CHECK' } else { 'ok' }
    if ($LASTEXITCODE -ne 0 -or $log -match 'ERROR|WARNING') { Write-Host $log }
    '{0,-22} x{1}  {2}' -f $p[2], $p[3], $simple
}

if (-not $SkipImages) {
    $views = @{ iso = '0,0,250,60,0,35,1900'; front = '0,0,280,90,0,0,1700'; side = '0,0,280,90,0,90,1700'; top = '0,0,0,0,0,0,1700' }
    foreach ($k in $views.Keys) {
        & $osc -o "images/assembly_$k.png" --imgsize=1600,1200 --camera=$($views[$k]) --colorscheme=Tomorrow --projection=o assembly.scad 2>&1 | Out-Null
    }
    foreach ($k in $views.Keys) {
        & $osc -o "images/mk2_$k.png" --imgsize=1600,1200 --camera=$($views[$k]) --colorscheme=Tomorrow --projection=o assembly_mk2.scad 2>&1 | Out-Null
    }
    foreach ($f in 'x_end', 'x_carriage', 'z_mounts', 'y_parts', 'frame_parts', 'extruder_mount') {
        & $osc -o "images/parts_$f.png" --imgsize=1200,900 --viewall --autocenter --colorscheme=Tomorrow "parts/$f.scad" 2>&1 | Out-Null
    }
    'images done'
}
