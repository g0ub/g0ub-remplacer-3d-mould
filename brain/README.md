# `/brain/` — Anatomical model source & `.nii → STL` conversion / Source du modèle anatomique & conversion `.nii → STL`

**FR** | [EN below](#english-version)

---

## Version française

Ce dossier **ne contient pas** le fichier de cerveau d'origine : il explique
comment le récupérer à la source et reproduire la conversion en STL.
La licence du template (CC BY-NC-SA) autorise le re-hébergement, mais renvoyer
vers NITRC évite la duplication et garde l'attribution propre.

---

## ⚠️ Pièges courants (à lire en premier)

Trois bugs reviennent systématiquement quand on enchaîne Slicer → STL → OpenSCAD.
Ils font perdre du temps mais sont triviaux à éviter une fois connus.

1. **Toujours cliquer « Apply » dans Segment Editor avant l'export STL.**
   L'outil *Threshold* affiche un aperçu coloré séduisant, mais tant que
   tu n'as pas appuyé sur **Apply** en bas du panneau, le segment reste
   vide et l'export produit un STL vide.

2. **Cocher *Smoothing* + *Islands* dans Segment Editor avant l'export.**
   Sans ça, le STL contient souvent quelques vertices isolés (artéfacts de
   seuillage) qui peuvent perturber les outils en aval. Le script
   d'alignement les gère, mais autant les éviter dès la source.

3. **Fermer et rouvrir OpenSCAD à chaque fois qu'on modifie un STL externe.**
   OpenSCAD met les `import()` en cache et continue à utiliser l'ancienne
   version même si tu remplaces le fichier sur le disque. Si tu observes
   un comportement « impossible » (le moule semble correct alors que tu
   as cassé le STL exprès), c'est ça : ferme l'application et rouvre-la
   pour purger le cache.

---

## 1. Récupérer le template (NITRC)

> ℹ️ **Pour un usage rapide, c'est déjà fait.** Un STL du cerveau aligné est
> inclus dans le dépôt à [`/scad/mold_file.stl`](../scad/) et utilisé
> directement par le `.scad`. Les instructions ci-dessous décrivent comment
> **régénérer** ce STL depuis la source — utile pour un autre template, une
> autre espèce, ou pour adapter la résolution / le lissage du maillage.

- **Projet** : Templates for In vivo Mouse Brain (*tpm_mouse*)
- **URL** : https://www.nitrc.org/projects/tpm_mouse
- **Archive** : `C57Bl6.zip`
- **Fichier utilisé** : `Template_C57Bl6_T2_n10_brain.nii`
- **Licence** : CC BY-NC-SA — **citation obligatoire** :

  > Hikishima K, Komaki Y, Seki F, Ohnishi Y, Okano HJ, Okano H.
  > *In vivo microscopic voxel-based morphometry with a brain template to
  > characterize strain-specific structures in the mouse brain.*
  > Sci Rep. 2017;7(1):85. doi:10.1038/s41598-017-00148-1. PMID: 28273899.

> ⚠️ **Échelle** : sur ces templates, la taille des voxels a été
> **multipliée par 10** (pour un usage direct dans SPM). Le STL obtenu fait
> donc ~10× la taille réelle (~160 mm de long). C'est normal — la mise à
> l'échelle finale est gérée dans le `.scad` via le paramètre `model_scale`
> (≈ 0.10). Ne redimensionne pas le STL avant.

---

## 2. Convertir `.nii → STL` avec 3D Slicer (voie recommandée)

C'est la voie réellement utilisée pour ce moule. Tout se fait en interface
graphique, sans script.

1. **Charger le volume** — *File → Add Data…*, sélectionne
   `Template_C57Bl6_T2_n10_brain.nii`, *OK*.

2. **Créer un segment** — ouvre le module **Segment Editor**
   (*Modules → Segmentation → Segment Editor*). Clique **Add** pour créer un
   segment, donne-lui un nom (par ex. `brain`).

3. **Seuiller** — sélectionne l'outil **Threshold**. Glisse le curseur
   du seuil inférieur jusqu'à ce que **seule la surface du cerveau** soit
   colorée en aperçu (sans le crâne ni le bruit autour). Bascule en vue 3D
   pour vérifier. **Clique sur Apply** (cf. pièges courants §1).

4. **Lisser** *(recommandé)* — active l'outil **Smoothing**, méthode
   *Gaussian* ou *Median*, intensité modérée, *Apply*.

5. **Retirer les îlots flottants** *(recommandé)* — active l'outil
   **Islands**, opération *Keep largest island*, *Apply*. Cela élimine
   les vertices baladeurs qui sortiraient sinon dans le STL.

6. **Exporter en STL** — tout en bas du panneau Segment Editor, clique
   **Export to files…** :
   - *Destination folder* : choisis ton dossier
   - *File format* : **STL**
   - *Reference volume* : laisse par défaut
   - Coche le segment du cerveau dans la liste
   - **Export**

7. **Vérifier le STL** — ouvre-le dans PrusaSlicer, Cura ou MeshLab :
   - un seul objet (pas de bouts de crâne ou de bruit autour)
   - longueur ~160 mm (rappel : échelle ×10)
   - maillage étanche *(watertight)* — sinon, fais un *Repair* dans
     PrusaSlicer.

### Alternative : modèle intermédiaire

Si tu veux passer par un *Model node* exportable séparément (utile si tu
veux le manipuler avant l'export), tu peux d'abord convertir la
segmentation en modèle via *Segmentations → Export/import models and
labelmaps → Operation: Export, Output type: Models, Output node: Create
new model*. Slicer écrit le modèle d'abord en `.vtk` (son format natif) ;
tu peux ensuite le ré-ouvrir et le ré-exporter en STL (voir §4).

---

## 3. Aligner le STL pour le `.scad` (script Python)

Le `.scad` attend le cerveau dans une orientation précise (axe principal sur Z,
dorso-ventral sur Y, médio-latéral sur X). Selon ta version de Slicer et la
convention NIfTI du template, ton STL peut sortir orienté différemment — et
alors le moule **se forme vide ou bizarre**. Le script `scripts/align_stl.py`
analyse le STL et le réoriente automatiquement.

### Quand l'utiliser
Toujours, par sécurité. Coût : 2 secondes d'exécution, et tu as la garantie
que le moule sera bien formé. Si tu sais que ton STL est déjà dans la bonne
convention (par exemple parce que tu repars d'un export précédent qui
marchait), tu peux sauter cette étape.

### Installation
```
pip install trimesh numpy
```
(une seule fois, dépendances légères)

### Usage
```
python scripts/align_stl.py brain.stl
```
Le script écrit `brain_aligned.stl` à côté du STL d'entrée et affiche un
rapport détaillé. **Garde ce rapport sous les yeux**, il contient les
coordonnées à coller dans le `.scad` pour le canal de coulée.

### Options
- `--flip-ap` : force le retournement antéro-postérieur (à utiliser si
  l'auto-détection se trompe, c'est-à-dire si les bulbes olfactifs se
  retrouvent côté tronc dans le moule)
- `--flip-dv` : force le retournement dorso-ventral (rare ; la PCA ne
  peut pas distinguer dorsal et ventral toute seule)
- `--report` : génère juste le rapport sans écrire de fichier
- `-o sortie.stl` : choisir le nom du STL de sortie

### Brancher le STL aligné dans le `.scad`
1. Renomme `brain_aligned.stl` en `mold_file.stl` (ou modifie
   `model_filename` dans le `.scad`).
2. **Ferme et rouvre OpenSCAD** (cf. pièges courants §3).
3. Le rapport du script propose **deux options** pour les coordonnées
   du canal de coulée (`bs_tip` / `bs_entry`), parce que l'orientation
   antéro/postérieure peut tomber dans un sens ou dans l'autre. Copie
   d'abord l'**Option A** dans le `.scad` :
   ```scad
   bs_tip   = [ ..., ..., ... ];
   bs_entry = [ ..., ..., ... ];
   ```
4. Mets `show_brain_debug = true;` dans le `.scad` et fais F5.
5. Vérification visuelle :
   - **sphère rouge sur le tronc cérébral** (cervelet ventral) → garde l'Option A ✓
   - **sphère rouge sur les bulbes olfactifs** → remplace par l'Option B, F5
6. Repasse `show_brain_debug = false;` et vérifie que le moule se forme
   correctement avec le canal de coulée à l'endroit attendu.

Pour un réglage très fin de la position du canal, tu peux éditer
`bs_tip` / `bs_entry` à la main : les sphères rouge (`bs_tip`) et bleue
(`bs_entry`) se déplacent dans la vue debug et tu vois en direct où elles
tombent par rapport au tronc.

### Cas particulier : STL avec plusieurs objets
Le script attend **un seul cerveau** dans le STL. Si ton STL contient
plusieurs objets (cerveau + restes de crâne, deux cerveaux superposés
après une manipulation Blender, etc.), nettoie-le d'abord dans PrusaSlicer
(*clic droit → Split → To objects*, supprimer ce qui n'est pas le cerveau,
*Export STL*).

---

## 4. Convertir `.nii → STL` en Python avec VTK (option scriptée)

Pour automatiser ou reproduire le pipeline dans un script, voici
l'équivalent du seuillage + extraction d'isosurface fait par Slicer :

```python
# pip install vtk
import vtk

IN_FILE  = "Template_C57Bl6_T2_n10_brain.nii"
OUT_FILE = "brain.stl"
ISO      = 0.5          # seuil — à régler (voir ci-dessous)

# 1. Lecture du NIfTI
reader = vtk.vtkNIFTIImageReader()
reader.SetFileName(IN_FILE)
reader.Update()

# 2. (option) léger lissage du volume avant l'extraction
gauss = vtk.vtkImageGaussianSmooth()
gauss.SetInputConnection(reader.GetOutputPort())
gauss.SetStandardDeviations(1.0, 1.0, 1.0)
gauss.Update()

# 3. Isosurface (marching cubes / flying edges)
mc = vtk.vtkFlyingEdges3D()
mc.SetInputConnection(gauss.GetOutputPort())
mc.SetValue(0, ISO)
mc.Update()

# 4. Garder uniquement la plus grande région connexe (enlève le bruit)
conn = vtk.vtkPolyDataConnectivityFilter()
conn.SetInputConnection(mc.GetOutputPort())
conn.SetExtractionModeToLargestRegion()
conn.Update()

# 5. Lissage + allègement du maillage pour l'impression
smooth = vtk.vtkWindowedSincPolyDataFilter()
smooth.SetInputConnection(conn.GetOutputPort())
smooth.SetNumberOfIterations(20)
smooth.BoundarySmoothingOff()
smooth.NonManifoldSmoothingOn()
smooth.NormalizeCoordinatesOn()
smooth.Update()

deci = vtk.vtkDecimatePro()
deci.SetInputConnection(smooth.GetOutputPort())
deci.SetTargetReduction(0.5)   # ~50 % de triangles en moins
deci.PreserveTopologyOn()
deci.Update()

# 6. Écriture STL (binaire)
writer = vtk.vtkSTLWriter()
writer.SetFileName(OUT_FILE)
writer.SetInputConnection(deci.GetOutputPort())
writer.SetFileTypeToBinary()
writer.Write()
print("written:", OUT_FILE)
```

### Régler le seuil `ISO`
La valeur dépend de l'intensité du volume. Le plus simple est de la
trouver visuellement **dans 3D Slicer** avec l'outil *Threshold* (la
valeur basse du curseur, quand seule la surface du cerveau est isolée),
puis de la reporter dans le script.

Le STL produit par ce script Python doit ensuite passer par
`scripts/align_stl.py` (§3), comme un STL Slicer.

---

## 5. Convertir un `.vtk` existant en `.stl`

Si tu as exporté depuis 3D Slicer en `.vtk` (format natif de Slicer) et
que tu veux passer en `.stl`, trois options :

- **Le plus simple** : ré-ouvrir le `.vtk` dans Slicer (*File → Add
  Data…*), puis l'exporter en STL via la même procédure qu'au §2
  (clic droit *Export to file…* sur le modèle, ou *File → Save Data…* en
  choisissant **STL** dans la colonne *File Format*).
- **Sans Slicer** : *File → Import Mesh* dans **MeshLab**, puis
  *File → Export Mesh As… → STL*.
- **En script Python avec VTK** :

  ```python
  import vtk
  reader = vtk.vtkPolyDataReader()       # ou vtkXMLPolyDataReader() pour .vtp
  reader.SetFileName("brain.vtk")
  reader.Update()
  writer = vtk.vtkSTLWriter()
  writer.SetFileName("brain.stl")
  writer.SetInputConnection(reader.GetOutputPort())
  writer.SetFileTypeToBinary()
  writer.Write()
  ```

  Le format VTK existe en deux variantes — *legacy* (`.vtk`,
  `vtkPolyDataReader`) et *XML* (`.vtp`, `vtkXMLPolyDataReader`).
  Ouvre le fichier avec un éditeur de texte pour t'en assurer : le legacy
  commence par `# vtk DataFile Version`.

---

## English version

This folder **does not contain** the original brain file: it explains how to
fetch it from the source and reproduce the STL conversion. The template's
licence (CC BY-NC-SA) allows re-hosting, but pointing back to NITRC avoids
duplication and keeps attribution clean.

---

## ⚠️ Common pitfalls (read first)

Three bugs come up systematically along the Slicer → STL → OpenSCAD pipeline.
They waste time but are trivial to avoid once known.

1. **Always click "Apply" in Segment Editor before exporting the STL.**
   The *Threshold* tool shows a tempting coloured preview, but until you
   press **Apply** at the bottom of the panel, the segment stays empty and
   the export produces an empty STL.

2. **Tick *Smoothing* + *Islands* in Segment Editor before exporting.**
   Without these, the STL often contains a few stray vertices (thresholding
   artefacts) that can confuse downstream tools. The alignment script handles
   them, but it's better to avoid them at the source.

3. **Close and reopen OpenSCAD every time you modify an external STL.**
   OpenSCAD caches `import()` and keeps using the old version even when
   you replace the file on disk. If you see "impossible" behaviour (the mould
   looks correct even though you deliberately broke the STL), this is why:
   close the app and reopen it to flush the cache.

---

## 1. Fetch the template (NITRC)

> ℹ️ **For a quick start, this is already done.** An aligned brain STL is
> bundled in the repository at [`/scad/mold_file.stl`](../scad/) and used
> directly by the `.scad`. The instructions below describe how to
> **regenerate** that STL from source — useful for a different template,
> a different species, or to tune the mesh resolution / smoothing.

- **Project**: Templates for In vivo Mouse Brain (*tpm_mouse*)
- **URL**: https://www.nitrc.org/projects/tpm_mouse
- **Archive**: `C57Bl6.zip`
- **File used**: `Template_C57Bl6_T2_n10_brain.nii`
- **Licence**: CC BY-NC-SA — **citation required**:

  > Hikishima K, Komaki Y, Seki F, Ohnishi Y, Okano HJ, Okano H.
  > *In vivo microscopic voxel-based morphometry with a brain template to
  > characterize strain-specific structures in the mouse brain.*
  > Sci Rep. 2017;7(1):85. doi:10.1038/s41598-017-00148-1. PMID: 28273899.

> ⚠️ **Scale**: on these templates, the voxel size has been **multiplied by 10**
> (for direct use in SPM). The resulting STL is therefore ~10× life size
> (~160 mm long). That's expected — final scaling is handled inside the
> `.scad` via the `model_scale` parameter (≈ 0.10). Don't resize the STL
> beforehand.

---

## 2. Convert `.nii → STL` with 3D Slicer (recommended path)

This is the path actually used for this mould. Everything happens in the
graphical interface, no scripting needed.

1. **Load the volume** — *File → Add Data…*, select
   `Template_C57Bl6_T2_n10_brain.nii`, *OK*.

2. **Create a segment** — open the **Segment Editor** module
   (*Modules → Segmentation → Segment Editor*). Click **Add** to create a
   segment, name it (e.g. `brain`).

3. **Threshold** — select the **Threshold** tool. Slide the lower threshold
   until **only the surface of the brain** is highlighted in the preview
   (no skull or noise around). Switch to 3D view to confirm. **Click Apply**
   (see common pitfalls §1).

4. **Smooth** *(recommended)* — activate the **Smoothing** tool, method
   *Gaussian* or *Median*, moderate intensity, *Apply*.

5. **Remove floating islands** *(recommended)* — activate the **Islands**
   tool, operation *Keep largest island*, *Apply*. This eliminates the stray
   vertices that would otherwise show up in the STL.

6. **Export as STL** — at the bottom of the Segment Editor panel, click
   **Export to files…**:
   - *Destination folder*: choose your folder
   - *File format*: **STL**
   - *Reference volume*: leave default
   - Tick the brain segment in the list
   - **Export**

7. **Sanity-check the STL** — open it in PrusaSlicer, Cura or MeshLab:
   - a single object (no skull fragments or noise around)
   - length ~160 mm (remember: ×10 scale)
   - watertight mesh — if not, use *Repair* in PrusaSlicer.

### Alternative: via an intermediate model

If you want to go through a separately exportable *Model node* (useful for
manipulating the model before export), you can first convert the segmentation
to a model via *Segmentations → Export/import models and labelmaps →
Operation: Export, Output type: Models, Output node: Create new model*.
Slicer first writes the model as `.vtk` (its native format); you can then
reopen and re-export it as STL (see §4).

---

## 3. Align the STL for the `.scad` (Python script)

The `.scad` expects the brain in a specific orientation (principal axis on Z,
dorso-ventral on Y, medio-lateral on X). Depending on your Slicer version and
on the NIfTI template's convention, your STL may come out oriented differently
— and then the mould **prints empty or weird**. The `scripts/align_stl.py`
script analyses the STL and re-orients it automatically.

### When to use it
Always, for safety. Cost: a 2-second run, and you have the guarantee the mould
will be properly formed. If you know your STL is already in the right
convention (because you reused a previous working export, for example), you
can skip this step.

### Install
```
pip install trimesh numpy
```
(one time only, lightweight dependencies)

### Usage
```
python scripts/align_stl.py brain.stl
```
The script writes `brain_aligned.stl` next to the input STL and prints a
detailed report. **Keep this report at hand**, it contains the coordinates
you need to paste into the `.scad` for the pour channel.

### Options
- `--flip-ap`: force an antero-posterior flip (use this if the auto-detection
  gets it wrong, i.e. if the olfactory bulbs end up on the brainstem side
  in the mould)
- `--flip-dv`: force a dorso-ventral flip (rare; PCA cannot tell dorsal
  from ventral on its own)
- `--report`: print only the diagnostic report, do not write any file
- `-o output.stl`: choose the output STL filename

### Plug the aligned STL into the `.scad`
1. Rename `brain_aligned.stl` to `mold_file.stl` (or change `model_filename`
   in the `.scad`).
2. **Close and reopen OpenSCAD** (see common pitfalls §3).
3. The script's report proposes **two options** for the pour-channel
   coordinates (`bs_tip` / `bs_entry`), because the antero-posterior
   orientation may fall either way. Paste **Option A** into the `.scad`
   first:
   ```scad
   bs_tip   = [ ..., ..., ... ];
   bs_entry = [ ..., ..., ... ];
   ```
4. Set `show_brain_debug = true;` in the `.scad` and press F5.
5. Visual check:
   - **red sphere on the brainstem** (ventral cerebellum) → keep Option A ✓
   - **red sphere on the olfactory bulbs** → replace with Option B, F5
6. Set `show_brain_debug = false;` again and check the mould forms correctly
   with the pour channel where expected.

For fine-tuning the channel position, you can edit `bs_tip` / `bs_entry`
by hand: the red sphere (`bs_tip`) and blue sphere (`bs_entry`) move in
the debug view so you see live where they land on the brainstem.

### Special case: STL with several objects
The script expects **a single brain** in the STL. If your STL contains
multiple objects (brain + skull fragments, two overlapping brains after
some Blender manipulation, etc.), clean it first in PrusaSlicer (*right-click
→ Split → To objects*, delete what is not the brain, *Export STL*).

---

## 4. Convert `.nii → STL` in Python with VTK (scripted option)

To automate the pipeline in a script, here is the Python equivalent of the
thresholding + isosurface extraction that Slicer does:

```python
# pip install vtk
import vtk

IN_FILE  = "Template_C57Bl6_T2_n10_brain.nii"
OUT_FILE = "brain.stl"
ISO      = 0.5          # threshold — tune (see below)

# 1. Read the NIfTI
reader = vtk.vtkNIFTIImageReader()
reader.SetFileName(IN_FILE)
reader.Update()

# 2. (optional) light volume smoothing before extraction
gauss = vtk.vtkImageGaussianSmooth()
gauss.SetInputConnection(reader.GetOutputPort())
gauss.SetStandardDeviations(1.0, 1.0, 1.0)
gauss.Update()

# 3. Isosurface (marching cubes / flying edges)
mc = vtk.vtkFlyingEdges3D()
mc.SetInputConnection(gauss.GetOutputPort())
mc.SetValue(0, ISO)
mc.Update()

# 4. Keep only the largest connected region (removes noise)
conn = vtk.vtkPolyDataConnectivityFilter()
conn.SetInputConnection(mc.GetOutputPort())
conn.SetExtractionModeToLargestRegion()
conn.Update()

# 5. Smoothing + mesh simplification for printing
smooth = vtk.vtkWindowedSincPolyDataFilter()
smooth.SetInputConnection(conn.GetOutputPort())
smooth.SetNumberOfIterations(20)
smooth.BoundarySmoothingOff()
smooth.NonManifoldSmoothingOn()
smooth.NormalizeCoordinatesOn()
smooth.Update()

deci = vtk.vtkDecimatePro()
deci.SetInputConnection(smooth.GetOutputPort())
deci.SetTargetReduction(0.5)   # ~50 % fewer triangles
deci.PreserveTopologyOn()
deci.Update()

# 6. Write STL (binary)
writer = vtk.vtkSTLWriter()
writer.SetFileName(OUT_FILE)
writer.SetInputConnection(deci.GetOutputPort())
writer.SetFileTypeToBinary()
writer.Write()
print("written:", OUT_FILE)
```

### Tuning the `ISO` threshold
The value depends on the volume's intensity. The easiest is to find it
visually **in 3D Slicer** with the *Threshold* tool (the lower value of the
slider when only the brain surface is isolated), then transfer it to the
script.

The STL produced by this Python script must then go through
`scripts/align_stl.py` (§3), like any Slicer STL.

---

## 5. Convert an existing `.vtk` to `.stl`

If you exported from 3D Slicer in `.vtk` (Slicer's native format) and want
to switch to `.stl`, three options:

- **The easiest**: re-open the `.vtk` in Slicer (*File → Add Data…*), then
  export to STL via the same procedure as §2 (right-click *Export to file…*
  on the model, or *File → Save Data…* selecting **STL** in the *File Format*
  column).
- **Without Slicer**: *File → Import Mesh* in **MeshLab**, then
  *File → Export Mesh As… → STL*.
- **In a Python script with VTK**:

  ```python
  import vtk
  reader = vtk.vtkPolyDataReader()       # or vtkXMLPolyDataReader() for .vtp
  reader.SetFileName("brain.vtk")
  reader.Update()
  writer = vtk.vtkSTLWriter()
  writer.SetFileName("brain.stl")
  writer.SetInputConnection(reader.GetOutputPort())
  writer.SetFileTypeToBinary()
  writer.Write()
  ```

  The VTK format exists in two flavours — *legacy* (`.vtk`,
  `vtkPolyDataReader`) and *XML* (`.vtp`, `vtkXMLPolyDataReader`).
  Open the file in a text editor to check: the legacy variant starts with
  `# vtk DataFile Version`.
