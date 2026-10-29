# Celestial Meadow

A couch dogfight for two to six pilots on one screen. Everyone flies a little
ship around a poster-style arena of planets, asteroids and a space station,
shooting each other until one side is left. Built with Godot 4.7 for a Steam
Machine plugged into the TV, one controller per pilot.

## Controls

Every pilot flies the same way:

| | Controller | Keyboard (pilot 1 only) |
|---|---|---|
| Rotate | D-pad left / right | Left / Right arrows |
| Thrust | RT | Up arrow |
| Shoot | A | Space |
| Pause | Menu (Start) | Escape |

Each controller has its own seat and colour, in the order Godot numbers the
pads:

| Pad | Seat | Colour |
|---|---|---|
| 1 | Pilot 1 | Red |
| 2 | Pilot 2 | Lime |
| 3 | Pilot 3 | Tangerine |
| 4 | Pilot 4 | Marigold |
| 5 | Pilot 5 | Orchid |
| 6 | Pilot 6 | Lagoon |

### Menus

Any pad drives the title, the match setup, the options, pause and results:
**D-pad** or **left stick** to move, **A** to choose, **B** to go back.
**View** opens the options. On the title, **B** or **Menu** asks to quit.

### Match setup

Pick the **Mode**, **Teams** (off or on) and the mode's rule: **Lives** (1-5)
for Last Ship Standing, **Time** (1-5 minutes) for Time Attack. Then **Pick
seats**. It remembers the last match, and opens on Pick seats, so the same
again is just **A**, **A** from the title.

### Who's flying? (the lobby)

Nobody drives a menu for everyone else. Each pilot uses their own pad:

- **A** takes your seat, and **A** again says you're ready.
- **B** backs out: un-ready, then leave the seat.
- **D-pad left / right** changes your team, when the match has teams: Alpha,
  Beta or Gamma. Joining puts you on the smallest side.
- **B** on a pad with no seat goes back to the match setup, but only while
  every seat is empty.

The round launches on its own once at least two sides are seated and everyone
is ready.

### During a round

- **Menu** pauses. The panel shows who paused, and anyone can resume:
  Resume, Restart, Change match or Main Menu.
- Unplugging a pilot's controller pauses the game and asks for it back.
- Alt-tabbing or opening the Steam overlay pauses too.

## Modes

- **Last Ship Standing** - a few lives each (three unless you change it). The
  last ship (or team) flying wins.
- **Time Attack** - endless respawns against the clock (two minutes unless you
  change it). Most kills wins; a tie goes to sudden death.

Asteroids sometimes drop a power-up: a **shield**, **rapid fire** or a
**speed boost**. Teammates' shots pass through each other.

After a round: **Rematch**, **Change match** (back to the match setup, still
seated) or **Main Menu** (the title, starting afresh). Wins are tallied across
rematches until you start a new match.

### Playing solo

Debug builds let one pilot launch against an idle dummy ship. On a release
build, press D-pad **left, right, left, right** on an empty seat's pad in the
lobby to turn the dummy on for the session.

## Building

You need [Godot 4.7.1](https://godotengine.org/download).

```sh
godot --path .                  # play from source
godot --headless -s plug.gd install   # once: fetch gdUnit4 for the tests
tests/run.sh                    # run every test suite headless
```

The `Linux build` workflow exports `CelestialMeadow.x86_64` for every pull
request, and publishes a GitHub Release for every `v*` tag:

```sh
git tag v0.4.0 && git push origin v0.4.0
```

`steamdeck/README.md` covers adding the game to Steam as a non-Steam shortcut
that updates itself from those releases. The library art lives in
`steam/art`.

### Frame-rate readout

**F3** toggles a corner readout: fps, the slowest frame in the last second,
and the milliseconds spent on script, physics and rendering (CPU and GPU).
With no keyboard, add `--perf` to the shortcut's launch options in Steam
(`%command% --perf`) and it starts switched on.
