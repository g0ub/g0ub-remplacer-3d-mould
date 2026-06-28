# Crédits et attributions

Ce moule est un **travail dérivé** combinant plusieurs ressources ouvertes.
L'ensemble du dépôt est distribué sous licence **Creative Commons
Attribution – Pas d'Utilisation Commerciale – Partage dans les Mêmes
Conditions 4.0 International (CC BY-NC-SA 4.0)** — voir le fichier `LICENSE`.

Cette licence est imposée par le template de cerveau amont (NITRC tpm_mouse,
CC BY-NC-SA), dont la géométrie est dérivée : les clauses NC et SA se
propagent à l'ensemble de l'œuvre.

---

## 1. Modèle anatomique du cerveau

- **Fichier source** : `Template_C57Bl6_T2_n10_brain.nii`
- **Projet** : Templates for In vivo Mouse Brain (*tpm_mouse*), NITRC
- **URL** : https://www.nitrc.org/projects/tpm_mouse
- **Auteur / contact** : Keigo Hikishima (OIST)
- **Licence d'origine** : CC BY-NC-SA
- **Référence à citer** :
  > Hikishima K, Komaki Y, Seki F, Ohnishi Y, Okano HJ, Okano H.
  > *In vivo microscopic voxel-based morphometry with a brain template to
  > characterize strain-specific structures in the mouse brain.*
  > Sci Rep. 2017;7(1):85. doi:10.1038/s41598-017-00148-1. PMID: 28273899.
- **Étape réalisée** : conversion du fichier NIfTI (`.nii`) en maillage STL
  (pipeline via VTK), puis réorientation avec `scripts/align_stl.py`.
  Le STL résultant — inclus dans le dépôt à `/scad/mold_file.stl` — est
  un dérivé direct du template NITRC ; sa redistribution est autorisée par
  la licence CC BY-NC-SA d'origine, sous réserve du respect des clauses
  d'attribution (cf. citation ci-dessus), NC et SA.

---

## 2. Générateur de moule en deux parties (chaîne de dérivés)

### 2a. Auteur original
- **Script** : Parametric two-part mold generator for OpenSCAD
- **Auteur** : Jason Webb — https://jasonwebb.io
- **Source** : https://www.thingiverse.com/thing:31581 (publication d'origine, 2012)
- **Licence** : Creative Commons (voir la fiche Thingiverse d'origine) —
  dérivés autorisés et explicitement encouragés par l'auteur.

### 2b. Modification intermédiaire
- **Titre** : « Mold Generator - modified »
- **Auteur** : Dan Steele (*rocketboy* sur Thingiverse), 31 août 2014
- **Profil** : https://www.thingiverse.com/rocketboy
- **Source** : https://www.thingiverse.com/thing:447443
- **Licence d'origine** : CC BY (Creative Commons – Attribution)
- **Modifications** :
  - une clé de repérage transformée en cube, pour empêcher l'assemblage
    du moule à l'envers ;
  - trou de coulée optionnel.

### 2c. Adaptations REMPLACER (ce dépôt)
- **Auteur** : Philippe Zizzari — atelier REMPLACER,
  Neurocentre Magendie (INSERM U1215), 2026 — https://github.com/g0ub / https://g0ub.github.io/remplacer/
- **Modifications** :
  - import de la forme de cerveau (STL dérivé du template NITRC, cf. §1),
    positionnée et mise à l'échelle dans le moule ;
  - **canal de coulée OBLIQUE aligné sur le tronc cérébral** :
    - `module cone_between()` : cône conique le long d'un vecteur quelconque ;
    - canal défini dans le repère du STL (vise directement le tronc) ;
    - le canal débouche dans une seule moitié, par la face latérale du moule ;
  - ajout des textes **REMPLACER / REPLACE** et de leur transcription en
    **braille**.

---

## Licence de l'ensemble

Tous les fichiers de ce dépôt (STL dérivés du cerveau, source `.scad`,
textes et ajouts REMPLACER) sont publiés sous **CC BY-NC-SA 4.0**.
Toute réutilisation doit créditer l'ensemble de la chaîne ci-dessus,
rester non commerciale et conserver la même licence.
