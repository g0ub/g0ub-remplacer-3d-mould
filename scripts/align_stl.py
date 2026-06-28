#!/usr/bin/env python3
"""
align_stl.py — Re-orient a mouse-brain STL into the convention expected by
the REMPLACER mould `.scad` file.

REMPLACER convention (after the mould's rotate([90, 0, 0])):
    - Axis Z of the STL  = antero-posterior axis of the brain (longest)
    - Axis Y of the STL  = dorso-ventral axis (shortest)
    - Axis X of the STL  = medio-lateral axis (intermediate)

Algorithm:
    1. Read the STL with trimesh.
    2. Filter out outlier vertices (stray points >3σ from the centroid),
       so Slicer / Blender export artefacts cannot bias the PCA.
    3. Run PCA on the cleaned vertex cloud → 3 principal axes.
    4. Align principal axis (longest)      -> STL Z   (antero-posterior)
       Align minor axis     (shortest)     -> STL Y   (dorso-ventral)
       Align middle axis    (intermediate) -> STL X   (medio-lateral)
    5. Heuristically detect antero-posterior chirality:
       the olfactory bulbs (anterior) form a finer tip than the cerebellum
       (posterior) — compare the cross-section width at 10 % and 90 %
       along the principal axis. Anterior = narrower end.
    6. Centre the mesh on the origin and write the aligned STL.
    7. Compute pour-channel coordinates (bs_tip / bs_entry) for BOTH
       extremities of the brain and print them in the report — the user
       picks the right pair visually in OpenSCAD (sphere on the brainstem
       = correct option).
    8. Print a text report summarising every step.

Usage:
    python align_stl.py brain.stl                  # writes brain_aligned.stl
    python align_stl.py brain.stl -o out.stl       # custom output name
    python align_stl.py brain.stl --report         # diagnostic only, no file
    python align_stl.py brain.stl --flip-ap        # reverse anterior/posterior
    python align_stl.py brain.stl --flip-dv        # reverse dorsal/ventral

Dependencies:
    pip install trimesh numpy

Author: Philippe Zizzari — REMPLACER outreach workshop, INSERM U1215, 2026
License: CC BY-NC-SA 4.0 (see LICENSE in the repository root)
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
import trimesh


# ---------------------------------------------------------------------------
# Geometry helpers
# ---------------------------------------------------------------------------

def filter_outliers(vertices: np.ndarray, sigma: float = 3.0) -> np.ndarray:
    """Remove vertices that lie more than `sigma` standard deviations away
    from the centroid along any axis. Stray points (Slicer/Blender export
    artefacts) badly skew the PCA: a single distant vertex can dominate the
    principal axis and produce a wrong alignment.

    Returns the filtered vertex array."""
    centre = vertices.mean(axis=0)
    distances = np.linalg.norm(vertices - centre, axis=1)
    threshold = distances.mean() + sigma * distances.std()
    mask = distances <= threshold
    return vertices[mask]


def principal_axes(vertices: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """Return the principal axes (3x3, columns = axes) and their variances
    (descending). PCA on the centred vertex cloud, with outlier filtering
    so stray points (Slicer / Blender export artefacts) cannot dominate
    the principal axis."""
    cleaned = filter_outliers(vertices)
    centred = cleaned - cleaned.mean(axis=0)
    cov = np.cov(centred.T)
    eigvals, eigvecs = np.linalg.eigh(cov)  # ascending order
    # Reorder descending (axis 0 = longest)
    order = np.argsort(eigvals)[::-1]
    return eigvecs[:, order], eigvals[order]


def rotation_to_align(src_axes: np.ndarray) -> np.ndarray:
    """Build the rotation matrix that sends the source axes (columns) onto
    the REMPLACER target frame:
        principal (longest)     -> +Z
        middle                  -> +X
        minor (shortest)        -> +Y
    """
    target = np.array([
        [0, 0, 1],   # principal -> Z
        [1, 0, 0],   # middle    -> X
        [0, 1, 0],   # minor     -> Y
    ]).T             # columns = target axes in order [principal, middle, minor]
    # src_axes @ R^-1 = target  =>  R = target^-1 @ src_axes  =>  R = src_axes @ target^-1
    # Since target is orthonormal, target^-1 = target.T
    R = target @ src_axes.T
    # Ensure right-handedness (det = +1, not -1, which would be a mirror)
    if np.linalg.det(R) < 0:
        # Flip the minor axis (smallest impact on shape)
        R[:, 2] = -R[:, 2]
    return R


def detect_anterior_end(vertices: np.ndarray) -> int:
    """Return +1 if the anterior (olfactory bulbs) is on the +Z side,
    -1 if on the -Z side, by comparing cross-section widths at 10 % and 90 %
    along the Z axis. The narrower end is anterior.

    If the test is inconclusive (sizes within 10 % of each other), return 0.
    """
    z = vertices[:, 2]
    zmin, zmax = z.min(), z.max()
    length = zmax - zmin
    if length <= 0:
        return 0

    # Slabs of 10 % thickness near each end
    slab = 0.10 * length
    low_mask = (z >= zmin) & (z <= zmin + slab)
    high_mask = (z >= zmax - slab) & (z <= zmax)

    if low_mask.sum() < 10 or high_mask.sum() < 10:
        return 0

    # Width of each slab = bounding-box diagonal in the XY plane
    def slab_width(mask: np.ndarray) -> float:
        xy = vertices[mask, :2]
        ext = xy.max(axis=0) - xy.min(axis=0)
        return float(np.linalg.norm(ext))

    w_low = slab_width(low_mask)
    w_high = slab_width(high_mask)

    if abs(w_low - w_high) / max(w_low, w_high) < 0.10:
        return 0   # inconclusive
    return +1 if w_high < w_low else -1   # anterior = narrower end


def bbox_dimensions(vertices: np.ndarray) -> np.ndarray:
    return vertices.max(axis=0) - vertices.min(axis=0)


# ---------------------------------------------------------------------------
# Main pipeline
# ---------------------------------------------------------------------------

def align_mesh(
    mesh: trimesh.Trimesh,
    *,
    force_flip_ap: bool = False,
    force_flip_dv: bool = False,
) -> tuple[trimesh.Trimesh, dict]:
    """Return the aligned mesh and a diagnostic report dict."""

    report: dict = {}
    report["input_dimensions"] = bbox_dimensions(mesh.vertices).tolist()
    report["input_vertex_count"] = len(mesh.vertices)

    # --- 1. PCA on the vertices
    axes, variances = principal_axes(mesh.vertices)
    report["principal_variances"] = variances.tolist()
    report["principal_lengths"] = np.sqrt(variances).tolist()

    # --- 2. Build the alignment rotation
    R = rotation_to_align(axes)

    # --- 3. Apply: centre + rotate + RE-CENTRE
    # We centre and re-centre based on the FILTERED cloud (outliers excluded),
    # so stray vertices cannot shift the brain off-centre. But we still
    # rotate and export ALL vertices, otherwise the mesh would be punctured.
    clean_centre = filter_outliers(mesh.vertices).mean(axis=0)
    centred = mesh.vertices - clean_centre
    aligned = centred @ R.T
    clean_centre2 = filter_outliers(aligned).mean(axis=0)
    aligned = aligned - clean_centre2

    # --- 4. Detect anterior end (on the filtered cloud) and flip if needed
    ap_sign = detect_anterior_end(filter_outliers(aligned))
    report["anterior_detection"] = {
        +1: "narrower end at +Z (kept as-is)",
        -1: "narrower end at -Z (auto-flipped along Z)",
        0:  "inconclusive — anterior end unknown, no flip applied",
    }[ap_sign]
    if ap_sign == -1:
        # Anterior should be at +Z. Flip Z (and X to preserve handedness).
        aligned[:, 2] = -aligned[:, 2]
        aligned[:, 0] = -aligned[:, 0]

    # --- 5. User-forced flips (override auto-detection)
    if force_flip_ap:
        report["forced_flip_ap"] = True
        aligned[:, 2] = -aligned[:, 2]
        aligned[:, 0] = -aligned[:, 0]
    if force_flip_dv:
        report["forced_flip_dv"] = True
        aligned[:, 1] = -aligned[:, 1]
        aligned[:, 0] = -aligned[:, 0]

    # --- 5.5. Compute bs_tip and bs_entry candidates for BOTH extremities.
    # The auto-detection of which end is the brainstem (vs olfactory bulbs)
    # has only ~50% reliability on a given mesh, so we provide BOTH options
    # and let the user pick the right one visually in OpenSCAD.
    #
    # bs_tip is taken as the centroid of the bottom 1% of vertices along Z.
    # bs_entry extends bs_tip along the oblique caudal-ventral direction.
    aligned_clean = filter_outliers(aligned)
    z_extent = aligned_clean[:, 2].max() - aligned_clean[:, 2].min()

    # Option A: brainstem at -Z (the auto-detection's choice)
    z_low = np.percentile(aligned_clean[:, 2], 1)
    tip_A = aligned_clean[aligned_clean[:, 2] <= z_low].mean(axis=0)
    direction_A = np.array([0.1, -0.3, -1.0])
    direction_A = direction_A / np.linalg.norm(direction_A)
    entry_A = tip_A + direction_A * 0.7 * z_extent

    # Option B: brainstem at +Z (the opposite extremity)
    z_high = np.percentile(aligned_clean[:, 2], 99)
    tip_B = aligned_clean[aligned_clean[:, 2] >= z_high].mean(axis=0)
    direction_B = np.array([0.1, -0.3,  1.0])
    direction_B = direction_B / np.linalg.norm(direction_B)
    entry_B = tip_B + direction_B * 0.7 * z_extent

    report["bs_tip_option_A"]   = tip_A.tolist()
    report["bs_entry_option_A"] = entry_A.tolist()
    report["bs_tip_option_B"]   = tip_B.tolist()
    report["bs_entry_option_B"] = entry_B.tolist()

    # --- 6. Build the output mesh
    aligned_mesh = trimesh.Trimesh(
        vertices=aligned,
        faces=mesh.faces,
        process=False,
    )

    report["output_dimensions"] = bbox_dimensions(aligned).tolist()
    aligned_clean = filter_outliers(aligned)
    report["output_dimensions_clean"] = bbox_dimensions(aligned_clean).tolist()
    report["output_dimensions_labelled"] = {
        "X (medio-lateral)":    float(aligned_clean[:, 0].max() - aligned_clean[:, 0].min()),
        "Y (dorso-ventral)":    float(aligned_clean[:, 1].max() - aligned_clean[:, 1].min()),
        "Z (antero-posterior)": float(aligned_clean[:, 2].max() - aligned_clean[:, 2].min()),
    }
    report["outliers_removed"] = int(len(aligned) - len(aligned_clean))

    return aligned_mesh, report


def print_report(report: dict, input_path: Path, output_path: Path | None) -> None:
    print()
    print("=" * 64)
    print("  align_stl.py — alignment report")
    print("=" * 64)
    print(f"  Input:  {input_path}")
    if output_path is not None:
        print(f"  Output: {output_path}")
    print(f"  Vertices: {report['input_vertex_count']}")
    print()
    print("  Input bounding box (X, Y, Z, in STL units):")
    dx, dy, dz = report["input_dimensions"]
    print(f"      {dx:8.2f}  {dy:8.2f}  {dz:8.2f}")
    print()
    print("  Principal-axis lengths (sqrt of variance, descending):")
    p, m, n = report["principal_lengths"]
    print(f"      principal {p:8.2f}    middle {m:8.2f}    minor {n:8.2f}")
    print()
    print("  Antero-posterior detection:")
    print(f"      {report['anterior_detection']}")
    if report.get("forced_flip_ap"):
        print("      USER: --flip-ap requested (additional flip applied)")
    if report.get("forced_flip_dv"):
        print("      USER: --flip-dv requested (additional flip applied)")
    print()
    print("  Output bounding box (after alignment, brain only — outliers excluded):")
    for label, value in report["output_dimensions_labelled"].items():
        print(f"      {label:24s} {value:8.2f}")
    if report["outliers_removed"] > 0:
        full = report["output_dimensions"]
        print(f"      ({report['outliers_removed']} stray vertices excluded; "
              f"full bbox incl. outliers: {full[0]:.1f} × {full[1]:.1f} × {full[2]:.1f})")
    print()
    print("  How to verify in OpenSCAD:")
    print("      1. In mold_brainstem_pour.scad, set:")
    print("           model_filename = \"<this output STL>\";")
    print("           show_brain_debug = true;")
    print("      2. Press F5. The brain should appear with:")
    print("           - olfactory bulbs at +Z (top of the screen)")
    print("           - cerebellum / brainstem at -Z (bottom)")
    print("           - dorsal surface at +Y, ventral at -Y")
    print("      3. If the anterior/posterior is reversed, rerun with --flip-ap")
    print("         If the dorsal/ventral is reversed, rerun with --flip-dv")
    print()
    print("  Pour-channel coordinates (paste ONE of the two options into the .scad):")
    print()
    print("    Option A — brainstem at -Z end of the brain:")
    tA, eA = report["bs_tip_option_A"], report["bs_entry_option_A"]
    print(f"        bs_tip   = [ {tA[0]:6.2f}, {tA[1]:6.2f}, {tA[2]:6.2f} ];")
    print(f"        bs_entry = [ {eA[0]:6.2f}, {eA[1]:6.2f}, {eA[2]:6.2f} ];")
    print()
    print("    Option B — brainstem at +Z end of the brain:")
    tB, eB = report["bs_tip_option_B"], report["bs_entry_option_B"]
    print(f"        bs_tip   = [ {tB[0]:6.2f}, {tB[1]:6.2f}, {tB[2]:6.2f} ];")
    print(f"        bs_entry = [ {eB[0]:6.2f}, {eB[1]:6.2f}, {eB[2]:6.2f} ];")
    print()
    print("  Try Option A first. Open the .scad with show_brain_debug = true:")
    print("    - red sphere on the brainstem (cerebellum / ventral caudal end)? -> keep A")
    print("    - red sphere on the olfactory bulbs (anterior)? -> switch to B")
    print("  Fine-tune bs_tip / bs_entry manually if needed.")
    print("=" * 64)
    print()


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Align a mouse-brain STL into the REMPLACER mould convention "
            "(principal axis = Z, dorso-ventral = Y, medio-lateral = X)."
        ),
    )
    parser.add_argument("input", type=Path, help="Input STL file.")
    parser.add_argument(
        "-o", "--output", type=Path, default=None,
        help="Output STL filename (default: <input>_aligned.stl).",
    )
    parser.add_argument(
        "--report", action="store_true",
        help="Print the diagnostic report only, do not write any STL.",
    )
    parser.add_argument(
        "--flip-ap", action="store_true",
        help="Force a flip of the antero-posterior axis (override the "
             "auto-detection if it picked the wrong end).",
    )
    parser.add_argument(
        "--flip-dv", action="store_true",
        help="Force a flip of the dorso-ventral axis (rare; PCA cannot "
             "tell dorsal from ventral on its own).",
    )
    args = parser.parse_args(argv)

    if not args.input.is_file():
        print(f"error: input file not found: {args.input}", file=sys.stderr)
        return 2

    try:
        mesh = trimesh.load(args.input, force="mesh")
    except Exception as exc:
        print(f"error: could not load STL: {exc}", file=sys.stderr)
        return 2

    if not isinstance(mesh, trimesh.Trimesh) or len(mesh.vertices) == 0:
        print(f"error: {args.input} contains no triangle mesh.", file=sys.stderr)
        return 2

    aligned, report = align_mesh(
        mesh,
        force_flip_ap=args.flip_ap,
        force_flip_dv=args.flip_dv,
    )

    output_path: Path | None
    if args.report:
        output_path = None
    else:
        output_path = args.output or args.input.with_name(
            args.input.stem + "_aligned.stl"
        )
        aligned.export(output_path)

    print_report(report, args.input, output_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
