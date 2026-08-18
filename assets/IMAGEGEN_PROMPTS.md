# Pitfighter ImageGen prompt set

All card and artifact bitmaps were generated as distinct assets with the
built-in ImageGen tool. The concrete subject for each call came from the card or
artifact `name` and `description` emitted by `tests/asset_manifest.gd`.

## Card template

> Use case: stylized-concept. Asset type: collectible arena card illustration.
> Primary request: {name} — {description}. Scene/backdrop: {faction flavor}; a
> chaotic underground fighter pit with dust bursts and cheering silhouettes.
> Style/medium: polished 2D cartoon arcade-fighter concept art, bold black ink
> outlines, chunky cel shading, saturated colors, oversized props, elastic
> poses, exaggerated goofy anger, silly aggression, cartoonishly violent and
> bloodless slapstick impact. Composition: portrait-friendly centered action
> subject, strong silhouette, dynamic foreshortening, readable at small size,
> safe margins, uncluttered focal point. Constraints: no written words, no
> letters, no numbers, no logo, no watermark, no card frame, no gore, no blood,
> no realistic wounds, no dismemberment.

Faction flavors were volcanic golem magic, dwarven brass clockwork, alien
robotics, campy gothic vampires, deep-sea coral monsters, and electric sky
raiders respectively. Shared cards use rowdy gladiator gear and magical arena
energy.

## Artifact template

> Use case: stylized-concept. Asset type: square persistent artifact icon.
> Primary request: {name} — {description}. Scene/backdrop: a weird magical trophy
> found after a pit victory, mounted metal and glowing energy; a chaotic
> underground fighter pit with dust bursts and cheering silhouettes. Style and
> constraints match the card template. Composition: one centered trophy object
> with an extremely strong silhouette, square icon crop, readable at small size.

Outputs are stored at `assets/cards/<definition_id>.png` and
`assets/artifacts/<artifact_id>.png`. The manifest and coverage test enumerate
86 unique card definitions and 20 unique artifacts.

## Environment texture prompts

`assets/ui/battered_metal_panels.png` was generated with the built-in ImageGen
tool as a seamless, straight-on sheet of dented and scratched post-apocalyptic
steel: subtle welded seams, sparse rivets, faint rust, greasy handprints and
impact dents in a hand-painted cartoon style. The prompt required dark
blue-gray, low-contrast detail with no focal point, text, symbols, characters,
weapons, logos, watermark, perspective, bright highlights or strong shadows so
the texture remains background-like beneath UI labels.

`assets/ui/fighter_pit_background.png` was generated with the built-in ImageGen
tool as an empty cartoon post-apocalyptic underground gladiator ring made from
battered scrap metal and broken concrete, with chain-link scraps, bent spikes,
ropes, crude floodlights, impact marks, smashed helmets and loose cartoon teeth.
The prompt required silly aggressive energy, an open uncluttered center, strong
detail at the edges, safe crops for both the compact banner and expanded pit,
muted orange/cyan lighting, no text, characters, logos, watermark, realistic
gore, severed body parts or excessive blood.
