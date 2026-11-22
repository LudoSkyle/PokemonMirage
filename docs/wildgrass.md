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
4. **Histoire, sac, sauvegarde, menu, options, titre** : `StoryFlags`,
   `Inventory`, `Items`, `ItemReveal`, `SaveGame`, `SaveMenu`, `SaveSlots`,
   `PauseMenu`, `OptionsMenu`, `TitleScreen` → les services et écrans du moteur,
   habillés par des scènes de Mirage. Les quêtes à étapes de Mirage restent au
   jeu, en outils de la page Game.
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
