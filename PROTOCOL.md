# PROTOCOL — Cerveaux de souris en agarose / Agarose mouse-brain casting

**FR** | [EN below](#english-version)

> Les valeurs ci-dessous (concentration, temps de prise) sont des **points de
> départ** issus de la pratique de l'atelier REMPLACER. Ajustez-les à votre
> agarose, votre volume de moule et votre température ambiante.

---

## Version française

### Matériel
- Les deux moitiés du moule imprimées (`/stl/`)
- Agarose en poudre + eau distillée
- Récipient + chauffage (micro-ondes ou plaque chauffante)
- Ruban adhésif résistant (type scotch de bureau)
- Réfrigérateur (4 °C)

### Impression du moule
- Matériau : **PLA**
- Résolution : **0,2 mm** recommandée
- Remplissage : 15–20 % suffisent (les parois portent la forme)
- Orientation : face arrière (avec le texte REMPLACER/REPLACE) **sur le plateau**

#### Supports & blocker de support (PrusaSlicer)
Le moule a deux zones qui réclament des supports, et **une zone où il faut empêcher** le slicer d'en mettre :

- **Supports nécessaires** sur le **canal de coulée** (cône oblique, en surplomb) et sur le **braille en relief** (chaque point est un dôme sur une face verticale). Sans supports, ces zones impriment mal.
- **Bloqueur de support obligatoire** à l'intérieur de la **cuvette du cerveau** : par défaut, PrusaSlicer y détecte une instabilité et propose d'ajouter des supports, mais ceux-ci seraient piégés à l'intérieur du moule et abîmeraient l'empreinte au retrait. Place un *Support Blocker* qui recouvre toute la cuvette (clic droit sur l'objet → *Add modifier → Support Blocker → Box*, redimensionner pour couvrir la cuvette).

Avec ces réglages, le slicer met les supports uniquement là où il faut, et la cuvette reste lisse et propre.

### Préparation de l'agarose (1 à 2 %)
1. Peser **1 à 2 g d'agarose pour 100 mL** d'eau distillée (1 % donne plus de translucidité, 2 % plus de tenue).
2. Chauffer en remuant jusqu'à dissolution **complète et limpide** (proche de
   l'ébullition, sans déborder). La solution doit être parfaitement claire.

> **Pourquoi pas de colorant ?** Les colorants alimentaires et autres
> colorants histologiques classiques (éosine, etc.) diffusent au cours du
> temps : ils s'échappent du gel quand on conserve les cerveaux dans l'eau,
> et l'agarose redevient incolore. C'est aussi ce qui se passe à l'intérieur
> d'un cerveau en agarose quand on l'utilise pour visualiser une injection
> stéréotaxique au colorant alimentaire : le colorant diffuse du site
> d'injection vers tout le volume. Pour ce dernier usage, **l'encre de Chine**
> fonctionne mieux : les particules de carbone restent piégées dans le
> maillage de polysaccharides et permettent de visualiser de façon durable
> le site d'injection.

### Fermeture et coulée
1. Assembler les deux moitiés (les détrompeurs — clé cube — garantissent le
   bon sens).
2. **Sceller** : poser du ruban adhésif sur la tranche pour solidariser les
   deux parties, puis ajouter des bandes **à 90°** pour assurer l'étanchéité.
3. **Couler l'agarose encore chaud** par le trou de coulée, jusqu'à
   remplissage complet ; tapoter doucement pour chasser les bulles.

### Prise et démoulage
1. Laisser polymériser **~15 min à température ambiante**.
2. Puis **≥ 20 min à 4 °C** (le froid raffermit le gel et facilite le
   démoulage) — *à ajuster selon vos conditions*.
3. **Bien attendre** la polymérisation complète avant d'ouvrir le moule —
   c'est l'étape la plus importante pour réussir le démoulage. À 1 % d'agarose,
   le gel est très translucide mais aussi très fragile : ne pas précipiter.
4. Retirer le ruban, ouvrir délicatement les deux moitiés, démouler le cerveau.

### Conseils
- Un agarose mal dissous donne un gel trouble et fragile : insistez sur l'étape
  de chauffage.
- Bulles : couler lentement, mouler tiède, tapoter.
- Démoulage difficile : prolonger le passage à 4 °C, ou augmenter légèrement la
  concentration d'agarose pour un gel plus ferme.
- Le modèle peut être utilisé avec un **cadre stéréotaxique standard** pour
  les démonstrations.
- Conservation : **immergé dans l'eau du robinet** dans un contenant fermé.
  Le gel se dessèche à l'air libre. Pas besoin de réfrigérateur, mais
  **changer l'eau régulièrement** (toutes les 1 à 2 semaines) — sans ça,
  des algues peuvent se développer. Si ça arrive, un lavage des cerveaux à
  l'eau javellisée diluée permet souvent de les récupérer.

---

## English version

### Materials
- Both printed mould halves (`/stl/`)
- Agarose powder + distilled water
- Container + heat source (microwave or hot plate)
- Strong tape (office tape)
- Refrigerator (4 °C)

### Printing the mould
- Material: **PLA**
- Resolution: **0.2 mm** recommended
- Infill: 15–20 % is enough (the walls carry the shape)
- Orientation: back face (with the REMPLACER/REPLACE text) **on the bed**

#### Supports & support blocker (PrusaSlicer)
The mould has two areas that need supports, and **one area where you must prevent** the slicer from adding them:

- **Supports needed** on the **pour channel** (oblique cone, overhang) and on the **braille in relief** (each dot is a dome on a vertical face). Without supports these areas print badly.
- **Mandatory support blocker** inside the **brain cavity**: PrusaSlicer flags it as unstable and proposes to add supports, but they would be trapped inside the mould and would damage the imprint on removal. Place a *Support Blocker* covering the whole cavity (right-click the object → *Add modifier → Support Blocker → Box*, resize it to cover the cavity).

With these settings, the slicer adds supports only where they belong, and the cavity prints smooth and clean.

### Preparing the agarose (1 to 2 %)
1. Weigh **1 to 2 g agarose per 100 mL** distilled water (1 % gives more translucency, 2 % holds its shape better).
2. Heat while stirring until **fully and clearly dissolved** (near boiling,
   without boiling over). The solution must be perfectly clear.

> **Why no dye?** Food dyes and classical histological dyes (eosin, etc.)
> diffuse out over time: they leach from the gel when the brains are stored
> in water, and the agarose turns clear again. The same thing happens *inside*
> an agarose brain used to visualise stereotaxic injections with food dye:
> the dye diffuses from the injection site to the whole volume. For that
> purpose, **India ink** works much better: the carbon particles get trapped
> in the polysaccharide mesh and provide a durable visualisation of the
> injection site.

### Closing and pouring
1. Assemble both halves (the cube key prevents assembling them backwards).
2. **Seal**: tape along the seam to hold the halves together, then add strips
   **at 90°** to make it watertight.
3. **Pour the agarose while still hot** through the pour hole until full; tap
   gently to release bubbles.

### Setting and demoulding
1. Let it set for **~15 min at room temperature**.
2. Then **≥ 20 min at 4 °C** (chilling firms the gel and eases demoulding) —
   *adjust to your conditions*.
3. **Really wait** for full polymerization before opening the mould — this is
   the most important step for a successful demoulding. At 1 % agarose, the gel
   is very translucent but also very fragile: do not rush it.
4. Remove the tape, gently open the halves, demould the brain.

### Tips
- Poorly dissolved agarose gives a cloudy, fragile gel: don't rush the heating
  step.
- Bubbles: pour slowly, cast warm, tap the mould.
- Hard to demould: extend the 4 °C step, or slightly raise the agarose
  concentration for a firmer gel.
- The model can be used with a **standard stereotaxic frame** for demonstrations.
- Storage: **immersed in tap water** in a closed container. The gel dries
  out in open air. No need to refrigerate, but **change the water regularly**
  (every 1 to 2 weeks) — otherwise algae can grow. If that happens, washing
  the brains in dilute bleach water often saves them.
