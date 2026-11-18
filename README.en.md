<div align="center">

<img src="docs/img/portada.jpg" alt="The game's title screen: the Miskatonic University library by candlelight, with the great window and Cthulhu's silhouette in the storm" width="100%">

# Lovecraft Library: Surviving Cthulhu

**An isometric 3D voxel bullet hell with auto-fire and *survivors*-style progression, for 1 to 4 players in local and online co-op, set in H. P. Lovecraft's mythos.**

[![Godot 4.4](https://img.shields.io/badge/Godot-4.4.1-478CBF?logo=godotengine&logoColor=white)](https://godotengine.org/)
![GDScript](https://img.shields.io/badge/GDScript-statically%20typed-355570)
![Windows](https://img.shields.io/badge/Windows-x86__64-0078D6?logo=windows&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-universal-000000?logo=apple&logoColor=white)
![Players](https://img.shields.io/badge/players-1%E2%80%934%20local%20%26%20online-8e44ad)
![Languages](https://img.shields.io/badge/languages-English%20%C2%B7%20Spanish-c0392b)
![Tests](https://img.shields.io/badge/tests-GUT%20%C2%B7%201095%20passing-2e7d32)
![Version](https://img.shields.io/badge/version-0.9.0-e0a100)
[![License: code GPLv3, assets reserved](https://img.shields.io/badge/license-code%20GPLv3%20%C2%B7%20assets%20reserved-blue)](LICENCIA.md)

[Español](README.md) · **English**

[Features](#features) · [Screenshots](#screenshots) · [Campaign](#the-campaign) · [Characters](#characters) · [Weapons](#weapons-and-items) · [Bestiary](#bestiary) · [Installation](#installation-and-running) · [Development](#for-developers) · [Roadmap](#roadmap)

</div>

> *"The most merciful thing in the world, I think, is the inability of the human mind to correlate all its contents."*
> — H. P. Lovecraft, *The Call of Cthulhu*

In the Library of Miskatonic University, a handful of investigators have begun to correlate them. From Antarctica to Innsmouth, from Innsmouth to R'lyeh and from R'lyeh to the Dreamlands, something very old is waking up.

**Lovecraft Library** follows four of Lovecraft's stories (*At the Mountains of Madness*, *The Shadow over Innsmouth*, *The Call of Cthulhu* and *The Dream-Quest of Unknown Kadath*) across twenty levels and four colossal bosses, plus four more stories as standalone nights. Your weapons fire on their own: the skill lies in **moving and dodging** through hordes and curtains of bullets that drain your **health** or your **sanity**. When sanity hits zero, madness follows.

<div align="center">

<img src="docs/img/partida.gif" alt="A four-player game in the streets of Innsmouth, in the rain, among hybrids, acolytes and tiara priests" width="100%">

| 20 + 4 | 4 + 4 | 21 | 58 + 116 | 58 | 16 | 90+ | 1–4 |
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| levels and standalone nights | campaign and night bosses | investigators | weapons and their evolutions | items | companions | creatures | players, local or networked |

</div>

> [!NOTE]
> **Version 0.9.0, in development.** The full campaign can be played from start to finish: all four parts and the four standalone nights, solo, in local co-op or over the network, in English or Spanish. Still to come: part 4's own music, the online test between different homes, final balancing with real players, the itch.io release and switching on cloud saves, which are already built. The detailed status is in the [roadmap](#roadmap).

> [!IMPORTANT]
> **The game is currently in Spanish only.** The names of characters, weapons, items and creatures on this page are translated; the screenshots show them as they appear in the game.

## Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [The campaign](#the-campaign)
- [Characters](#characters)
- [Companions](#companions)
- [Weapons and items](#weapons-and-items)
- [Bestiary](#bestiary)
- [How to play](#how-to-play)
- [Installation and running](#installation-and-running)
- [Playing online](#playing-online)
- [For developers](#for-developers)
- [Roadmap](#roadmap)
- [Rights and credits](#rights-and-credits)
- [License](#license)

## Features

### Gameplay

- **Bullet hell with *survivors* progression:** hordes that pour in from off-screen, bullet patterns telegraphed on the ground and weapons that fire on their own. Each level lasts about five minutes and ends with a final event: a unique being, a horde to survive or one of the four bosses.
- **Health and sanity:** physical attacks (red, orange and yellow) take health; mental attacks (purple and lilac) take sanity; mixed ones take both. Being near the horrors wears the mind down too.
- **Madness crises:** at zero sanity, the investigator suffers one of five crises (paralysis, hysterical flight, aimless wandering, delirium with inverted controls, or paranoia), with a purple aura and a panicked face. Coming out of a crisis, you pick a **revelation** that lasts for the rest of the level.
- **58 weapons with two evolutions each:** firearms, physical and magic, four at once (six with the holsters from the shop). Each one levels from 1 to 5 and, at max level and with its paired item, the next arcane chest lets you choose between its two evolutions. Magic weapons cost sanity, and weapons from different players (or your own) **combine** when they meet.
- **58 items** that bend the rules: projectiles, range, criticals, double dodges, shields, decoys, resurrection…
- **21 investigators** with seven attributes, a starting weapon, a trait of their own and their own dodge style (slide, roll, dive, jump, flash, Pickman's painting, Gilman's angles…), an oil portrait and a victory pose. Two are secret. Pairs who know each other in the stories share **bonds**: a small bonus while they stay close.
- **16 companions** that bite, heal, steal, swallow bullets or teleport, and learn two tricks at level 5.
- **Living levels:** snowfall, blizzards, fog, rain and thunderstorms; water that slows you down, waves that sweep the deck, devouring Angles that swallow whoever stays inside, arcane chests and breakable scenery; birds, bats and critters that react to the battle.
- **More than surviving:** elites with traits, mid-level bosses, Necronomicon pacts, Elder Signs, mid-level objectives, events in the night (blood moon, fog, tide…), a peddler and loose diary pages.
- **Difficulty from 1 to 10**, adjustable game speed and, after beating Cthulhu, five **degrees of madness** that make the campaign harder one after another.

### Co-op, local and online

- **1 to 4 players** with gamepad or keyboard on the same PC, over the network between several PCs, or a mix of both (for example, two on the couch and two more, each in their own home).
- Shared camera, **shared experience** and **turn-based** level-ups: one player levels up at a time, in a window of their colour.
- Fallen players stay down for a few seconds and a teammate can **revive** them; staying next to a teammate in crisis shortens it.
- **Online** with a host and up to three guest PCs (ENet): rooms by **8-letter code**, IP or automatic port forwarding (UPnP), each PC with its own camera and save, and a bot that takes the place of anyone who disconnects until they come back.

### Progress and menus

- **Three save slots**, each with its own money, unlocks and achievements, plus a **cloud copy** in your GitHub account (a secret gist) to carry on from another PC; if a save has changed on two PCs, the game asks which one to keep ([guide](docs/GUARDADO_NUBE.md), in Spanish).
- **Antique shop:** permanent boosts, characters, companions and **outfits** (83 pieces shown on the model).
- **The Library:** a living bestiary, the arsenal, the places, the trophy room, the expedition archive, the investigator's manual (with clips from the game) and your account's statistics, with 1920s journal notes.
- **39 achievements** with rewards, an intro, **stories** that tell each level before you play it and an illustrated ending for each part.
- **More modes:** the endless night, the daily run, the boss rush, expeditions, 21 challenges and fishing on the Innsmouth pier.
- **Four-player selection screen:** each player joins with Start, picks a character and a companion, and rotates them to see every side.
- **Accessibility:** interface size, high-contrast bullets, fewer flashes, adjustable camera shake and vibration. Remappable gamepad and keyboard controls.
- **In English and Spanish**, with a selector in Settings.

### Tech

- **All 3D art is generated by code:** every character, creature, prop and level comes from a Python script that places the voxels (48 per metre for characters and companions). Nothing is modelled by hand in an editor.
- **Voxel meshes** with hidden-face culling, per-vertex ambient occlusion, an emissive layer and a disk cache. Animation by parts, with no rigging, using layers and blends.
- **Thousands of bullets without one node per bullet:** packed arrays, a spatial grid and `MultiMesh`. Voxel weapon effects (flames, smoke, acid, explosions) with shared particles.
- **Physics interpolation** for displays above 60 Hz, with physics at 60 Hz.
- **Data before code:** characters, weapons, enemies, patterns, levels, arenas, companions, items, achievements, shop and texts are `.tres` resources or JSON. A new enemy can be added without touching code.
- **Host-authoritative networking:** each PC decides the hits its own players take (what you dodge on screen is what counts) and the host rules the world, with 20 Hz interpolated snapshots and about 19 kB/s per guest.
- **Balancing with simulations:** a bot that dodges and picks upgrades (`SmartBot`) plays hundreds of games in parallel to measure every level and difficulty.

## Screenshots

| | |
|:---:|:---:|
| ![Base camp on the Ross Sea coast](docs/img/p1_campamento.jpg) | ![The mountain pass](docs/img/p1_paso.jpg) |
| **Part 1 · Base camp.** Blind albino penguins and protoplasmic fragments between the hut and the tents, on the Ross Sea coast. | **Part 1 · The mountain pass.** Crystals, rock spires and shoggoths in the cavern mist. |
| ![The rooftop escape](docs/img/p2_tejados.jpg) | ![The marshes and the abandoned railway to Rowley](docs/img/p2_pantano.jpg) |
| **Part 2 · The rooftop escape.** The Devil Reef horde climbs onto the roof of the Gilman House: hold out for one minute. | **Part 2 · The railway to Rowley.** The railway embankment between slowing waters and Deep Ones rising from the marsh. |
| ![The sculptor Wilcox's studio](docs/img/p3_estudio.jpg) | ![The ritual in the Louisiana swamps](docs/img/p3_ritual.jpg) |
| **Part 3 · Wilcox's studio.** Sculptures, easels and nightmares from the wave of dreams, in Providence. | **Part 3 · The swamp ritual.** Bonfires, armed cultists from the *Alert* and bat-winged devils. |
| ![The storm in the Pacific](docs/img/p3_tormenta.jpg) | ![R'lyeh risen](docs/img/p3_rlyeh.jpg) |
| **Part 3 · The storm in the Pacific.** A wave sweeps the deck as the white polypous thing rises. | **Part 3 · R'lyeh risen.** Flagstones that don't add up, lesser Old Ones and emanations of the colossal door. |
| ![The enchanted wood and the outskirts of Ulthar](docs/img/p4_bosque.jpg) | ![The plateau of Leng](docs/img/p4_leng.jpg) |
| **Part 4 · The enchanted wood.** Zoogs among the oaks and mushrooms, and the cats of Ulthar coming down to help. | **Part 4 · The plateau of Leng.** Shantaks, purple spiders and their webs, and the icy wind of Leng. |
| ![The Gardner farm](docs/img/noche_color.jpg) | ![The Rue d'Auseil](docs/img/noche_zann.jpg) |
| **Standalone night · The Colour Out of Space.** The Gardner farm withers around the well. | **Standalone night · The Music of Erich Zann.** The viol holds back what is outside while it plays; behind the window there is no Paris. |

### The bosses

| The primordial shoggoth | Father Dagon | Cthulhu | Nyarlathotep |
|:---:|:---:|:---:|:---:|
| ![The primordial shoggoth](docs/img/jefe_shoggoth.jpg) | ![Father Dagon](docs/img/jefe_dagon.jpg) | ![Cthulhu](docs/img/jefe_cthulhu.jpg) | ![Nyarlathotep](docs/img/jefe_nyarla.jpg) |
| Chases you through the tunnels of the underground sea, crying "Tekeli-li!". | Rises from the depths of Devil Reef, slams with his hands and calls the Deep Ones. | Looms through the door of R'lyeh, sweeps with his tentacles and, when he falls, re-forms once. | Waits atop Kadath in three shapes: the black pharaoh, the swarm and the faceless one. |

### Menus

| | |
|:---:|:---:|
| ![Four-player character selection](docs/img/seleccion.jpg) | ![Campaign map](docs/img/mapa.jpg) |
| **Selection.** Up to four players pick character, outfit and companion at the same time, each with their own gamepad. | **The map.** Four parts of five levels joined by a path of ink, with the standalone nights on the side. |
| ![Level story](docs/img/relato.jpg) | ![Character sheet](docs/img/ficha.jpg) |
| **Stories.** Each level is told before you play it, over a map of the place. | **The character sheet** in-game: attributes, weapons and items. |
| ![Antique shop](docs/img/tienda.jpg) | ![The Library](docs/img/biblioteca.jpg) |
| **The antique shop,** with the old man behind the counter. | **The Library:** living bestiary, arsenal, places, trophies, manual and statistics. |
| ![Achievements](docs/img/logros.jpg) | ![Play online](docs/img/online.jpg) |
| **Achievements,** with their reward and progress. | **Play online:** create a room or join one with its code. |

## The campaign

Four parts of five levels. Each level opens when you beat the previous one, and each part when you beat the previous part. Every part starts again with the weakest creatures, but is harder than the last one, counting what you have bought in the shop.

### Part 1 · *At the Mountains of Madness* (Antarctica)

<!-- tabla:parte1 -->
| Level | Creatures | Mid-level | Final event |
|---|---|---|---|
| 1. Base camp on the Ross Sea coast | Blind albino penguin, Protoplasmic fragment | — | Lurker |
| 2. Lake's ruined camp | Blind albino penguin, Protoplasmic fragment, Revived Elder Thing, Winged Elder Thing, Lake's expedition member | — | The first to wake |
| 3. The mountain pass and its caverns | Blind albino penguin, Protoplasmic fragment, Revived Elder Thing, Winged Elder Thing, Slave shoggoth, Mimic shoggoth, Burrowing shoggoth | Gedney, what's left of him | The shoggoth of the cavern |
| 4. The cyclopean city of the Elder Things | Blind albino penguin, Protoplasmic fragment, Revived Elder Thing, Winged Elder Thing, Slave shoggoth, Elder Thing warrior, Mutilated Elder Thing, Elder Thing sower | — | The guardian of the city |
| 5. The tunnels and the abyss of the underground sea | Blind albino penguin, Protoplasmic fragment, Slave shoggoth, Mutilated Elder Thing, Glowing-eyed shoggoth, Elder Thing of the abyssal sea, Burrowing shoggoth, Elder Thing sower | — | **Boss: The primordial shoggoth** |
<!-- /tabla -->

### Part 2 · *The Shadow over Innsmouth* (New England)

<!-- tabla:parte2 -->
| Level | Creatures | Mid-level | Final event |
|---|---|---|---|
| 1. Newburyport and the road to Innsmouth | Innsmouth fisherman, Innsmouth townswoman, Innsmouth old man, Acolyte of the Order of Dagon | — | The deacon of the Order |
| 2. The streets of Innsmouth and the Order's temple | Innsmouth fisherman, Innsmouth townswoman, Innsmouth old man, Acolyte of the Order of Dagon, Advanced hybrid, Advanced hybrid, Priest of the tiara, Guardian of the Order of Dagon | — | The high priest of the Order |
| 3. The Gilman House hotel and the rooftop escape | Deep One, Spitting Deep One, Advanced hybrid, Advanced hybrid, Rooftop lurker, Guardian of the Order of Dagon, Daughter of the Marshes | Captain Obed Marsh | Hold out 60 s against the horde |
| 4. The marshes and the abandoned Rowley line | Deep One, Swamp Deep One, Spitting Deep One, Advanced hybrid, Advanced hybrid, Elder Deep One of Y'ha-nthlei, Tide swimmer, Daughter of the Marshes | — | Barnabas Marsh, transformed |
| 5. Devil Reef and Y'ha-nthlei | Deep One, Swamp Deep One, Spitting Deep One, Elder Deep One of Y'ha-nthlei, Advanced hybrid, Tide swimmer | Pth'thya-l'yi, the ancestor | **Boss: Mother Hydra → Father Dagon** |
<!-- /tabla -->

### Part 3 · *The Call of Cthulhu* (Providence, Louisiana and the Pacific)

<!-- tabla:parte3 -->
| Level | Creatures | Mid-level | Final event |
|---|---|---|---|
| 1. Providence: the sculptor Wilcox's studio | Nightmare of the dream wave, Cthulhu cultist, Providence sleepwalker | — | The nightmare of the bas-relief |
| 2. The Louisiana swamps: the cult's ritual | Cthulhu cultist, Armed cultist of the Alert, Bat-winged devil, Swamp drummer, Living idol | Old Castro | The priest of the ritual |
| 3. The docks and the deck of the Alert | Deep One, Spitting Deep One, Cthulhu cultist, Armed cultist of the Alert, Living idol | Spawn of Cthulhu | The greater spawn |
| 4. The storm in the Pacific | The white polypous thing, Deep One, Armed cultist of the Alert, Bat-winged devil, Providence sleepwalker | — | The white thing of the hidden lake |
| 5. R'lyeh risen: the colossal door | Emanation of the door, Deep One, Cthulhu cultist | Lesser Great Old One | **Boss: Cthulhu → Cthulhu, reformed** |
<!-- /tabla -->

### Part 4 · *The Dream-Quest of Unknown Kadath* (the Dreamlands)

It opens when you beat Cthulhu. More colour than the earlier parts, without leaving the night, and each level with something of its own: the cats of Ulthar, the black galley that lands its crew, the spiders' webs, the ghasts that hate the light, the night-gaunts that carry you through the air and the flutes of the Other Gods.

<!-- tabla:parte4 -->
| Level | Creatures | Mid-level | Final event |
|---|---|---|---|
| 1. The enchanted wood and the outskirts of Ulthar | Zoog, Treetop zoog, Nightmare of the dream wave | — | The elder of the zoogs' council |
| 2. The port of Dylath-Leen and the black galley | Merchant of Leng, Moon rower, Nightmare of the dream wave | — | The master of the black galley |
| 3. The plateau of Leng and the windowless monastery | Shantak, Purple spider of Leng, Merchant of Leng | The high priest not to be described | The mother of the spiders of Leng |
| 4. The vaults of Zin and the tower of the gugs | Ghast, Gug | — | The great gug of the Tower of Koth |
| 5. The summit of Kadath and the onyx castle | Larva of the Other Gods, Night-gaunt | — | **Boss: Nyarlathotep, the Crawling Chaos** |
<!-- /tabla -->

### Standalone nights

Four more stories, outside the campaign, from the map's "Standalone nights" button: one level with its two creatures, its boss, its story and its own rules.

<!-- tabla:noches -->
| Level | Creatures | Mid-level | Final event |
|---|---|---|---|
| The Gardner farm | Grey cow, Withered farmer | — | **Boss: The colour rising from the well** |
| Sentinel Hill | Dunwich whippoorwill, Devotee of the hills | — | **Boss: Wilbur's brother** |
| The ruins of Pnakotus | Possessed by the Great Race, Flying polyp | — | **Boss: The ancient polyp** |
| The Rue d'Auseil | Rue d'Auseil lodger, Shred of the night | — | **Boss: What lies beyond the window** |
<!-- /tabla -->

- ***The Colour Out of Space*:** the Gardner farm withers around the well, and whatever the colour touches drains health.
- ***The Dunwich Horror*:** the unseen thing on Sentinel Hill only leaves footprints; the powder of Ibn Ghazi shows it for a moment.
- ***The Shadow Out of Time*:** the almost invisible polyps rise from the trapdoors of Pnakotus, which are sealed by standing on them.
- ***The Music of Erich Zann*:** the viol at the highest window pushes back and burns what is outside, and speeds up into a frenzy.

## Characters

All of them come from Lovecraft's stories or are invented relatives and acquaintances of his characters. You start with four (Dyer, Olmstead, Peaslee and Whipple); the rest are bought in the shop, except two secret ones you have to discover.

Each investigator has **seven attributes** (Power, Intelligence, Strength, Constitution, Tenacity, Dexterity and Culture), at 10 plus 20 points spread according to their background. They determine health, sanity, dodge, speed and the damage of each weapon type, and each level-up adds one more point.

![Dyer, Olmstead, Legrasse, Johansen, Peaslee, Varga and Whipple](docs/img/personajes_1.jpg)
![Blake, Iwanicki, Elwood, Malone, Armitage and West](docs/img/personajes_2.jpg)
![Carter, Whateley, Pickman, Ward, Gilman, Tillinghast, Derby, Asenath and Kuranes](docs/img/personajes_3.jpg)

The faces are drawn by hand, voxel by voxel, on the model's own head: eyebrows, eyes with irises, raised noses, moustaches, glasses, freckles and lips.

![The faces up close](docs/img/cabezas.jpg)

<!-- tabla:personajes -->
| Character | Starting weapon | Trait | Dodge | Story |
|---|---|---|---|---|
| **William Dyer**, geologist at Miskatonic University *(starter)* | Stielhandgranate | Explosions 25 % bigger | Slide | *At the Mountains of Madness* |
| **Robert Olmstead**, traveller and narrator of Innsmouth *(starter)* | Webley Mk VI | 30 % longer dodge | Roll | *The Shadow over Innsmouth* |
| **Amelia Peaslee**, archaeologist, niece of Professor Peaslee *(starter)* | Lever-action rifle | Luckier: sometimes a fourth upgrade option | Roll | *The Shadow Out of Time* |
| **Dr Marian Whipple**, doctor, niece of Dr Elihu Whipple *(starter)* | Scalpels | Revives teammates 50 % faster | Leap | *The Shunned House* |
| **John R. Legrasse**, new Orleans police inspector | Pump-action shotgun | 25 % more damage against cultists and human enemies | Leap | *The Call of Cthulhu* |
| **Gustaf Johansen**, second mate of the Emma | Machete | 25 % more melee damage | Penguin belly-slide | *The Call of Cthulhu* |
| **Madame Ludmila Varga**, spiritualist and medium of Arkham | Necronomicon | Arcane weapons cost her half the sanity | Flash | *Arkham medium* |
| **Henrietta Blake**, writer, sister of Robert Blake | Trapezohedron | 15 % more experience per gem | Slide | *The Haunter of the Dark* |
| **Father Iwanicki**, priest of St Stanislaus' church | Banishing formula | A calming aura: he and nearby teammates recover sanity | Roll | *The Dreams in the Witch House* |
| **Sergeant Frank Elwood**, great War veteran | Mauser C96 pistol | Takes 15 % less physical damage | Penguin belly-slide | *The Dreams in the Witch House* |
| **Vera Malone**, red Hook bootlegger | Thompson M1928 | Up to 50 % more damage the closer the enemy is | Slide | *The Horror at Red Hook* |
| **Professor Henry Armitage**, librarian of Miskatonic University | Powder of Ibn-Ghazi | Magic weapons recharge 20 % sooner | Flash | *The Dunwich Horror* |
| **Herbert West**, physician, reanimator | West's injector | On level-up, heals nearby teammates for 15 % of their health | Roll | *Herbert West–Reanimator* |
| **Randolph Carter**, boston dreamer *(secret)* | Key of dreams | Madness crises last half as long for him: he knows how to wake up | Flash | *The Silver Key* |
| **Wilbur Whateley**, son of Lavinia, of Dunwich *(secret)* | Footsteps of the unseen | Half from another world: mental damage affects him 40 % less | Leap | *The Dunwich Horror* |
| **Richard Upton Pickman**, boston painter | Pickman's canvases | He has painted worse things: loses 30 % less sanity | Painting | *Pickman's Model* |
| **Charles Dexter Ward**, providence antiquarian | Essential salts | Curwen's shadow: up to 40 % more damage the less sanity he has left | Dust | *The Case of Charles Dexter Ward* |
| **Walter Gilman**, miskatonic mathematics student | Impossible angles | Between the angles: bullets hit him less (his hitbox is 30 % smaller) | Angle | *The Dreams in the Witch House* |
| **Crawford Tillinghast**, physicist and philosopher of Providence | Machine from beyond | Sees beyond: his weapons reach 15 % further | Beyond | *From Beyond* |
| **Edward Derby**, arkham poet (and Asenath Waite) | The threshold | Two souls in two bodies: every dodge swaps them. Edward strikes up close; Asenath glares from afar. Each swap restores 3 health and sanity | Body swap | *The Thing on the Doorstep* |
| **Kuranes**, london dreamer, king of Celephaïs | Reverie of Celephaïs | Half asleep: recovers 0.4 sanity per second, even among the horrors | Dream | *Celephaïs* |
<!-- /tabla -->

## Companions

Each player can bring one. They level up with you and are bought in the shop.

![Dog, cat, rat, toad, owl, baby shoggoth, Mini-Byakhee and raven](docs/img/companeros_1.jpg)
![Moth, gull, Mini-Mi-Go, spider of Tindalos, serpent of Yig, Innsmouth fish, Mini-Dhole and goat](docs/img/companeros_2.jpg)

<details>
<summary><b>The 16 companions</b></summary>

<!-- tabla:companeros -->
| Companion | What it does |
|---|---|
| Rat in the Walls | A huge, ill-mannered rat. Every so often it digs and finds dollars; sometimes, an arcane chest |
| Innsmouth fish | A fish with legs that thinks it's human. It takes a run-up and rams the enemies in its way |
| Lake's sled dog | It runs at nearby enemies and bites them; the higher your level, the harder it bites |
| Arkham raven | A thieving raven. It flies off for distant gems and brings them to you; on the way it steals a few coins, from whoever |
| Goat of the woods | A seemingly innocent little goat. It rams the enemies: pushing and stunning them |
| Innsmouth toad | Hideous but adorable. It spits poisonous slime: it leaves a puddle that damages and weakens enemies |
| Dream owl | It looks wise. It flies beside you and gives you 12 % more experience, up to 30 % as it levels up |
| Innsmouth gull | A noisy scavenger. It goes off for fish and brings it back: it heals 8 % health and sanity (up to 15 %) to whoever needs it most. It screeches when it spots an elite |
| Cat of Ulthar | A seemingly ordinary black cat... until it gets angry. It scratches enemies that come close; if you get hurt, its fur bristles and it attacks twice as fast |
| Moth of Leng | Pretty... until it opens its wings. It shakes its dust over groups of enemies: they wander about confused and don't shoot |
| Serpent of Yig | A snake that stares far too intently. It bites and poisons: the poison keeps doing damage for a few seconds |
| Mini-Byakhee | An alien bat with an unfriendly face. It flies high and dives onto the enemies: an area blow that pushes them back |
| Baby shoggoth | A little black ball full of eyes. It sticks close to you and swallows enemy bullets that pass nearby |
| Mini-Mi-Go | A tiny space crustacean. It fires rays at the nearest enemy |
| Mini-Dhole | A gigantic worm reduced to a pet. It burrows and surfaces under groups of enemies: striking, pushing and stunning them |
| Spider of Tindalos | A spider that doesn't respect the laws of geometry. It teleports behind an enemy, bites hard and stuns it |
<!-- /tabla -->

</details>

## Weapons and items

**58 weapons** (16 physical, 17 firearms and 25 magic), each with two evolutions:

![Icons of the 58 weapons](docs/img/armas.jpg)

They all fire on their own, and each one's data decides how it aims: at the nearest enemy, at the densest area, at elites, around the character… They level from 1 to 5 and their damage grows with the attributes of their type. With the weapon at level 5 and its paired item, an arcane chest turns it into one of its two **evolutions**, your choice:

![Icons of the 116 evolutions](docs/img/evoluciones.jpg)

<details>
<summary><b>The 58 weapons and their evolutions</b></summary>

<!-- tabla:armas -->
| Weapon | Type | How it works | Evolutions (with) |
|---|---|---|---|
| Anchor of the Alert | Physical | An anchor on a chain that swings around the character at a great distance, slow and heavy | Johansen's anchor / Windlass of the Alert (Sealskin cuirass) |
| Boomerang | Physical | It flies out to its range and comes back to your hands, hitting on the way out and on the way back | Bone boomerang / War boomerang (Pabodie's skis) |
| Chemical thrower | Physical | Acid flask: enemies in the puddle take 25 % more damage | Arkham apothecary / Aqua regia (Laudanum) |
| Chlorine gas | Physical | A toxic cloud that drifts slowly towards the enemies and poisons them | Mustard gas / Phosgene (Curwen's elixir) |
| Crossbow | Physical | Bolts that pierce and pin the enemy in place for a moment | Crossbow of fortune / Cranequin crossbow (Bone die) |
| Fishing net | Physical | Throws a net over the densest group: those underneath are held still for 2 seconds. Elites are only slowed | Innsmouth net / Trawl nets (Deep One scales) |
| Geologist's hammer | Physical | Strikes the ground and opens a crack that runs in a straight line, damaging and briefly stunning everything in its path | Hammer of the Barrier / Pabodie's ice axe (Crampons) |
| Machete | Physical | A circular slash around the character; it only strikes if someone is close | Canefield machete / Harvest machetes (Stevedore's gloves) |
| Molotov cocktail | Physical | A bottle thrown in an arc that makes a pool of flames | The Emma's cocktail / Kerosene bomb (Rum flask) |
| Scalpels | Physical | A fan of piercing blades | Surgical kit / Anatomist's scalpel (Reindeer coat) |
| Stielhandgranate | Physical | A stick grenade thrown at the densest area; a big explosion on impact | Bundled charge / Grenade cluster (Reflexes) |
| Sword cane | Physical | A long, quick thrust at the nearest enemy that pierces everything in the line. It waits until someone is within reach | Duellist's rapier / Hussar's sabre (Whetstone) |
| Traps | Physical | Leaves traps on the ground: the first one to step on them is caught and wounded | Hunter's traps / Bear trap (Fang necklace) |
| West's injector | Physical | Fires serum darts: an enemy that dies with the serum inside rises for 6 seconds as an ally and attacks its own | Perfected reagent / Halsey's serum (Medical kit) |
| Whaling harpoon | Physical | A heavy projectile that pierces and drags lesser enemies along | Nantucket harpoon / Bomb lance (Sinker) |
| Whip | Physical | A long lash in an arc ahead that hits everyone in the arc | Tamer's whip / Overseer's whip (Lake's whistle) |
| BAR M1918 | Firearm | Bursts whose bullets bounce to another nearby enemy | Assault BAR / Marksman's BAR (Snow boots) |
| Danforth's Nagant | Firearm | A revolver whose rate of fire speeds up while it has someone to shoot at, up to two and a half times | Lookout's Nagant / Seven-shot Nagant (Magnifying glass) |
| Fireworks | Firearm | Erratic rockets that burst into sparks | Grand fireworks display / Fairground rocket (Firecrackers) |
| Flammenwerfer | Firearm | A cone of fire that leaves the ground burning | Breath of Moloch / Thermal lance (Matches of Cthugha) |
| Flare gun | Firearm | A flare that lights up and lures nearby enemies (elites don't fall for it) | Lighthouse flare / Magnesium flare (Cloak of the Black Man) |
| Lever-action rifle | Firearm | Fast shots that pierce several enemies | Miskatonic rifle / Big-game rifle (Field diary) |
| Lewis gun | Firearm | Sets the machine gun on its tripod on the ground; it fires on its own at the nearest enemy for 8 seconds | Machine-gun nest / Firing posts (Marksmanship manual) |
| Mauser anti-tank rifle | Firearm | A very slow shot that pierces every enemy in the line | Anti-tank gun / Tank hunter's rifle (Hunter's medallion) |
| Mauser C96 pistol | Firearm | Short bursts of three tracers | Tillinghast's Mauser / Mauser carbine (Tillinghast's watch) |
| Pump-action shotgun | Firearm | Pellets that spread in a ring around the character | Trench shotgun / Buckshot shotgun (Bandolier) |
| Sawn-off shotgun | Firearm | Two shots in a row of pellets in a short, wide cone that pushes hard | Smuggler's sawn-off / Slaughterhouse sawn-off (Shoggoth tooth) |
| Springfield M1903 | Firearm | A slow, powerful shot that targets the elite or the enemy with the most health first; sometimes it is a triple critical hit. Pierces one | Sniper's Springfield / Belleau Springfield (Pickman's eye) |
| Stokes mortar | Firearm | A shell in a high arc at the densest group at range; a big explosion | Mortar battery / Incendiary mortar (Ponape powder) |
| Tesla coil | Firearm | Discharges a bolt at the nearest enemy that jumps to the next ones, up to four; each jump deals a little less | Nikola's coil / Wardenclyffe bolt (Dowsing rod) |
| Thompson M1928 | Firearm | Tight bursts of small projectiles | Chicago Thompson / Federal agent's Thompson (Obed's gold) |
| Twin Lugers | Firearm | A pistol in each hand: they fire at once where you are heading and behind you, without seeking a target | The ace's Lugers / Trick-shot Lugers (Aviator goggles) |
| Webley Mk VI | Firearm | Heavy projectiles that knock enemies back | Lookout's revolver / Six-shot Webley (Lake's compass) |
| Aether lens | Magic | A beam held on one enemy: its damage grows while it stays on it, up to three times. If the enemy falls, it jumps to another. Costs sanity | Aether eye / Aether prism (Spyglass) |
| Arcane Sign | Magic | Draws a sign beneath their feet that damages enemies and pushes them outwards; enemy bullets crossing it move at half speed. Costs sanity | Elder Sign / Sign of Koth (Scapular) |
| Banishing formula | Magic | A wave that spreads out from the character, pushing and stunning. Costs sanity | Greater exorcism / Banishing litany (Elder Sign) |
| Breath of Ithaqua | Magic | A cone of icy wind that slows enemies and freezes those who stay inside | Breath of the Wendigo / The one who walks on the wind (Pemmican) |
| Essential salts | Magic | Scatters the salts where most enemies have fallen and recites the formula: it damages those around and raises two of the fallen, who fight for him for a while. Costs sanity | Dragon's Head / Dragon's Tail (Jar of the Custodes) |
| Flame of Cthugha | Magic | A ball of living fire that pierces enemies and leaves a burning trail | Flame of the cult / Sparks of Fomalhaut (Esoteric talisman) |
| Footsteps of the unseen | Magic | Wilbur's brother, whom no one can see, advances in a straight line towards the densest group: it crushes and stuns whatever it treads on | What came down from Sentinel Hill / Wilbur's twin (Wilbur's cipher diary) |
| Impossible angles | Magic | Throws angles that fly out crooked and turn corners at right angles until they find the enemy. They pass through walls, trees and several enemies | The witch's geometry / The throne of Azathoth (Balustrade figurine) |
| Key of dreams | Magic | Randolph Carter's silver key flies out to its range and back, leaving everything it touches drowsy for a moment | Key of unknown Kadath / Keys of Ulthar (Map of the Dreamlands) |
| Lamp of Alhazred | Magic | A beam of light that sweeps in a circle around the character | Lamp of the Mad Arab / Beacon of Irem (Ankh of Nephren) |
| Lamplighter's staff | Magic | Releases will-o'-the-wisps that zigzag and seek out enemies on their own. Costs sanity | Will-o'-the-wisp lantern / St Elmo's fire (Meerschaum pipe) |
| Machine from beyond | Magic | A violet wave that reveals what surrounds us: those it reaches take 30 % more damage from everything for a few seconds, and the hidden come out. Each pulse in a row heats up the machine and takes more sanity from the whole group nearby | What surrounds us / Jellyfish from beyond (Machine valve) |
| Mi-Go orb | Magic | An orb of the fungi from Yuggoth flies around you on its own and shoots the nearest enemy. Costs sanity | Swarm of Yuggoth / Mi-Go cylinder (Crystal of Ithaqua) |
| Necronomicon | Magic | Pages that orbit around the character. Costs sanity | Complete Necronomicon / Al Azif (Pnakotic Manuscripts) |
| Pickman's canvases | Magic | Plants a painting among the enemies that lures them and leaves them vulnerable. When they break it, it bursts and a ghoul comes out of it to hunt for a while | North End gallery / Pickman's model (Photograph of the model) |
| Powder of Ibn-Ghazi | Magic | Spreads a cloud over the densest group: inside, enemies move 40 % slower and deal 30 % less damage. Costs sanity | Powder of the Elder Things / Powder of Ibn Schacabao (Map of Leng) |
| Ray of Yith | Magic | Freezes the enemy in time for 1.5 s; the damage it takes meanwhile is applied at the end, 50 % greater. Costs sanity | Ray of the Great Race / Ray of Pnakotus (Hourglass of Yith) |
| Resonator | Magic | It hums every so often and its pulse dissolves nearby enemy bullets; it deals little damage. It only hums if bullets or enemies are close. Costs sanity | Great resonator / Crawford's resonator (Shield of Nodens) |
| Reverie of Celephaïs | Magic | A piece of the sky of Celephaïs where the enemies are thickest: inside, they dream and move ever more slowly, their bullets slow down and the investigators recover sanity | Valley of Ooth-Nargai / Serannian (Poppy of Ooth-Nargai) |
| Ritual dagger | Magic | Stabs the nearest enemy and curses it: it slowly loses health and, if it dies cursed, the curse jumps to those beside it. Costs sanity | Sacrificial dagger / Obsidian dagger (Ghoul's fang) |
| Sphere of Yog-Sothoth | Magic | A slow orb that pulls enemies into its centre and grinds them up | The Gate and the Key / Umr at-Tawil (Silver key) |
| Tentacles of Shub | Magic | Tentacles that burst from the ground, after a warning, beneath random enemies | The Thousand Young / The Black Goat (Eltdown shard) |
| The threshold | Magic | It depends on who is in the body. Edward strikes all around, close and hard (physical); Asenath casts two green glares that seek out the enemy (magic, they cost sanity). Each dodge swaps them | The thing on the doorstep / The eyes of Ephraim (Knocker of the Derby house) |
| Trapezohedron | Magic | A ray of concentrated light that damages everything it passes through. Costs sanity | Awakened Trapezohedron / Blake's Trapezohedron (Idol of Cthulhu) |
| Yellow Sign | Magic | Enemies who look at it go mad and attack their own for a few seconds | The King in Yellow / Carcosa (Psalter) |
<!-- /tabla -->

</details>

**58 items**, from level-ups (permanent boosts are bought in the shop):

![Icons of the 58 items](docs/img/objetos.jpg)

<details>
<summary><b>The 58 items</b></summary>

<!-- tabla:objetos -->
| Item | Effect |
|---|---|
| Ankh of Nephren | Once per level, when you fall you get back up with 30 % health |
| Aviator goggles | +0.08 s of invulnerability when dodging |
| Balustrade figurine | Your weapons' bullets are 12 % bigger: they hit sooner and are easier to see |
| Bandolier | +1 projectile for bullet and thrown weapons |
| Bone die | +15 % luck: sometimes one more option when levelling up |
| Cloak of the Black Man | When you dodge you leave a lure that draws enemies for 1 s per level |
| Crampons | +15 % dodge distance |
| Crystal of Ithaqua | 6 % chance that a hit slows the enemy for 1.5 s |
| Curwen's elixir | +15 % damage for 2 s after dodging |
| Deep One scales | Returns 30 % of contact damage to whoever hits you |
| Dowsing rod | Arcane chests appear 15 % more often |
| Elder Sign | −10 % mental damage, including from auras |
| Eltdown shard | 8 % chance that a killed enemy bursts and damages those around it |
| Esoteric talisman | Magic weapons cost 12 % less sanity |
| Fang necklace | +25 % critical damage |
| Field diary | +20 maximum sanity |
| Firecrackers | When you dodge, a charge explodes where you were |
| Ghoul's fang | Each enemy killed heals 0.15 health |
| Hourglass of Yith | +15 % duration of zones, orbits, beams and turrets |
| Hunter's medallion | +30 % damage to elites and unique beings |
| Idol of Cthulhu | +12 % enemies, experience and dollars |
| Jar of the Custodes | Allies raised by your weapons (risen, ghouls, reanimated) hit 15 % harder |
| Knocker of the Derby house | Three knocks and then two: the first damage to an unhurt enemy is 12 % higher |
| Lake's compass | +30 % experience pickup radius |
| Lake's whistle | +20 % companion damage and speed |
| Laudanum | Madness crises last 20 % less |
| Machine valve | Revealed enemies take 8 % more damage |
| Magnifying glass | +10 % experience |
| Map of Leng | +10 % area of explosions, zones, waves and slashes |
| Map of the Dreamlands | Magic weapons recharge 7 % sooner |
| Marksmanship manual | +12 % firearm damage |
| Matches of Cthugha | 6 % chance that a hit sets the enemy on fire for 3 s |
| Medical kit | Recovers 0.5 health per second |
| Meerschaum pipe | Recovers 0.6 sanity per second |
| Obed's gold | +15 % dollars for the team |
| Pabodie's skis | +1 dodge in a row before recharging |
| Pemmican | Food and potions heal 30 % more |
| Photograph of the model | Allies raised by your weapons (ghouls, reanimated) last 12 % longer |
| Pickman's eye | +8 % critical chance (damage ×1.5) |
| Pnakotic Manuscripts | +12 % magic weapon damage |
| Ponape powder | +12 % projectile speed |
| Poppy of Ooth-Nargai | Enemies slowed by your weapons move 6 % slower |
| Psalter | Each enemy killed restores 0.12 sanity |
| Reflexes | Dodge recharges 10 % sooner |
| Reindeer coat | +20 maximum health |
| Rum flask | +8 % damage |
| Scapular | +25 % invulnerability after being hit |
| Sealskin cuirass | −2 physical damage from each hit |
| Shield of Nodens | Every 25 s it absorbs a whole hit (3 s sooner per level) |
| Shoggoth tooth | +20 % damage below 30 % health |
| Silver key | RB or E on level-up: different options, once per level |
| Sinker | +25 % knockback |
| Snow boots | +8 % walking speed |
| Spyglass | +10 % weapon range |
| Stevedore's gloves | +12 % physical weapon damage and +10 % knockback |
| Tillinghast's watch | Weapons recharge 6 % sooner |
| Whetstone | Bullets pierce 1 more enemy |
| Wilbur's cipher diary | You recover 0.25 sanity per second, and so do companions within 4 m |
<!-- /tabla -->

</details>

## Bestiary

More than 90 creatures, among them the unique beings at the end of each level, the mid-level bosses and the eight bosses. Each has its tier (1 to 5), its behaviour and its attack pattern, all in data. Low-tier creatures make up the bulk of the horde; tiers 4 and 5 are elites.

<!-- tabla:bestiario_p1 -->
**Part 1:** Blind albino penguin · Protoplasmic fragment · Lurker · Revived Elder Thing · Winged Elder Thing · Lake's expedition member · The first to wake · Slave shoggoth · Mimic shoggoth · Burrowing shoggoth · Gedney, what's left of him · The shoggoth of the cavern · Elder Thing warrior · Mutilated Elder Thing · Elder Thing sower · The guardian of the city · Glowing-eyed shoggoth · Elder Thing of the abyssal sea · The primordial shoggoth.
<!-- /tabla -->

![Creatures from part 1](docs/img/bestiario_1.jpg)

<!-- tabla:bestiario_p2 -->
**Part 2:** Innsmouth fisherman · Innsmouth townswoman · Innsmouth old man · Acolyte of the Order of Dagon · The deacon of the Order · Advanced hybrid · Advanced hybrid · Priest of the tiara · Guardian of the Order of Dagon · The high priest of the Order · Deep One · Spitting Deep One · Rooftop lurker · Daughter of the Marshes · Captain Obed Marsh · Swamp Deep One · Elder Deep One of Y'ha-nthlei · Tide swimmer · Barnabas Marsh, transformed · Pth'thya-l'yi, the ancestor · Mother Hydra · Father Dagon.
<!-- /tabla -->

![Creatures from part 2](docs/img/bestiario_2.jpg)

<!-- tabla:bestiario_p3 -->
**Part 3:** Nightmare of the dream wave · Cthulhu cultist · Providence sleepwalker · The nightmare of the bas-relief · Armed cultist of the Alert · Bat-winged devil · Swamp drummer · Living idol · Old Castro · The priest of the ritual · Spawn of Cthulhu · The greater spawn · The white polypous thing · The white thing of the hidden lake · Emanation of the door · Lesser Great Old One · Cthulhu · Cthulhu, reformed.
<!-- /tabla -->

![Creatures from part 3](docs/img/bestiario_3.jpg)

<!-- tabla:bestiario_p4 -->
**Part 4:** Zoog · Treetop zoog · The elder of the zoogs' council · Merchant of Leng · Moon rower · The master of the black galley · Shantak · Purple spider of Leng · The high priest not to be described · The mother of the spiders of Leng · Ghast · Gug · The great gug of the Tower of Koth · Larva of the Other Gods · Night-gaunt · Nyarlathotep, the Crawling Chaos.
<!-- /tabla -->

![Creatures from part 4](docs/img/bestiario_4.jpg)

<!-- tabla:bestiario_noche -->
**Standalone nights:** Grey cow · Withered farmer · The colour rising from the well · Dunwich whippoorwill · Devotee of the hills · Wilbur's brother · Possessed by the Great Race · Flying polyp · The ancient polyp · Rue d'Auseil lodger · Shred of the night · What lies beyond the window.
<!-- /tabla -->

![Creatures from the standalone nights](docs/img/bestiario_noches.jpg)

Some have behaviours of their own: the blind penguin heads to where it last heard the player, the mimic shoggoth disguises itself as an Elder Thing and transforms as you approach, nightmares pass through scenery, devils dive from above and marsh Deep Ones rise out of the water. The devouring Angles of R'lyeh can't be killed: they must be dodged. In the Dreamlands, ghasts flee from the light, the spiders of Leng spin webs that trap you and night-gaunts carry off whoever they catch. Elites roll one or two random traits (vampiric, explodes on death, ichor trail, fast or shielded), with their icon above the head.

## How to play

### Controls

| Action | Gamepad | Keyboard |
|---|---|---|
| Move | Left stick or D-pad | WASD or arrow keys |
| Dodge | A | Space |
| Shoot | Automatic | Automatic |
| Character sheet | Select | Tab |
| Arena map | D-pad down | M |
| Sheet pages / rotate on the selection screen | LB / RB | Q / E |
| Pause | Start | Esc |
| Menus: confirm / back | A / B | Enter / Esc |
| Selection: join | Start | Enter |

Everything can be remapped, on keyboard and gamepad, under **Settings → Controls**.

### Health, sanity and madness

- **Health:** drops with physical damage. In co-op, at zero you are downed for a few seconds and a teammate can revive you.
- **Sanity:** drops with mental attacks, with the presence of nearby horrors and with arcane weapons. It recovers away from enemies.
- **Madness crises** (4 to 6 seconds, at zero sanity):

| Crisis | Effect |
|---|---|
| Catatonic paralysis | Freezes in place for brief moments, warned by a tremor. Keeps shooting. |
| Hysterical flight | Runs uncontrollably away from the nearest horror. |
| Aimless wandering | Slow, erratic movement; the controls only half obey. |
| Delirium | Inverted controls. |
| Paranoia | Their weapons aim at teammates and drain their sanity (co-op only). |

- **Readability:** low-sanity effects never hide or fake the real bullets.

### Levelling up

Experience gems are shared by the team. On a level-up, the player whose turn it is chooses between three options (four with luck): a new weapon, upgrading one they already carry, or an item. Arcane chests with treasure appear throughout the levels; a level 5 weapon carrying its paired item evolves when the next one is opened.

## Installation and running

### From source

Requirements: [Godot 4.4.1](https://godotengine.org/download/archive/4.4.1-stable/) (standard version, not .NET) and a Vulkan-capable graphics card (Metal on Mac). Optional, to regenerate models, levels and images: Python 3.12 with `numpy`, `scipy` and `Pillow`.

```bash
git clone https://github.com/sergiosanchezcustodio/lovecraft-bullethell.git
cd lovecraft-bullethell
godot --headless --path . --import   # first time only: imports the resources
godot --path .                       # credits card, intro, title screen, save slots, main menu
```

On Windows you can also just double-click `jugar.cmd`. The game starts in fullscreen; to play in a window, use `godot --path . -- window=true`. The first game takes a few extra seconds to start because it builds the model meshes, which are then cached.

### Executables

With the Godot 4.4.1 export templates installed:

```bash
sh tools/exportar.sh          # compresses the models and exports Windows and macOS builds to builds/
```

This produces a single `.exe` for 64-bit Windows 10/11 and a universal `.app` for macOS 11 or later (Apple Silicon and Intel). The Mac version isn't signed with an Apple developer account: the first time, open it with **right-click → Open**.

## Playing online

Up to four players spread across one to four PCs. One PC creates the room (**Jugar → Jugar online → Crear sala**, "Play → Play online → Create room") and shares its **8-letter code** with the others, who join with it. If the router opens the port by itself (UPnP), the code works from anywhere; otherwise, open port 24680 manually or use a virtual private network.

- Everyone needs the **same version** of the game (shown at the bottom right of the main menu).
- The room is the character selection screen itself: each PC picks with its own unlocks and the host chooses the level.
- Each PC has its own camera, its HUD with ping, and its own save (money and achievements).
- If someone disconnects, a bot takes their place, and they can come back at the next level.
- Holding **F9** or **LB+RB** drops a marker in the network log of every PC, so you can discuss later what happened.

Full guide for players (in Spanish) in [`docs/JUGAR_ONLINE.md`](docs/JUGAR_ONLINE.md).

## For developers

The code, comments and internal documentation are in Spanish.

### Structure

```
addons/      GUT (tests)
data/        Game data: characters, weapons, enemies, patterns, levels, arenas,
             companions, items, outfits, shop, achievements, weather, ambience, campaign and texts
docs/        Design (GDD), roadmap, journal, lessons, performance, guides and images
models/      Voxel models in JSON (generated by the scripts in tools/)
resources/   Illustrations, masks, icons, music, sounds and fonts
scenes/      main (router), title, select, relato, game, preview and bench
scripts/     Code by system: anim, bullets, core, enemies, fx, input, level, menus, net,
             pets, player, progression, save, title, ui, weapons
tests/       GUT tests
tools/       Generators for models, levels, effects, icons and images; simulations
```

### Voxel art pipeline

1. **Python generator** (`tools/gen_*.py`, built on `tools/voxlib.py`, plus `tools/cuerpo.py` for humans): builds the model from primitives and flat-faced sections, colours it by material and paints the details. Faces are drawn row by row, like a sprite, onto the head.
2. **JSON** (`models/*.json`): a list of voxels `[x, y, z, part, r, g, b, glow]` and one pivot per part.
3. **`VoxelBuilder`** turns the JSON into meshes: it culls hidden faces, computes per-vertex ambient occlusion, separates the emissive layer and caches the result.
4. **Animation in code:** each model family has its script in `scripts/anim/`, which rotates the parts according to the animation phase.
5. **Levels** from recipes (`tools/arena_kit.py`): ground, borders, light, weather, scattered props and a walkability map built from each piece's actual voxels.
6. **References and icons** with FLUX: locally with ComfyUI (`tools/generar_local.py`) or, with permission, on Replicate. References guide the design; the models always come from the generator.

```bash
python tools/gen_dyer.py                              # regenerate a character
python tools/gen_vestuario.py                         # and then its outfits
python tools/gen_arena_campamento.py                  # level 1 arena and its map
godot --path . -- still 0 dyer,olmstead,legrasse      # screenshot of one or more models
godot --path . -- anim 45 dyer walk                   # frames of an animation
```

### Launch options

Scenes read whatever comes after `--`. Some useful ones:

```bash
godot --path . -- title                                         # title screen
godot --path . -- select join=3                                 # selection screen with three test players
godot --path . -- level=p2_n2 bot=smart bots=3 autopick=true    # a game with four bots
godot --path . -- level=p3_n5 boss=true final_at=5 god=true     # straight to Cthulhu
godot --path . -- character=legrasse nolevel=true cam=3.5       # test field, close up
godot --path . -- select net_host=true net_upnp=false           # test online room (and another window with net_join=127.0.0.1)
godot --path . --disable-vsync -- bot=circle god=true max_alive=150 spawn_rate=40 bullet_rain=1000 perf=10
                                                                # stress test
python tools/simular.py --ts 2 --par 2                          # balance simulations with SmartBot
```

The full list is in [`CLAUDE.md`](CLAUDE.md). In-game, **Pause → Debug** lets you change almost anything without restarting.

### Tests

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd
```

419 tests with [GUT 9.4](https://github.com/bitwes/Gut): movement, combat, bullets, weapons and evolutions, waves, progression, sanity, co-op, networking, companions, economy, shop, achievements, saves, cloud, settings, menus, content and animations. Visuals are checked with automatic screenshots from the terminal.

### Performance

Windows 11, RTX 3070 Ti, 1920 × 1080, Forward+, no vsync:

| Test | Average | 1 % low |
|---|---|---|
| Normal game: 75 enemies and 500 bullets, on any of the 15 levels | 107-119 FPS | 60-118 FPS |
| Stress test: 150 enemies and 1,000 bullets, one player | 82-90 FPS | 53 FPS |
| Stress test: 150 enemies and 1,000 bullets, four players | 65-69 FPS | 37-41 FPS |
| Network: four PCs with 75 live enemies | ~19 kB/s per guest | 0.46 ms of networking per frame |

Details in [`docs/RENDIMIENTO.md`](docs/RENDIMIENTO.md) and in the journal.

### Documentation (in Spanish)

- [`docs/GDD.md`](docs/GDD.md): living design document, with every decision.
- [`docs/ROADMAP.md`](docs/ROADMAP.md): phases, milestones, acceptance criteria and status.
- [`docs/ESTADO.md`](docs/ESTADO.md): detailed journal of every milestone and change.
- [`docs/LECCIONES.md`](docs/LECCIONES.md): technical lessons learned.
- [`docs/JUGAR_ONLINE.md`](docs/JUGAR_ONLINE.md) and [`docs/PRUEBA_ONLINE.md`](docs/PRUEBA_ONLINE.md): guide to playing online and checklist for the internet test.
- [`docs/GUARDADO_NUBE.md`](docs/GUARDADO_NUBE.md): guide to cloud saves (in Spanish).
- [`CLAUDE.md`](CLAUDE.md): current status, architecture, pipeline and commands.
- [`docs/PROMPT_juego_lovecraft.md`](docs/PROMPT_juego_lovecraft.md): the original specification, unchanged.

### Images in this README

They come from automatic in-game screenshots: `sh tools/capturas_readme.sh` plays the games with bots and captures menus and models, and `python tools/montar_readme.py` scales them to 960 px, assembles the model, face and icon sheets (reading the same data the game uses) and uses ffmpeg to make the GIF and an MP4 video with sound. It also writes `docs/img/vista_previa.jpg` (1280 × 640), the image GitHub shows when the repository link is shared. The character, companion, weapon, item, level and creature tables come from the game's data: `python tools/tablas_readme.py` rebuilds them in both READMEs (between the `<!-- tabla:… -->` markers), the English one with the same translation the game uses.

## Roadmap

| Phase | Content | Status |
|---|---|---|
| 0 | Documentation and decisions | ✅ Done |
| 1 | Playable prototype: one level, weapons, enemies, progression, sanity and HUD | ✅ Done |
| 2 | Menus, saves and local co-op: save slots, settings, four-player selection, revives, economy, shop, companions, achievements, weather and outfits | ✅ Done |
| 3 | Content pipeline: enemies, weapons, evolutions, levels and arenas as data | ✅ Done |
| 4 | Part 1: Antarctica, five levels and the primordial shoggoth | ✅ Done |
| 5 | Credits card, intro, stories for all 15 levels, expanded shop, Armitage and West | ✅ Done |
| 6 | Part 2: Innsmouth, five levels and Father Dagon | ✅ Done |
| 7 | Part 3: Providence, Louisiana, the Pacific, R'lyeh and Cthulhu | ✅ Done |
| 8 | Polish and release: sound, music, accessibility, 50 weapons and 50 items, rebuilt levels, voxel effects, difficulties, living ambience, turn-based level-ups, new faces | 🔨 In progress: final balancing with real games and the itch.io release remain |
| 9 | Online play: room, selection and networked game, pause and level-ups for everyone, disconnections and rejoining | ✅ Done, pending the internet test |
| 10 | Cloud saves: saves and controls copied to a GitHub gist, conflicts between PCs | ✅ Done, waiting to be switched on (GitHub app) and for the two-PC test |
| 11-14 | Hit feel, death report, endless mode, daily run, photo mode, trailer and part 1 demo | ✅ Done |
| 15 | Death replay, challenges, a new enemy per part and a living bestiary | ✅ Done |
| 16 | Performance (instanced hordes, loading during the story), two evolution branches, Elder Signs, peddler, degrees of madness, new enemies and mid-level bosses, elites with traits, game speed, boss rush, expeditions, fishing, secret characters, trophy room and livelier levels | ✅ Done |
| 17 | Animation and living levels: gestures, celebrations, victory poses, deaths by damage type, reactive scenery and distant events | ✅ Done |
| 18 | Voxel weapon effects with gradients: trails, impacts, casings, arcs, zones and evolution accents | ✅ Done |
| 19 | Performance, effect accessibility, Linux build and crash reports | ✅ Done |
| 20 | Menus, transitions and settings; six new characters: Pickman, Ward, Gilman, Tillinghast, Derby and Kuranes | ✅ Done |
| 21 | Bonds, night events, companion tricks, combos and revelations; part 4 (*Kadath*) and three standalone nights; illustrated endings, ink path, oil portraits, manual and statistics | ✅ Done, part 4's music still to come |
| 22 | Part 4 balance and performance, new achievements, the game in English, the fourth night (*The Music of Erich Zann*), trailer and itch.io page | ✅ Done |
| 23 | Lighter build, small demo, credits up to date; proposed: the first hour, the processor, a fifth night and run codes | 🔨 In progress |

## Rights and credits

- **Setting:** H. P. Lovecraft's stories are in the **public domain** in Spain and the European Union, and all of the game's content comes from them. The game is not affiliated with *Call of Cthulhu* (a trademark of Chaosium) and does not reproduce rules, texts or illustrations from the roleplaying game or from modern adaptations.
- **Engine:** [Godot Engine](https://godotengine.org/) (MIT license).
- **Tests:** [GUT](https://github.com/bitwes/Gut) (MIT license), in `addons/gut/`.
- **Title screen font:** *IM FELL English SC*, by Igino Marini, under the [SIL Open Font License 1.1](resources/fonts/OFL_IMFellEnglishSC.txt).
- **Menu font:** *EB Garamond*, by Georg Duffner and Octavio Pardo, under the [SIL Open Font License 1.1](resources/fonts/OFL_EBGaramond.txt).
- **Sound effects:** [Kenney](https://kenney.nl/) (CC0) and synthesized for the game.
- **Music:** by the author (title screen and first level) and CC0 tracks from [OpenGameArt](https://opengameart.org/) by Eldritch Grim, Juhani Junkala, isaiah658 and others; the full list, with authors and links, is in [`data/musica.json`](data/musica.json).
- **Design, title screen and shop illustrations:** Sergio Sánchez Custodio.
- **Use of AI:** the code, the voxel models (generated by programs) and the texts are developed with [Claude Code](https://claude.com/claude-code) (Anthropic), under the author's direction. The weapon and item icons, the menu ornaments, the investigators' portraits, the illustrated ending of each part and the design references were generated with FLUX (Black Forest Labs), on [Replicate](https://replicate.com/) and locally with ComfyUI.

## License

Mixed license; details in [`LICENCIA.md`](LICENCIA.md).

- **The code** (scripts, shaders, scenes, tools, tests, gameplay data and documentation) is released under the **GNU General Public License v3.0**, full text in [`LICENSE`](LICENSE). You may copy, modify and redistribute it, even commercially, as long as anything you redistribute based on it is also released under GPL-3.0 with its source code.
- **The game's assets** (the art, the author's music, the game's texts and the name *Lovecraft Library: Surviving Cthulhu*) are **all rights reserved**. You may use them to play, build or test the project, but not to reuse them in other projects.
- Third-party components keep their own licenses (see [Rights and credits](#rights-and-credits)).
