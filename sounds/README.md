# Pit Fighter sound folders

Drop any number of `.wav` or `.mp3` files into the category folders below.
Filenames do not matter. Pit Fighter scans each folder when the game starts and
chooses a random matching file whenever that event occurs.

- `attacking/`
- `blocking/`
- `draw_a_card/`
- `curse/`
- `blessing/`
- `background_music/`
- `PITSTART/` — random cue played at the start of a pit fight
- `FIGHTBG/` — random-start loop at the adjustable `PIT FIGHT VOLUME` level (75% by default), beginning with the `PITSTART/` cue and continuing during the pit phase
- `game over/` — random loss-screen music
- `oneshot/` — named `LEVELUP.mp3` cue for the victory artifact-selection screen

Sound effects use a six-player pool so effects can overlap. Background tracks
play at a lower volume; when a track finishes, another random track is selected.
Every pit hit randomly uses an available sound from `attacking/`, `blocking/`,
or a loose `.wav`/`.mp3` placed directly in `sounds/`.

Restart the game after adding or removing sound files so Godot can import them
and Pit Fighter can rebuild its sound lists.
