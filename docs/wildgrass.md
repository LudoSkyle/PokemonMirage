# Pokémon Mirage sur Wildgrass

Le moteur [WildgrassEngine](https://github.com/LudoSkyle/WildgrassEngine) est
branché dans le jeu : sous-module `vendor/WildgrassEngine` (ignoré de Godot par
`vendor/.gdignore`), son addon lié en `addons/wildgrass`, son greffon activé,
son autoload `Wildgrass` chargé avant `Globals`. Le jeu tourne encore sur son
Kotlin : rien n'a basculé.

`addons/jvm` (l'extension Kotlin) n'est pas suivi par git : une nouvelle copie
de travail doit le recopier depuis une autre.

## La migration, dans l'ordre

Le jeu sur le moteur se construit **à côté** du jeu Kotlin : `game/main.tscn`
le lance (`godot --path . res://game/main.tscn`), la scène principale du
projet reste celle du Kotlin. Les cartes servent aux deux : leur racine est un
`WgMap` et chaque `SceneTrigger` a sa jumelle `WgDoor` sous `Exits`. Quand le
jeu sur le moteur fait tout ce que fait le Kotlin, il devient la scène
principale et le Kotlin part d'un coup, avec ses tests. Chaque étape garde les
deux jeux jouables et les tests verts ; `tests/gdunit/wildgrass/` teste le jeu
sur le moteur.

L'affichage du moteur (320 × 240 × 4) est appliqué par `game/main.gd` tant que
le Kotlin garde son `SubViewport` ; il passera dans `config/display.json`.

1. **Le cœur** : cartes, portes, joueur, marche, caméra, affichage.
   - Les 7 cartes passent en `WgMap` (`Entities`, points d'apparition `WgSpawnPoint`,
     `SceneTrigger` → `WgDoor`), le TileSet `level.tres` prend les données du moteur
     (`jump`, `ice`, `footprints`, `reflects`, `front_source`, `rustle`, `encounter`).
   - `player.tscn` devient un `WgWalker` (`WgCharacterSprite`, `WgPlayerInput`,
     `WgCamera`) ; `SceneManager`, `CharacterMovement`, `PlayerInput`,
     `PlayerCamera`, `CharacterAnimation`, `SceneTrigger` partent.
   - Le générateur de cartes (`tools/mapgen/build.py`) écrit des `WgMap`.
   - L'affichage 320 × 240 × 4 passe par la config `display` du moteur.
   *Fait* : les cartes, les portes, le joueur, la caméra, l'affichage.
2. **Dialogues et textes** : `MessageBox`, `ChoiceBox`, `Sign`, `Readable`,
   `StoryText` → le dialogue du moteur, la boîte de Mirage en scène remplaçable
   (`message_box`, son ombre de pixels comprise) ; les balises `@give:`,
   `@reload`… deviennent `[give=…]`, `[reload]`.
   *Fait* : la boîte de Mirage (`game/ui/message_box.tscn` : son cadre fin,
   son ombre de pixels, ses choix encadrés et son curseur), les panneaux, les
   meubles (`game/readable.gd` : texte, horloge, télé, trouvaille) et les
   obstacles, jumeaux sous `Twins` ; les textes traduits page par page par
   `game/page_translation.gd` avec les mêmes `locale/*.po`. Les objets donnés
   viendront avec le sac (étape 4).
3. **Personnages** : `Npc`, `Roadblock` → `WgWalker`, `WgWander`, `WgTalk`,
   `WgRoadblock`.
   *Fait* : chaque PNJ a son jumeau sous `Twins/Characters`, caché et arrêté
   (le Kotlin garde les siens) : un `game/npc.tscn` habillé par
   `game/character_sprite.gd` (la planche de `assets/characters`, ou le fichier
   de l'espèce pour un `pkmn_`), sa parole (`WgTalk`, le nom coloré selon le
   genre), sa promenade (`WgWander`, bornée par une zone ou par un calque comme
   `Background/Grass`) ou sa ronde (`WgPatrol`), sa présence (`WgShowIf`).
   Le crochet `map_built` de `game/main.gd` retire les PNJ Kotlin et met les
   jumeaux sous `World/Entities`. Le passage gardé du nord de l'île est un
   `WgRoadblock` sous `Twins`. Les traces de pas sont venues avec eux : la
   donnée de tuile `sand` s'appelle `footprints`, le nom que lit le moteur
   (le Kotlin aussi), et `config/footprints.json` lui donne la planche de
   Mirage.
4. **Histoire, sac, sauvegarde, menu, options, titre** : `StoryFlags`,
   `Inventory`, `Items`, `ItemReveal`, `SaveGame`, `SaveMenu`, `SaveSlots`,
   `PauseMenu`, `OptionsMenu`, `TitleScreen` → les services et écrans du moteur,
   habillés par des scènes de Mirage. Les quêtes à étapes de Mirage restent au
   jeu, en outils de la page Game.
   *Fait* : les objets, un `items/<id>.tres` chacun (le chemin par défaut du
   moteur, textes en français traduits par les `.po`) ; les trois poches de
   `config/bag.json` ; la présentation d'un objet rare
   (`game/ui/item_reveal.tscn`, son cadre et son fondu) ; le français par défaut
   (`config/language.json`). L'histoire du moteur décide aussi des meubles
   Kotlin qui en dépendent (le socle de la cloche, les archives), et quitter
   une carte par une porte applique son `on_leave` : la quête de la cloche se
   joue d'un bout à l'autre sur le moteur.
   Puis les écrans, chacun la scène Kotlin ramenée à 320 × 240 (le même au
   pixel près, sauf le liseré des lettres) sur l'écran du moteur qu'il
   habille : le sac (`game/ui/bag_screen.tscn`), le menu de pause et les
   options (dans les mots et l'ordre de Mirage, les options du moteur
   remplacées sous les mêmes noms), la sauvegarde (trois emplacements, les
   cartes trouvées par leur nom grâce à `wildgrass/paths/maps`), l'écran titre
   et le choix d'une partie. `game/ui/choice_box.tscn` et `menu_keys.gd`
   (la touche d'un événement) servent à tous. Le moteur n'écrit aucun
   de ses mots : chacun est une clé (`wg.menu.bag`…) que Mirage donne en
   français dans `locale/fr.po` et en anglais dans `locale/en.po`
   (docs/i18n.md) ; la répétition des touches tenues et l'écart des choix
   (`beside_gap`) sont ceux du moteur.
   `game/main.tscn` ouvre le titre ; `title = false` le saute (les tests).
   *Reste* : les sons des menus (étape 6), les outils Debug de Mirage
   (étape 7).
5. **Pokémon** : `Species`, `NationalDex`, `Pokedex`, `RegionalDex`,
   `PokedexMenu`, `WildEncounters` → le moteur, le pack de données lu par sa
   couche Studio.
6. **Son, jour et nuit, météo, vie des cartes, suiveur** : `AudioManager`,
   `DayNight`, `NightLight`, `StreetLamp`, `Weather`, `WeatherLayer`,
   `TallGrass`, `Footprints`, `Reflection`, `Flyer`, `Twinkle`,
   `LocationBanner`, `Follower` → le moteur.
7. **Outils de mise au point** : `PauseMenu` (Debug), `PokedexDebug` → les
   outils du moteur, les quêtes de Mirage dans Game.

Les tests de `tests/gdunit` suivent chaque étape : ceux d'un comportement que le
moteur teste déjà partent, ceux de ce qui est propre à Mirage (ses cartes, sa
quête de la cloche, son générateur) restent, réécrits sur le moteur.

## Ce que le moteur ne fait pas encore

L'état des lieux face au moteur de référence et ce qu'il faut pour lancer un
projet Studio sont dans [wildgrass-etat-des-lieux.md](wildgrass-etat-des-lieux.md).
