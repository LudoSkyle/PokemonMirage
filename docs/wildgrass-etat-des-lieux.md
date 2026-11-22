# Wildgrass : ce qu'il reste à faire

État au 22/11/2026, version `v0.1.0-snapshot` (fonctionnalités 0 à 20).
Tailles : P petit, M moyen, G gros.

## Face au moteur de référence

**Combat** : rien dans Wildgrass ; une rencontre ne fait qu'afficher un message.

| Domaine | Wildgrass | Taille |
|---|---|---|
| Déroulé d'un combat (tours, ordre, fuite, changement, fin) | non | G |
| Combats doubles et triples, avec un allié | non | G |
| IA des adversaires | non | G |
| Effets des capacités : les données Studio en appellent 258 | non | G |
| Talents, objets tenus | non | G |
| Statuts, météo et terrains en combat | non | M |
| Méga-évolution, capacités Z | non | M |
| Interface de combat, transitions | non | G |
| Animations et sons des capacités | non | G |
| Expérience, niveaux, évolution | non | M |
| Capture (`catch()` existe, rien ne l'appelle) | non | M |
| Dresseurs (équipes, argent, classes, musique, IA) | non | M |
| Safari, Nuzlocke | non | P |
| Rencontres sauvages : errants, Arbre à Miel | partiel | P |

**Pokémon**

| Domaine | Wildgrass | Taille |
|---|---|---|
| Un Pokémon du joueur (niveau, nature, sexe, chromatique, IV/EV, bonheur) | non | G |
| Équipe, soin, dons de Pokémon | non | M |
| PC, boîtes | non | M |
| Stats, natures, menthes | non | M |
| Apprentissage des capacités (niveau, CT, maître, rappel) | non | M |
| Œufs, pension, éclosion | non | M |
| Rubans, Panthéon | non | P |

**Objets**

| Domaine | Wildgrass | Taille |
|---|---|---|
| Sac, poches, argent, objets au sol | oui | — |
| Effets hors combat (soins, Super Bonbon, pierres, Repousse, Corde Sortie) : le menu Utiliser existe, aucun effet fourni | partiel | M |
| Objets en combat | non | M |
| CT/CS | non | P |
| Baies qui poussent | non | M |
| Magasins | non | M |
| Objet enregistré sur une touche | non | P |

**Monde**

| Domaine | Wildgrass | Taille |
|---|---|---|
| Surf, vélo, cascade | non | M |
| Capacités de terrain (Coupe, Force, Éclate-Roc, Flash, Vol, cannes) : des événements communs du projet | non | M |
| Événements de carte et leur interpréteur (commandes, interrupteurs, variables, événements communs) | partiel : PNJ, conditions, drapeaux | G |
| Dresseurs qui voient le joueur | non | M |
| Carte de la région, points de vol | non | M |
| Zones : météo forcée, groupes sauvages | partiel | P |
| Caméra scriptée, superpositions, lumières, particules | partiel | M |
| Phases de la lune, saisons | non | P |

**Interface**

| Domaine | Wildgrass | Taille |
|---|---|---|
| Écran d'équipe et résumé | non | M |
| Pokédex : recherche, tri, habitat | partiel | P |
| Carte dresseur, badges | non | P |
| Saisie d'un nom (`ask_number` existe) | partiel | P |
| Crédits, film d'introduction | non | P |
| Options de combat | non | P |

**Systèmes**

| Domaine | Wildgrass | Taille |
|---|---|---|
| Horloge à régler | partiel | P |
| Échanges, GTS, Cadeau Mystère, combats en ligne | non | G |
| Mini-jeux (casino, Voltorbataille, fouille) | non | M chacun |
| Concours | non | G |
| Quêtes, sauvegarde, options | oui | — |

## Lancer le projet Studio d'exemple

Le projet : 22 cartes, 512 événements (742 pages), 41 événements communs,
14 dresseurs. Sa première carte jouable est la 19 « Exterior » ; on y arrive
après un titre, une carte d'animation et une carte d'intro (genre, nom).

Ce qu'il manque, dans l'ordre où ça bloque :

1. **Un lecteur du format binaire `.rxdata`** (M). Sans lui, ni les événements,
   ni le point de départ, ni les passages des tuiles ne s'ouvrent.
2. **Le point de départ** (P) : carte 2 en (16, 17), lu dans `System.rxdata`.
3. **Un importeur de cartes** vers des `WgMap` (M à G) :
   - les trois couches, les planches de 32 px réduites de moitié ;
   - les priorités, les passages ;
   - les tags système traduits en données de tuiles (herbe, rebords, eau…) ;
   - les tuiles animées, la musique, la fréquence des rencontres, les liens.
4. **Un importeur d'événements et un interpréteur** (G, la pièce maîtresse) :
   - les pages, conditions, graphismes, déclencheurs ;
   - les mouvements automatiques ;
   - les commandes jouées une à une. Messages et choix vont au dialogue,
     interrupteurs et variables à l'histoire, routes aux marches, téléports
     aux cartes, sons au son.
5. **Les commandes, par lot** :
   - messages et choix, avec leurs balises (P) ;
   - logique, attente, téléport, son (M) ;
   - routes de déplacement, 37 codes (M) ;
   - images, ton, flash, tremblement (M) : aucun système d'images dans Wildgrass ;
   - saisie du nom (P).
6. **Les appels Ruby des événements** (G, longue traîne) : 2125 lignes,
   352 débuts distincts, dont les 40 premiers couvrent 66 %. Il faudra une table
   des appels connus traduits vers l'API (`give_item`, `set_self_switch`, quêtes,
   suiveur, cris…) et un petit évaluateur d'expressions ; les inconnus seront
   journalisés puis sautés.
7. **Les apparences du joueur** (P à M) : `player_m/f_<état>` selon le genre.
8. **Les systèmes absents** :
   - boutiques ;
   - équipe et Pokémon individuels ;
   - combats sauvages et contre des dresseurs ;
   - PC, pension, baies ;
   - mini-jeux.
9. **Les sons** : six `.wav` du projet ne sont pas en PCM, Godot ne les importe
   pas. Il faudra les convertir à l'import.

**Ce qu'on peut montrer avant les combats** : le titre, l'intro, puis la carte
19, avec son arrivée en bateau, le journal reçu et la quête lancée. On peut
ensuite visiter le Hub, les ascenseurs, la bibliothèque, le studio photo et le
Wifi.

Ce qui reste bloqué :

- par l'équipe : le labo, où l'on reçoit son premier Pokémon ;
- par les combats : la Route 20, le sous-sol, l'arène, la toundra et l'herbe.
