"""Build the step-by-step assembly guide: render each step with assembly_steps.scad, crop it, add the
step number, and write assembly_guide/index.html.

Usage: python make_guide.py            (render all steps, then write the page)
       python make_guide.py 7 9        (render only these steps)
       python make_guide.py --html     (only write the page)
"""
import html, math, os, re, subprocess, sys
from PIL import Image, ImageChops, ImageDraw, ImageFont

OSC = r'C:\Program Files\OpenSCAD\openscad.com'
CAD = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
SIZE = (2400, 1800)
# camera rotation [rx, rz] per step (rz = turn around the vertical axis)
CAMS = [(60, 35), (75, 35), (60, 35), (60, 35), (65, 60), (65, 330), (55, 35), (55, 150), (70, 35), (60, 35),
        (60, 35), (70, 15), (45, 20), (60, 35), (60, 35), (70, 330), (70, 330), (70, 0), (60, 35)]

# smaller labels on crowded bench steps (label size = view size / divisor)
LABEL_DIV = {12: 50, 13: 65}

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'assembly_guide')

# title, new parts [(name, qty, note)], hardware, instructions
STEPS = [
 ("Base frame",
  [("2020 bar 520 mm (side)", 2, ""), ("2020 bar 400 mm (front, rear)", 2, ""), ("Corner bracket", 4, "inside each corner")],
  "8 × M4×10 + washer, 8 × M4 T-nut",
  ["The front and rear bars go <b>between</b> the side bars.",
   "Your T-nuts are the <b>drop-in</b> type: put one into the slot from the top, then turn the screw; the nut turns 90° and locks. You can add them at any time.",
   "Fit 1 corner bracket in each inside corner. Tighten lightly.",
   "Put the frame on a flat table. Measure both diagonals; they must be equal (±1 mm). Then tighten."]),
 ("Feet",
  [("Rubber foot Penn-Elcom F1697", 4, "under the side-bar ends")],
  "4 × M4×16 or M4×25 (test which fits, see the check) + washer, 4 × M4 T-nut (bottom slot)",
  ["Fit one foot under each end of the side bars.",
   "Check: 4–6 mm of the screw must come out of the top of the foot. If more, use the shorter screw or add a washer."]),
 ("Uprights",
  [("2020 bar 520 mm (upright)", 2, ""), ("Corner bracket", 2, "rear face, at the bottom")],
  "4 × M4×10 + washer, 4 × M4 T-nut",
  ["Stand each upright on its side bar. The front face of the upright is <b>335 mm</b> from the front end of the side bar.",
   "Fit 1 corner bracket on the <b>rear</b> face. The front face has no bracket: the Z motor (step 6) is there.",
   "Check with a square that each upright is vertical. The braces (step 5) make it stiff."]),
 ("Top bar",
  [("2020 bar 400 mm (top)", 1, "between the uprights"), ("Corner bracket", 2, "under the top bar"), ("T-shape joining plate", 2, "rear face")],
  "8–10 × M4×10 + washer, 8–10 × M4 T-nut",
  ["Fit the top bar between the tops of the uprights.",
   "Fit 1 corner bracket under each end and 1 T-plate on each rear corner.",
   "Check that the distance between the uprights is the same at the top and at the bottom."]),
 ("Diagonal braces",
  [("2020 bar 290 mm (brace)", 2, ""), ("Brace gusset top / bottom (printed 24, 25)", "2 + 2", "outer faces")],
  "12 × M4×12 + washer, 12 × M4 T-nut",
  ["Fit each brace in line with its side: top end on the upright, bottom end on the side bar.",
   "Fix both ends with the printed gussets on the <b>outer</b> face.",
   "Check again that the uprights are vertical before you tighten."]),
 ("Z-bottom parts and Z motors",
  [("Z bottom left / right (printed 08, 09)", "1 + 1", ""), ("NEMA17 motor", 2, "below the Z-bottom"), ("Flexible coupler 5–8 mm", 2, "on the motor shaft")],
  "8 × M3×10 (motors), 4 × M4×12 + washer + T-nut (Z-bottoms)",
  ["Fit each Z-bottom on the front of its upright, <b>17 mm above the side bar</b> (the 47 mm motor body must clear the bar by approx. 3 mm).",
   "Fit each motor under its Z-bottom with 4 × M3×10.",
   "Push the coupler on the shaft, 5 mm end down. Tighten the lower grub screws only."]),
 ("Y rods",
  [("Y rod clamp (printed 15)", 4, "top slots of front and rear bars"), ("8 mm rod 500 mm", 2, ""), ("LM8UU", 3, "2 on the left rod, 1 on the right rod")],
  "8 × M4×12 + washer, 8 × M4 T-nut",
  ["<b>First slide the 3 LM8UU bearings onto the rods: 2 on the left rod, 1 on the right rod.</b>",
   "Fit the clamps at X = ±85 mm from the centre of the frame (rods 170 mm apart).",
   "Check that the rods are parallel (same distance at the front and at the rear) and at the same height."]),
 ("Y motor and Y idler",
  [("Y motor mount (printed 11)", 1, "rear bar"), ("NEMA17 motor", 1, ""), ("GT2 20T pulley", 1, ""),
   ("Y idler holder (printed 12)", 1, "front bar"), ("GT2 idler, 3 mm bore", 1, "")],
  "4 × M3×10 (motor), 4 × M4×12 + washer + T-nut, 1 × M3×25 + nut (idler axle)",
  ["Fit the Y motor mount on the rear bar, centred: 2 screws in the front slot, 2 in the top slot.",
   "Fit the motor with 4 × M3×10. Put the pulley on the shaft in line with the centre of the frame.",
   "Fit the idler holder on the front bar, centred, and the idler on its M3 axle."]),
 ("Y carriage",
  [("Y carriage (printed 27)", 1, "on top of the bearings"),
   ("Y bearing holder (printed 14)", 3, "under the bearings"), ("Y belt holder (printed 13)", 1, "under the centre")],
  "6 × M3×16 + nuts (bearing holders), 2 × M3×16 + nuts (belt holder)",
  ["Put the carriage on the 3 bearings.",
   "Clamp each bearing from below with a bearing holder (2 screws each).",
   "Fit the belt holder under the centre of the carriage.",
   "Move the carriage by hand: it must slide freely along the full length."]),
 ("Y belt",
  [("GT2 belt", 1, "approx. 1 m")],
  "zip ties",
  ["Clamp one belt end in the belt holder.",
   "Route the belt around the front idler, then to the rear motor pulley, then back to the belt holder.",
   "Pull it tight (it must sound like a low note when you pluck it) and clamp the other end."]),
 ("Heatbed",
  [("Bed spacer (printed 16)", 4, "on the carriage corners"), ("Bed spring", 4, ""), ("Heatbed MK2 214 mm", 1, "")],
  "4 × <b>M3×50</b> + nyloc nuts (from the top, through bed, spring, spacer, carriage)",
  ["Put a spacer on each corner hole of the carriage and a spring on each spacer.",
   "Put the heatbed on the springs and fit the 4 screws from the top.",
   "Tighten until each spring is compressed by approx. half. You level the bed later."]),
 ("X-ends (on the bench)",
  [("X-end motor (printed 01)", 1, ""), ("X-end idler (printed 02)", 1, ""), ("LM8UU", 2, "one in each X-end"),
   ("T8 brass nut", 2, "top of each X-end"), ("NEMA17 motor", 1, "X motor"), ("GT2 20T pulley", 1, ""),
   ("GT2 idler, 3 mm bore", 1, ""), ("Micro switch (X endstop)", 1, "")],
  "4 × M3×10 (motor), 4–8 × M3×10 (T8 nuts), 1 × M3×30 + nut (idler axle), 2 × M2/M3 (switch)",
  ["Push one LM8UU into the bearing hole of each X-end (from the top), with zip ties.",
   "Fit a T8 brass nut on top of each X-end: flange in the recess, screws into the holes.",
   "Fit the X motor on the X-end motor with <b>4</b> screws, and the pulley on its shaft.",
   "Fit the idler in the X-end idler on its M3 axle, and the micro switch on the X-end motor."]),
 ("X axis (on the bench)",
  [("8 mm rod 471 mm (cut)", 2, ""), ("X carriage (printed 03)", 1, ""), ("LM8UU", 3, "2 on the top rod, 1 on the bottom rod"), ("GT2 belt", 1, "approx. 1 m")],
  "zip ties, M3 square nuts in the carriage slots",
  ["Push the 3 bearings into the carriage and fix them with zip ties.",
   "Slide the 2 rods through the carriage bearings, then push the rod ends fully into both X-ends.",
   "Fix one belt end on the carriage, route it around the motor pulley and the idler, and back to the carriage. Tension it."]),
 ("Fit the X axis",
  [("Complete X axis from steps 12–13", 1, "")],
  "–",
  ["Lower the X axis between the uprights.",
   "Line up each X-end bearing over the rod hole of its Z-bottom, and each T8 nut over its coupler. Support the X axis on blocks."]),
 ("Z rods and lead screws",
  [("8 mm rod 500 mm", 2, ""), ("T8 lead screw 500 mm", 2, ""), ("Z top (printed 10)", 2, "")],
  "4 × M4×12 + washer + T-nut (Z tops)",
  ["Slide each Z rod down from the top through the X-end bearing into the Z-bottom.",
   "Turn each lead screw down through its T8 nut into the coupler. Tighten the upper grub screws.",
   "Fit the Z tops on the top of the rods and bolt them to the uprights. <b>The top of the lead screw stays free.</b>",
   "Turn both lead screws by hand until the X axis is level (same height left and right)."]),
 ("Extruder drive (on the X carriage)",
  [("Extruder body (printed 04)", 1, ""), ("NEMA17 motor (your shortest)", 1, ""), ("MK8 drive gear", 1, ""),
   ("Extruder idler (printed 06)", 1, ""), ("625 bearing + 5×16 pin (M5×16)", 1, "")],
  "3 × M3 (motor), 2 × M3×40 + springs (idler tension), M5 nyloc (pin)",
  ["Fit the motor on the extruder body with 3 screws (the idler arm needs the 4th corner).",
   "Fit the MK8 gear on the shaft so that its groove lines up with the filament path.",
   "Fit the 625 bearing in the idler on the pin, then the idler with its 2 tension screws and springs.",
   "Bolt the extruder body to the X carriage."]),
 ("Hotend and fans",
  [("E3D V6 hotend", 1, ""), ("Extruder cover (printed 05)", 1, "clamps the hotend"), ("30 mm fan", 1, "hotend fan"),
   ("Fan nozzle (printed 07)", 1, ""), ("5015 blower", 1, "part cooling")],
  "M3 screws from the M3×25 set, square nuts",
  ["Cut the PTFE tube in the hotend flush with the top of the heatsink.",
   "Put the hotend groove into the extruder body and clamp it with the cover.",
   "Fit the 30 mm fan on the heatsink side, and the 5015 blower with the fan nozzle."]),
 ("Electronics",
  [("Power supply 12 V 15 A", 1, "right side"), ("Heatbed MOS module", 1, "right side, behind the PSU"), ("MKS Gen L", 1, "left side"), ("Raspberry Pi 3B+", 1, "left side")],
  "M4×10 + washer + T-nut, M3 standoffs for the boards, cable ties",
  ["Fit the power supply on the outside of the right side bar, and the board and Pi on the left.",
   "Fit the MOS module on the right side bar, between the power supply and the Z motor. The bed current (approx. 11 A) then uses short wires from the power supply.",
   "<b>Do not connect power yet.</b> Wiring and the Klipper configuration come next."]),
 ("Complete printer: checks",
  [],
  "–",
  ["Move each axis by hand: X, Y and Z must move smoothly over the full length.",
   "Belts tight, all grub screws tight, all frame screws tight.",
   "Z: both sides at the same height. Bed: approximately level with the nozzle path."]),
]

TNUT = [("Each side bar", "top slot: upright bracket 1, Z-bottom 2, brace gusset area 3 (outer slot); bottom slot: foot 2; right bar outer slot: power supply 2, MOS module 2"),
        ("Front bar", "top slot: rod clamps 4, Y idler holder 2"),
        ("Rear bar", "top slot: rod clamps 4, Y motor mount 2; front slot: Y motor mount 2"),
        ("Each upright", "front face: Z-bottom 2, Z top 2, endstop 1; rear face: bracket 1, T-plate 2; outer face: gusset 3; inner face: top bracket 1"),
        ("Top bar", "bottom face: brackets 2; rear face: T-plates 2"),
        ("Each brace", "outer face: gussets 2")]

def render(i, title):
    """Aim the camera at the new parts of step i, render, crop, and add the step number."""
    rx, rz = CAMS[i - 1]
    scad = os.path.join(CAD, 'assembly_steps.scad')
    echo = os.path.join(OUT, f'step_{i:02d}.echo')
    subprocess.run([OSC, '-D', f'step={i}', '-o', echo, scad], capture_output=True)
    pts = [tuple(map(float, m)) for m in re.findall(r'PT\|([-\d.e]+)\|([-\d.e]+)\|([-\d.e]+)', open(echo).read())]
    os.remove(echo)
    if not pts:                                    # last step: the whole printer
        pts = [(-260, -300, -32), (300, 300, 600)]
    lo = [min(p[k] for p in pts) for k in range(3)]; hi = [max(p[k] for p in pts) for k in range(3)]
    c = [(lo[k] + hi[k]) / 2 for k in range(3)]
    ext = max(60.0, math.dist(lo, hi))
    dist = ext * 2.6
    bs = max(4.0, ext / LABEL_DIV.get(i, 40))
    png = os.path.join(OUT, f'step_{i:02d}.png')
    cmd = [OSC, '-D', f'step={i}', '-D', f'rx={rx}', '-D', f'rz={rz}', '-D', f'bs={bs:.1f}', '-o', png,
           f'--imgsize={SIZE[0]},{SIZE[1]}', f'--camera={c[0]:.1f},{c[1]:.1f},{c[2]:.1f},{rx},0,{rz},{dist:.0f}',
           '--colorscheme=Tomorrow', scad]
    for attempt in (1, 2):                         # OpenSCAD sometimes hangs while rendering: retry once
        try:
            r = subprocess.run(cmd, capture_output=True, text=True, timeout=420)
            break
        except subprocess.TimeoutExpired:
            print(f'step {i}: render timed out (attempt {attempt})', flush=True)
    else:
        return
    warn = [l for l in (r.stdout + r.stderr).splitlines() if re.search('WARNING|ERROR', l)]
    crop(png)
    banner(png, i, title)
    print(f'step {i:2d}: {title:32s} {len(warn)} warnings', flush=True)

def banner(p, i, title):
    im = Image.open(p).convert('RGB')
    h = 110
    out = Image.new('RGB', (im.width, im.height + h), (250, 250, 250))
    out.paste(im, (0, h))
    d = ImageDraw.Draw(out)
    try:
        big = ImageFont.truetype('arialbd.ttf', 64); small = ImageFont.truetype('arial.ttf', 40)
    except OSError:
        big = small = ImageFont.load_default()
    d.ellipse((24, 14, 106, 96), fill=(232, 115, 12))
    num = ImageFont.truetype('arialbd.ttf', 64)
    tw = d.textlength(str(i), font=num)
    d.text((65 - tw / 2, 20), str(i), font=num, fill='white')
    text, size = f'Step {i}: {title}', 64
    while size > 28 and d.textlength(text, font=big) > out.width - 150:      # shrink the title to fit
        size -= 4; big = ImageFont.truetype('arialbd.ttf', size)
    d.text((128, 55 - size // 2 - 4), text, font=big, fill=(34, 34, 34))
    out.save(p)

def crop(p):
    im = Image.open(p).convert('RGB')
    bg = Image.new('RGB', im.size, im.getpixel((0, 0)))
    box = ImageChops.difference(im, bg).getbbox()
    if box:
        m = 30
        box = (max(0, box[0] - m), max(0, box[1] - m), min(im.width, box[2] + m), min(im.height, box[3] + m))
        im.crop(box).save(p)

args = sys.argv[1:]
if '--html' not in args:
    todo = [int(a) for a in args] or range(1, len(STEPS) + 1)
    for i in todo:
        render(i, STEPS[i - 1][0])

cards = []
for i, (title, parts, hw, steps) in enumerate(STEPS, 1):
    img = f'step_{i:02d}.png'
    rows = ''.join(f'<tr><td><span class="tag">{k}</span> {html.escape(n)}</td><td class="q">{q}</td><td class="n">{html.escape(note)}</td></tr>' for k, (n, q, note) in enumerate(parts, 1))
    table = f'<table class="parts"><tr><th>New part</th><th>Qty</th><th>Where</th></tr>{rows}</table>' if parts else ''
    lis = ''.join(f'<li>{s}</li>' for s in steps)
    cards.append(f'''<section class="step" id="s{i}">
  <h2><span class="num">{i}</span>{html.escape(title)}</h2>
  <img src="{img}" alt="Step {i}: {html.escape(title)}">
  <div class="info">{table}<p class="hw"><b>Hardware:</b> {hw}</p><ol>{lis}</ol></div>
</section>''')

toc = ''.join(f'<a href="#s{i}">{i}. {html.escape(t[0])}</a>' for i, t in enumerate(STEPS, 1))
tn = ''.join(f'<tr><td>{a}</td><td>{b}</td></tr>' for a, b in TNUT)
page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Prusa i3 Build Guide</title>
<style>
:root{{--bg:#fafafa;--card:#fff;--ink:#222;--mute:#666;--line:#ddd;--acc:#e8730c}}
@media (prefers-color-scheme:dark){{:root:not([data-theme="light"]){{--bg:#16181b;--card:#1f2226;--ink:#e8e8e8;--mute:#a0a0a0;--line:#33373c}}}}
:root[data-theme="dark"]{{--bg:#16181b;--card:#1f2226;--ink:#e8e8e8;--mute:#a0a0a0;--line:#33373c}}
body{{margin:0;background:var(--bg);color:var(--ink);font:15px/1.5 system-ui,Segoe UI,Arial,sans-serif}}
main{{max-width:1100px;margin:auto;padding:16px}}
h1{{margin:.2em 0}} .sub{{color:var(--mute)}}
nav{{display:flex;flex-wrap:wrap;gap:6px;margin:12px 0 20px}} nav a{{font-size:13px;padding:4px 8px;border:1px solid var(--line);border-radius:6px;color:var(--ink);text-decoration:none;background:var(--card)}}
.step{{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:16px;margin:0 0 20px;break-inside:avoid}}
.step h2{{margin:0 0 10px;font-size:20px;display:flex;align-items:center;gap:10px}}
.num{{background:var(--acc);color:#fff;border-radius:50%;width:32px;height:32px;display:inline-flex;align-items:center;justify-content:center;font-size:16px;flex:none}}
.step img{{width:100%;height:auto;border-radius:6px;background:#f8f8f8}}
.parts{{border-collapse:collapse;width:100%;margin:10px 0}} .parts th,.parts td{{border-bottom:1px solid var(--line);padding:5px 6px;text-align:left;vertical-align:top}}
.tag{{display:inline-block;min-width:20px;height:20px;border-radius:50%;background:var(--acc);color:#fff;text-align:center;font-size:12px;line-height:20px;margin-right:4px}} .q{{white-space:nowrap}} .n{{color:var(--mute)}} .hw{{margin:6px 0}} ol{{margin:6px 0 0 20px;padding:0}} li{{margin:3px 0}}
.legend{{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:12px 16px;margin-bottom:20px}}
@media print{{nav{{display:none}} .step{{page-break-inside:avoid}}}}
</style></head><body><main>
<h1>Prusa i3 (MK2 parts, 2020 frame) — build guide</h1>
<p class="sub">One step per picture. The <b>orange numbers</b> in each picture match the numbers in the parts table of that step. <b>Coloured parts</b> are new in that step; they are pulled out along the direction in which you fit them, and <b>dashed lines</b> show where they go. <b>Transparent grey</b> parts were fitted in earlier steps. Steps 12, 13, 16 and 17 are done on the bench.</p>
<nav>{toc}</nav>
<div class="legend"><b>Frame screws:</b> all frame screws are <b>M4</b> into M4 T-nuts. Put an <b>M4 washer</b> under each screw head (the holes in the brackets and printed parts are 5.5 mm). Tighten a screw: if it stops but the part can still move, the screw touches the bottom of the slot; add 1 more washer.<br><b>Corner brackets:</b> 8 are used (4 base, 2 upright rear faces, 2 under the top bar). No other joint has a free 90° corner, so keep the other brackets as spares.<br><b>T-nuts:</b> your T-nuts are the <b>drop-in</b> type (6 × 10 mm, M4): put them into the slot from the top at any time. Approximate number per bar:
<table class="parts">{tn}</table></div>
{''.join(cards)}
</main></body></html>'''
open(os.path.join(OUT, 'index.html'), 'w', encoding='utf-8').write(page)
print('written', os.path.join(OUT, 'index.html'))
