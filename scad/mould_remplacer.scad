/*************************************************************************
 REMPLACER — agarose mouse-brain mould
 Two-part parametric mould generator with an oblique brainstem pour channel

 -----------------------------------------------------------------------
 ATTRIBUTION CHAIN  (please keep intact — this is a derivative work)
 -----------------------------------------------------------------------
 Original author : Jason Webb
                   http://jason-webb.info  (now https://jasonwebb.io)
                   "Parametric two-part mold generator"
                   https://www.thingiverse.com/thing:31581  (2012)

 Modified by     : Dan Steele (rocketboy on Thingiverse) — licensed CC BY
                   "Mold Generator - modified"
                   https://www.thingiverse.com/thing:447443  (2014)
                   - one registration key changed to a cube so the mould
                     cannot be assembled backwards
                   - optional pour hole

 Modified again  : Philippe Zizzari — REMPLACER outreach workshop
                   INSERM U1215, Neurocentre Magendie, 2026
                   https://github.com/g0ub
                   - imports a mouse-brain STL derived from the NITRC
                     tpm_mouse C57BL/6 template (Hikishima et al. 2017,
                     CC BY-NC-SA), positioned and scaled inside the mould
                   - OBLIQUE pour channel aligned on the brainstem:
                       * cone_between(): conical channel along an
                         arbitrary vector
                       * channel defined in the STL's own frame
                         (aims straight at the brainstem)
                       * half-channel subtracted from EACH half, so the
                         two halves form a complete conduit when closed
                   - REMPLACER / REPLACE text engraved on the back of each
                     half (along the 80 mm axis), and "remplacer" in French
                     braille IN RELIEF on the long lateral face of the bottom
                     half (centered, Marburg pitch — see parameters at top)

 roundedBox()    : from OpenSCAD's bundled example022.scad (public domain)

 -----------------------------------------------------------------------
 LICENSE: CC BY-NC-SA 4.0
 The brain geometry derives from a CC BY-NC-SA template, so the
 NonCommercial + ShareAlike terms apply to this whole work.
 Full attribution & citation: see CREDITS.md.  License text: see LICENSE.
*************************************************************************/

/*************************************************
 Mould size
*************************************************/
// Global scale factor for the whole mould (and the brain inside).
// Three sizes are shipped: 1.5, 1.75 and 3.
// - 1.5  : close to an adult mouse brain
// - 1.75 : intermediate size (large mouse / juvenile rat)
// - 3    : workshop version — the only size at which the braille is
//          tactilely readable (standard Marburg pitch of 6 mm).
mould_size_factor = 3;

// Enable or disable the braille in relief.
// The braille is laid out in standard Marburg pitch (ABSOLUTE dimensions,
// NOT scaled with the mould). Below mould_size_factor = 3 it does not fit
// on the lateral face — it must then be disabled.
show_braille = (mould_size_factor >= 3);

// Model parameters
model_filename  = "mold_file.stl";
model_rotate    = [90, 0, 0];
model_scale     = 0.10 * mould_size_factor;   // brain ~16 mm at ×1 (STL ~161 mm)
model_translate = [0, 0, 25];                 // CONSTANT (do not scale with factor)

// Mould parameters — ×1 baseline multiplied by the factor.
// Baseline ×1 (per half): 12.5 × 20 × 6.25 mm — strictly homothetic to the
// 50 × 80 × 25 mm workshop mould (×1 = workshop / 4).
mold_width   = 12.5 * mould_size_factor;    // along X axis
mold_height  = 20   * mould_size_factor;    // along Y axis
mold_depth   = 6.25 * mould_size_factor;    // along Z axis
mold_spacing = 3;                           // spacing between the two halves (preview only)
rounded_corners = true;                     // rounded corners reduce warping during printing
edge_radius  = 2    * mould_size_factor;    // radius of the rounded corners

// Key parameters (registration marks between the two halves)
key_size   = 0.75 * mould_size_factor;      // radius of the spherical keys
key_fettle = 0.4;                           // clearance between keys and their holes
key_margin = 1.75 * mould_size_factor;      // distance from the outer edge of the mould

/*************************************************
 Engraving parameters — text (back face) + braille (lateral face)
*************************************************/
// Text engraved on the BACK of each half. The text IS scaled with the mould
// (stays proportional and readable at every size).
text_top_str    = "REMPLACER";              // engraved on the back of the top half
text_bottom_str = "REPLACE";                // engraved on the back of the bottom half
text_size       = 2.25 * mould_size_factor; // letter height (mm) — 6.75 at ×3
text_depth      = 0.4  * mould_size_factor; // engraving depth (mm)
text_font       = "Liberation Sans:style=Bold";
// If the text comes out mirrored after printing, flip the relevant boolean:
text_mirror_top    = false;
text_mirror_bottom = true;

// Braille (standard French) — IN RELIEF on the long lateral face
// (x = -mold_width/2) of the bottom half, centred vertically and along Y.
// The word "remplacer" = 9 cells at the standard Marburg pitch (6 mm).
// Braille dimensions are ABSOLUTE (not scaled with the mould) — this is the
// tactile standard. At ×3, the 6 mm pitch fits within the 60 mm long face.
//   r        e     m       p         l       a   c     e     r
//   1235     15    134     1234      123     1   14    15    1235
braille_word = [
    [1,2,3,5],
    [1,5],
    [1,3,4],
    [1,2,3,4],
    [1,2,3],
    [1],
    [1,4],
    [1,5],
    [1,2,3,5]
];
braille_dot_d      = 1.5;               // dot base diameter at the surface (mm)
braille_dot_h      = 0.75;              // dot height above the face (mm) — Marburg standard ≈ 0.5
braille_dot_dist   = 2.5;               // dot spacing within a cell (Marburg standard)
braille_cell_pitch = 6.0;               // spacing between cells (Marburg standard)

/*************************************************
 Pour channel — aligned on the brainstem
*************************************************/
pour_hole     = 1;                          // 0 = no, 1 = yes
pour_funnel_r = 1.75 * mould_size_factor;   // entry radius (wide), in mm in the mould
pour_neck_r   = 0.6  * mould_size_factor;   // outlet radius (narrow), at the brainstem (mm)

// >>> Points in the STL FRAME — CALIBRATED on this mold_file.stl <<<
//   bs_tip   = tip of the brainstem (caudal-ventral extremity)
//   bs_entry = same oblique axis, extended to exit through the lower face
// (Re-calibrate with show_brain_debug if you change STL.)
bs_tip   = [ -0.3, -25.3,  76.4 ];
bs_entry = [  5.9, -43.1, 128.1 ];

// Debug helpers
show_brain_debug = false;   // true -> brain ALONE + markers, in STL coordinates
debug_tronc = false;        // true -> witness sphere on bs_tip (in the mould)
debug_canal = false;        // true -> channel rendered transparent in the mould (%)

if (show_brain_debug)
    debug_brain();          // <-- to CALIBRATE bs_tip / bs_entry
else
    side_by_side();

/****************************************
 Conical frustum between two 3D points.
 The obliquity follows directly from the vector p2 - p1.
 (cylinder of radius r1 at p1, r2 at p2)
*****************************************/
module cone_between(p1, p2, r1, r2, fn = 48) {
    v = p2 - p1;
    h = norm(v);
    if (h > 0)
        translate(p1)
            rotate([0, acos(v[2]/h), atan2(v[1], v[0])])
                cylinder(h = h, r1 = r1, r2 = r2, $fn = fn);
}

/****************************************
 Pour channel, defined in the brain frame.
 Wrapped in the SAME transformation chain as the STL import so it aims
 straight at the brainstem. The radii are divided by model_scale to cancel
 out the final scale.
*****************************************/
module pour_channel() {
    scale(model_scale)
        translate(model_translate)
            rotate(model_rotate)
                cone_between(bs_entry, bs_tip,
                             pour_funnel_r / model_scale,
                             pour_neck_r   / model_scale);
}

/****************************************
 Engrave text on the back of a half.
 The text is rotated 90° around Z to align with the long dimension of
 the mould (Y axis, the longest one).
   face_z    : absolute Z of the face in the half's local frame
   normal_z  : +1 if the face points towards +Z, -1 if towards -Z
   mirror_y  : true to pre-mirror along Y (set this if the text comes out
               mirrored once the printed part is flipped over)
*****************************************/
module text_engrave(str, face_z, normal_z, mirror_y) {
    eps = 0.2;
    translate([0, 0, face_z + normal_z * eps])
        mirror([0, 0, normal_z == 1 ? 1 : 0])           // extrude into the material
            mirror([0, mirror_y ? 1 : 0, 0])             // mirror along the reading axis
                rotate([0, 0, 90])                       // text aligned with Y
                    linear_extrude(height = text_depth + 2 * eps)
                        text(str, size = text_size,
                             halign = "center", valign = "center",
                             font = text_font);
}

/****************************************
 A single braille dot IN RELIEF: ellipsoidal dome centred on the X- face.
 - base diameter at the surface = braille_dot_d
 - height above the face        = braille_dot_h
 The inner half merges with the mould material (union).
*****************************************/
module _braille_dot() {
    // Sphere of radius braille_dot_d/2, stretched along X to reach the
    // desired height. At the x = 0 plane (the face), the cross-section
    // stays a circle of diameter braille_dot_d.
    scale([braille_dot_h / (braille_dot_d / 2), 1, 1])
        sphere(r = braille_dot_d / 2, $fn = 16);
}

/****************************************
 A single braille cell (list of active dots 1..6).
 On the X- face: Y = reading direction, Z = height (dot 1 at the top).
   1 . 4
   2 . 5
   3 . 6
 The cell is vertically centred (z = 0 at the middle).
*****************************************/
module _braille_cell(dots) {
    for (p = dots) {
        col = floor((p - 1) / 3);    // 0 (read first) or 1 (read second)
        row = (p - 1) % 3;           // 0 = top, 1 = middle, 2 = bottom
        translate([0,
                   col * braille_dot_dist,
                   (1 - row) * braille_dot_dist])
            _braille_dot();
    }
}

/****************************************
 Full braille word IN RELIEF, centred on the long lateral face
 (x = -mold_width/2) of the bottom half: centred vertically (z = 0 in
 local frame) and along the mould length (y = 0).
 Must be called in UNION with the half (not inside a difference).
*****************************************/
module braille_side_bottom() {
    n      = len(braille_word);
    word_w = (n - 1) * braille_cell_pitch + braille_dot_dist;   // word length along Y
    translate([-mold_width / 2,             // dots centred on the X- face
               -word_w / 2,                 // centred along Y
               0])                          // centred along Z (middle of the bottom half)
        for (i = [0 : n - 1])
            translate([0, i * braille_cell_pitch, 0])
                _braille_cell(braille_word[i]);
}

/****************************************
 Calibration view: brain ALONE in STL coordinates.
 The grid units shown match the STL coordinates, so the marker positions
 correspond DIRECTLY to the numbers in bs_tip / bs_entry.
   - RED sphere  -> bs_tip   : place it on the tip of the brainstem
   - BLUE sphere -> bs_entry : extend it out of the brain along the axis
*****************************************/
module debug_brain() {
    %import(model_filename);
    color("Red")  translate(bs_tip)   sphere(r = 4, $fn = 24);
    color("Blue") translate(bs_entry) sphere(r = 4, $fn = 24);
}

/****************************************
 Rotate and place both halves side by side
 along the X axis for easy single-plate printing
*****************************************/
module side_by_side() {
	// Bottom half -> right side (positive X)
	translate([mold_width/2 + mold_spacing/2, 0, mold_depth/2])
		bottom_half();

	// Top half -> left side (negative X), flipped
	translate([-mold_width/2 - mold_spacing/2, 0, mold_depth*3/2])
		rotate([0, 180, 0])
			top_half();
}

/*******************************************
 Bottom half of the mold
********************************************/
module bottom_half() {
	// Create the mould body, then subtract negative features.
	difference() {

		// Subtract the brain STL, then the pour channel
		difference() {
			difference() {
				if(rounded_corners) 
					roundedBox([mold_width, mold_height, mold_depth], edge_radius, true);
				else
					cube(size = [mold_width, mold_height, mold_depth], center = true);
	
				scale(model_scale)
					translate(model_translate)
						rotate(model_rotate)
							import(model_filename);
			}
			// Pour channel (bottom half-channel)
			if (pour_hole)
				pour_channel();
		}

		// Negative key 1
		translate([-mold_width/2 + key_margin, -mold_height/2 + key_margin, mold_depth/2])
			cube(size =[key_size+key_fettle,key_size+key_fettle,key_size+key_fettle], center=true);

		// Negative key 2
		translate([mold_width/2 - key_margin, mold_height/2 - key_margin, mold_depth/2])
			sphere(key_size + key_fettle, $fn = 30);

		// Engraved REPLACE on the back (face z = -mold_depth/2, normal towards -Z)
		text_engrave(text_bottom_str, -mold_depth/2, -1, text_mirror_bottom);
	}

	// Braille "remplacer" IN RELIEF on the long lateral face (x = -mold_width/2)
	// Centred along Y and Z (z = 0 local = vertical mid-plane of the half).
	// Only enabled from mould_size_factor >= 3 (see show_braille).
	if (show_braille)
		braille_side_bottom();

	// Positive key 1
	translate(v = [-mold_width/2 + key_margin, mold_height/2 - key_margin, mold_depth/2])
		sphere(r = key_size, $fn = 30);

	// Positive master key
	translate(v = [mold_width/2 - key_margin, -mold_height/2 + key_margin, mold_depth/2])
		sphere(r = key_size, $fn = 30);

	// --- Calibration helpers (rendered transparent) ---
	if (debug_tronc)
		%scale(model_scale) translate(model_translate) rotate(model_rotate)
			translate(bs_tip) sphere(3, $fn = 24);
	if (debug_canal)
		%pour_channel();
}

/*******************************************
 Top half of the mold
********************************************/
module top_half() {
	// Create the mould body, then subtract negative features.
	difference() {

		// Subtract the brain STL, then the pour channel
		difference() {
			translate([0, 0, mold_depth])
				if(rounded_corners) 
					roundedBox([mold_width, mold_height, mold_depth], edge_radius, true);
				else
					cube(size = [mold_width, mold_height, mold_depth], center = true);

			scale(model_scale)
				translate(v = model_translate)
					rotate(model_rotate)
							import(model_filename);

			// Pour channel (top half-channel)
			if (pour_hole)
				pour_channel();
		}

		// Negative master key
		translate(v = [mold_width/2 - key_margin, -mold_height/2 + key_margin, mold_depth/2])
			sphere(key_size + key_fettle, $fn = 30);

		// Negative key 2
		translate(v = [-mold_width/2 + key_margin, mold_height/2 - key_margin, mold_depth/2])
			sphere(key_size + key_fettle, $fn = 30);

		// Engraved REMPLACER on the back (face z = 3*mold_depth/2, normal towards +Z)
		text_engrave(text_top_str, 3 * mold_depth / 2, +1, text_mirror_top);
	}

	// Positive key 1
	translate(v = [mold_width/2 - key_margin, mold_height/2 - key_margin, mold_depth/2])
		sphere(key_size, $fn = 30);

	// Positive key 2 (cube -> anti-reverse-assembly feature)
	translate(v = [-mold_width/2 + key_margin, -mold_height/2 + key_margin, mold_depth/2])
		cube(size =[key_size,key_size,key_size], center=true);
}

/******************************************
 roundedBox module from example022.scad
 size is a vector [w, h, d]
******************************************/
module roundedBox(size, radius, sidesonly)
{
	rot = [ [0,0,0], [90,0,90], [90,90,0] ];
	if (sidesonly) {
		cube(size - [2*radius,0,0], true);
		cube(size - [0,2*radius,0], true);
		for (x = [radius-size[0]/2, -radius+size[0]/2],
				 y = [radius-size[1]/2, -radius+size[1]/2]) {
			translate([x,y,0]) cylinder(r=radius, h=size[2], center=true);
		}
	}
	else {
		cube([size[0], size[1]-radius*2, size[2]-radius*2], center=true);
		cube([size[0]-radius*2, size[1], size[2]-radius*2], center=true);
		cube([size[0]-radius*2, size[1]-radius*2, size[2]], center=true);

		for (axis = [0:2]) {
			for (x = [radius-size[axis]/2, -radius+size[axis]/2],
					y = [radius-size[(axis+1)%3]/2, -radius+size[(axis+1)%3]/2]) {
				rotate(rot[axis]) 
					translate([x,y,0]) 
					cylinder(h=size[(axis+2)%3]-2*radius, r=radius, center=true);
			}
		}
		for (x = [radius-size[0]/2, -radius+size[0]/2],
				y = [radius-size[1]/2, -radius+size[1]/2],
				z = [radius-size[2]/2, -radius+size[2]/2]) {
			translate([x,y,z]) sphere(radius);
		}
	}
}
