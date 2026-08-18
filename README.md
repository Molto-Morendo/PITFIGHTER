# Pit Fighter


https://www.youtube.com/watch?v=KKTR3KY_VxA
A self-contained Godot 4 faction card battler. Choose one of six doctrines,
build gladiators, deploy faction creations, and carry dramatic upgrades through
an escalating run of arena encounters. Both players begin an encounter at 20
health before run upgrades, artifacts, or encounter scaling are applied.

## Run

Open `project.godot` in Godot 4.3 or newer, run the project, and press **START**
on the title screen. **START** opens faction selection before the first match.

## Factions and runs

Each faction adds exactly ten unique cards and a once-per-round passive to the
classic shared deck. Cinder Coven commands elemental golems; Ironroot Compact
builds dwarven automatons; Velari Collective adapts alien robots; Sanguine Court
weaponizes blood; Tidebound Conclave heals behind coral defenses; and Tempest
Clans chains storm-powered plays.

Combat uses a visible doctrine triangle: **Assault beats Engine, Engine beats
Bulwark, and Bulwark beats Assault**. Advantage increases combat damage by 25%;
disadvantage reduces it by 20%.

A victory offers three random illustrated artifacts. The player chooses one
always-active artifact to carry forward, then banks one upgrade currency for
each computer fighter killed and opens the faction's connected five-node upgrade
tree. Upgrades cost five fighter kills, or about 1.5 encounters at the expected
knockout rate. Artifacts and purchased upgrades persist for the whole
run. Encounters scale enemy health and fighters and rotate rival factions.
Defeat offers an immediate encounter retry or a fresh faction run.

## Controls

- At the start of every turn, cards are drawn automatically until that player
  has eight cards. Before the hand is shown, it is reverse-sorted by card type
  and descending value, placing large stat cards toward the right, before play
  moves directly to training.
- Cards that cannot be played in the current phase are dimmed by 25% and sit
  25 pixels lower in the hand. As cards are played, the remaining hand stays
  centered in its panel.
- Train phase: select any numbered card from 1–10. A **New Fighter** card
  appears beside your stable, and every existing fighter exposes clickable
  attack and defense slots. Put two cards into the New Fighter slots to create
  a fighter, or add any selected stat value to either stat on an existing
  fighter. Each player may train at most two new fighters and apply at
  most two training cards per turn; the existing four-stat-card limit remains.
  If only one New Fighter slot is filled, use the **×** in that card's upper-right
  corner to cancel the unfinished fighter and return the stat card to your hand.
  Weapons, shields, blessings, curses, summons, and faction tactics use their
  normal card-specific rules.
- Attack phase: the hand slides away and the illustrated Fighter Pit expands.
  Every ready fighter starts in the pit; click any fighter you want to hold back,
  then send the remaining team into the arena. All living enemy defenders enter
  automatically, with no blocker assignment step or blocker lines. Both teams rush the
  middle and scuffle. Every 0.5 seconds, each living fighter rolls a die whose
  sides equal its total attack and simultaneously damages the physically closest
  enemy fighter. When only one side remains, each survivor rolls once more and
  deals that damage to the opposing player before the heal phase.
- Heal phase: select a heal card, then a damaged fighter or player portrait.
  Chaste Chase may instead be selected to heal a wounded ally by his attack.
  If you have no available healing action after combat, this phase is skipped.

## Special cards

- **Curse Deathmark** destroys one target fighter.
- **Curse Armageddon** destroys every fighter on both sides; each deck has two.
- Repeated status cards stack on the same fighter. Each Poison stack deals 2
  upkeep damage, while repeated Madness and Berserker effects add another 25%
  trigger chance per stack.
- **Call in the Squad** summons Dirty Dan, Wild Wayne, and Chaste Chase as 3/3
  fighters for five turns. It cannot be played on a turn when a new fighter
  was created, and creating a new fighter is locked after summoning the squad.

The title screen's lower-left **Mute Music** button pauses and resumes both the
intro track and match background music.

The match header includes **Settings** immediately left of **New Match**. Game
speed defaults to **Fast**; **Medium** makes popups, rolls, and animations 75%
longer, while **Slow** makes them 2.5 times as long as Fast. **New Match** opens a
confirmation screen, and Cancel resumes the current encounter exactly where it
was paused.

The human player occupies the left half of the combined status panel and the
computer occupies the right. Their background health bars begin green at full
health and transition toward red as health approaches zero.

At the start of each encounter, both sides visibly roll a six-sided die to
choose the first player, rerolling ties. The winner takes the first turn but
automatically skips the attack phase of that turn.

The included opponent, **This Computer**, is controlled by the game. Computer
card plays are shown moving to their targets before their effects resolve.

Fighter scuffling, simultaneous hit flashes, floating damage,
portrait damage, defeat motion, and victory flourishes are presented by
`systems/combat_animator.gd`. Opposing pit teams stage at opposite rails, rush
the center together on combat lock-in, then reposition every half-second as
closest-target damage rolls land with impact bursts, shake, and defeat launches.
Every unique shared and faction card loads its own
cartoon bitmap from `assets/cards/<definition_id>.png`; artifact icons load from
`assets/artifacts/<artifact_id>.png`. Full rules text is printed on each card.
The compact hand fits the normal eight-card draw without a horizontal scrollbar;
stat cards use an oversized centered number and short card names use the largest
display size that fits their face. Card art is masked to the rounded frame on all
four corners, single-word titles shrink before they can split, and each type badge
has a tight rounded backing plate. The main arena panels use a low-contrast
cartoon battered-metal texture, while the compact and expanded Fighter Pit share
the same illustrated post-apocalyptic arena backdrop.
The computer and human summaries share one divided top panel, leaving more
vertical space for both fighter lanes and the pit. Encounter and round numbers
are enlarged and color-coded. Fight-log game terms are underlined and expose
triple-size explanations on hover, while
fighter tooltips enumerate their stats, equipment, curses, wards, and timers.

## Sound folders

Add `.wav` or `.mp3` files under `sounds/attacking`, `blocking`,
`draw_a_card`, `curse`, `blessing`, `background_music`, `FIGHTBG`, or
`game over`. Named phase cues live in `sounds/oneshot`. Filenames are
ignored; the game randomly chooses from the appropriate folder.
