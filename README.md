# Suburb Chaos — Devlog

**An 11-year-old's vision, AI-built, dad-supervised.**

---

## What is this?

Suburb Chaos is a native desktop 3D open-world game — think GTA but for kids, set in a cartoon suburban neighborhood. No guns, no death, no dark stuff. Just a kid causing hilarious chaos with paintball guns, wiffle bats, and Home Alone-style traps.

**The team:**
- **Logan (age 11)** — Creative director. He decides what goes in, what the vibe is, and whether it's fun. He has final say on everything.
- **LeLand (age 18)** — Older brother, resident engineering debater. Argued for browser-based (he was right about ease of iteration, wrong about Logan's stubbornness).
- **Dad (Milenko)** — Project manager, tester, prompt engineer, and the one typing at midnight.
- **Claude (AI)** — The code monkey. Writes all the code based on Logan's ideas and Dad's direction.

**The rules:**
- Logan's ideas come first. If he says riding lawnmowers are a vehicle type, riding lawnmowers are a vehicle type.
- We're being transparent that this is AI-generated code. That's the whole point — showing what's possible when a kid with big ideas meets AI that can code.

---

## Tech Stack

- **Godot 4.6** — Native game engine (exported as desktop app)
- **GDScript** — All game logic
- **Kenney.nl Assets** — CC0 free 3D models (suburban buildings, vehicles, trees, fences)
- **Rapier3D + Three.js** — Original browser prototype (retired, served its purpose)

### The Platform Pivot

We actually started as a browser game (single HTML file, Three.js + Rapier physics). Got a working prototype in one session — drifty go-kart, procedural suburb, the works. Then Logan said the magic words:

> "Aren't we limited in a browser?"

LeLand argued for browser (easier to ship, easier to modify). Logan wanted native. Dad broke the tie: **Godot 4**. Logan's side-eye when we picked Godot over raw SDL/OpenGL was legendary.

> Logan: "Ok. -_-"

He wanted to write it in C with OpenGL. He's 11. I respect it.

---

## Milestone 1: The Browser Prototype ✅

**Goal:** Prove the concept works. Get a drifty kart driving around a suburb.

**What we built (single index.html):**
- Three.js + Rapier WASM physics, loaded from CDN
- Procedural 3x3 block suburban neighborhood
- Go-kart with custom grip-factor drift system
- Chase camera, skid marks, HUD
- Knockable mailboxes and trash cans

**Logan's verdict:** "So you're telling me, this was like 5 minutes of work?"

(It was not 5 minutes.)

---

## Milestone 2: Going Native (Godot 4) ✅

**Goal:** Port everything to Godot and make it a real game.

**What changed:**
- Full Godot 4.6 project with proper scene tree
- VehicleBody3D with arcade drift physics
- CharacterBody3D for on-foot movement
- Enter/exit vehicle system (press E/Y)
- Fortnite-style third-person camera (right stick/mouse orbits, left stick moves relative to camera)
- Paintball gun (left click/RT to fire, colorful splats on any surface)
- Xbox controller support throughout

---

## Milestone 3: Kenney Assets + Full Polish ✅

**Goal:** Make it look and feel like a real game, not a prototype.

**Visual upgrade:**
- 21 Kenney suburban building types with proper textures
- Kenney trees, fences, driveways, planters
- Kenney SUV model as the player vehicle
- Procedural sky with gradient (not flat blue)
- SSAO (ambient occlusion), proper shadows, fog
- HUD with drop shadows for readability

**Systems polish:**
- 9 scripts fully cleaned up — all magic numbers moved to centralized Config
- Paintball splats orient to surface normals (stick to walls properly!)
- NPCs react to paintball hits (flash pink, jump, flee)
- Camera raycast prevents clipping through buildings
- World boundaries (invisible walls + visible fence around perimeter)
- Splat memory management (max 50, auto-cleanup)
- Gun disabled while driving (no more RT dual-trigger)

**NPC life:**
- Dads in blue polos + red caps, washing cars near houses
- Moms in pink with sun hats, gardening
- Kids on bikes riding along roads (fast)
- Dogs roaming erratically (brown, low, with tails)
- Walking neighbors strolling sidewalks
- All flee when hit with paintballs

---

## What's Coming Next

The full vision (all Logan-approved, in rough priority order):

1. **Wiffle bat** — melee weapon, cartoon knockback, send NPCs flying
2. **Home Alone traps** — marbles (NPCs slip), paint buckets over doors, banana peels, trip wires. The signature mechanic — world becomes a toy you modify.
3. **More vehicles** — skateboard, bike, scooter, riding lawnmower, mom van, school bus
4. **Angry mom wanted system** — cause enough chaos and minivans come hunting you
5. **Ambient NPC behaviors** — dad actually washing a car, dog chasing squirrel, kid doing tricks
6. **Candy pickups** — ammo refills + health scattered around the neighborhood
7. **Auto-save** — pick up and put down anytime

---

## Design Philosophy

From Logan's original vision:

- **Pick up and put down anytime** — 5 minutes or 45, always feels worthwhile
- **No punishing fail states** — short self-contained missions, everything resets with a laugh
- **World is a toy first, game second** — the neighborhood is something you play WITH, not just exist in
- **Kid-friendly chaos** — paintballs not bullets, candy not drugs, angry moms not cops
- **Wanted level = angry neighborhood moms in minivans** (this was Logan's idea and it's genius)

---

## How to Play

1. Open the Godot project at `godot/`
2. Hit F5 to play

**Keyboard + Mouse:**
| Control | Action |
|---------|--------|
| WASD | Drive / Move |
| Mouse | Look (on foot) |
| Left Click | Shoot paintball |
| Space | Drift (driving) / Jump (on foot) |
| E | Enter/Exit vehicle |
| R | Reset position |
| ESC | Release mouse |

**Xbox Controller:**
| Control | Driving | On Foot |
|---------|---------|---------|
| Left Stick | Steer | Move |
| Right Stick | — | Aim camera |
| RT | Gas | Shoot |
| LT | Brake/Reverse | — |
| A | Drift | Jump |
| Y | Exit vehicle | Enter vehicle |
| B | Reset | Reset |

---

## Fun Stats

- **Session length:** One evening (and counting)
- **Lines of GDScript:** ~1,100 across 9 scripts
- **Kenney assets imported:** 68 models, 105 textures
- **Times Logan said "lmao":** Lost count
- **Times the controls were backwards:** At least 4
- **Times the tires were wrong:** 3 (balls, then sideways, then finally correct)

---

*Built with Claude Code. Directed by an 11-year-old. Supervised by Dad. Debated by an 18-year-old. No AI was harmed in the making of this game (though many virtual mailboxes were).*
