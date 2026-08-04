EXTERNAL SPRITE OVERRIDES

PNG files here replace the built-in code-drawn sprites.

UNIT NAMING   <KIND>_D<dir>[b].png
              dir 0 = front (moving down)
              dir 1 = side  (facing right, mirrored for left)
              dir 2 = back  (moving up)
              suffix b = walk frame, optional

EXAMPLE       KNIGHT_D0.png  KNIGHT_D1.png  KNIGHT_D2.png
              KNIGHT_D1b.png

KINDS         KNIGHT LANCER ARCHER MAGE CLERIC
              PALADIN DRAGOON SNIPER ARCHMAGE BISHOP
              ORC WOLF BOWMAN SHAMAN HEAVY

TILES         GRASS PATH WATER ROCK TREE FLOWER
              POISON SPRING HILL RUBBLE

Any square pixel size works. Transparent background required.
Missing files fall back to the direction 0 image, then to the
built-in code-drawn sprite.
