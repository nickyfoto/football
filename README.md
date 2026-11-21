# Blitz Breaker / Gridiron Rush

A small browser-based arcade football project built as a series of standalone HTML prototypes.

Live site:

[https://nickyfoto.github.io/football/](https://nickyfoto.github.io/football/)

## Project files

- `football.html`: original Gridiron Rush prototype
- `football_v2.html`: second iteration
- `football_v3.html`: third iteration
- `football_v4.html`: fourth iteration, titled Blitz Breaker
- `football_v5.html`: fifth iteration (single player)
- `football_v6.html`: Blitz Breaker Online (Blue vs Red, two-player online play, plus solo)
- `football_v7.html`: Blitz Breaker 2026 (NFL rosters, play-calling, 3D camera; 1P vs AI, 2P coach mode and online play)
- `football_v8.html`: latest version, Blitz Breaker 2026 Sim Edition (all 32 NFL teams, realistic football simulation, see below)
- `index.html`: GitHub Pages entry point that redirects to the latest version

## What's realistic in v8

- **Full 11-on-11 every snap.** All 22 players stay on the field for the whole play: receivers keep blocking after a catch, the QB stays put after a handoff, and an interception or punt return turns the defense into blockers mid-play.
- **Momentum.** Players speed up, plant and cut instead of moving at a fixed speed. Top speed and acceleration depend on position, with a few stars faster than normal.
- **Real routes and passing.** Slants, outs, curls, digs, posts, seams and drags are run as real route trees. The QB throws to where the route is going; the ball flies in an arc, is less accurate deep and under pressure, and catches can be contested, dropped or intercepted.
- **Playbooks.** 12 offensive plays (Inside Zone, Outside Toss, Power, HB Draw, Quick Slants, Curl Flats, Four Verts, PA Post, Drags & Dig, Smash, RB Screen, Y Cross) and 8 defensive calls (Cover 1, Tampa 2, Cover 3, Cover 4, Fire Zone, Six-Man Blitz, QB Spy, Run Stuff).
- **Blocking and coverage.** Linemen set a pocket and engage rushers; pass rushers win over time. Man and zone coverages play their assignments (zone defenders match routes in their area, deep defenders take the deepest threat), and play-action pulls the second level up.
- **Tackling.** Pursuit angles, broken tackles, gang tackles, yards after contact, fumbles (~1%, more on sacks), sacks, safeties and out-of-bounds.
- **Rules and clock.** Four quarters (5, 8, 10 or 15 minutes; 15 is the default and NFL length), halftime, two-minute warning, 2025 overtime (both teams get the ball), three timeouts per half, and a 40-second play clock with delay-of-game. The game clock keeps NFL pace: about 33 seconds run off between in-bounds plays (16 in a hurry-up, more when a leading team milks the clock), and it stops for incompletions, scores and changes of possession. Shorter quarters therefore mean proportionally lower scores.
- **Kicking.** 2025 dynamic kickoff (touchbacks to the 35), punts with fair catches, coverage and returns, distance-based field goals and 33-yard extra points.
- **Season mode.** Pick any team and play a full NFL season: a 17-game schedule built like the NFL's (division rivals twice, rotating divisions in your conference and the other one), AFC/NFC division standings, 7-team playoffs per conference, and the Super Bowl. Play or sim each game; other games are simulated from team strength. The season hub also shows league leaders (passing, rushing, receiving, touchdowns, sacks, interceptions, tackles) and your team's player stats. Road games are in the other team's stadium, playoff games go to extra overtimes until there's a winner, and the season saves in your browser so you can resume it.
- **Quick games** against the CPU, in 2P coach mode, or online with a friend.
- **Player ratings** (45-99) for all ~1,800 players: elite QBs throw tighter and read better, good hands win contested catches, linemen win or lose their matchups, great backs break tackles, sure tacklers bring them down, and kickers/punters differ in range. Ratings show on the team-select cards.
- **CPU vs CPU**: pick a home and an away team and watch the computer play both sides (play calls, timeouts, challenges and all), at 1x, 2x or 4x speed ([X]).
- **All 32 teams** with current 2026 starters (taken from team depth charts after the Nov 10, 2026 trade deadline, with everyone healthy — starters on injured reserve are back in the lineup), nickel defense with each team's strong safety (the SAM linebacker subs in on run calls), and full depth charts built from the active roster (healthy reserve-list players included, no practice squad): backups rotate in as starters tire (running backs and defensive linemen rotate, the slot receiver takes breathers), everyone gets fresh legs at halftime, and the bench comes in when a game is decided, team colors and home/away uniforms. In 1P the CPU defense gets quicker and tighter in coverage with the CPU skill setting (Rookie / Pro / All-Pro).
- **Decisions.** You choose on 4th down (go for it / punt / field goal) and after touchdowns (kick / go for 2); the CPU uses a situational chart.
- **Broadcast look.** Scorebug with timeouts and play clock, a play-by-play ticker, a box score at the final whistle, a fully marked field, stands and goal posts, and uniformed players (home team in color, away in white).

Controls: arrows or drag to move. QB: A/S/D/W/E throws to WR1/TE/WR2/SLOT/RB, Space throws to the most open receiver. Ball carrier: Space jukes; with no input the runner runs on his own. Defense: tap a defender or press Q to take the one nearest the ball; with no input he plays his assignment. T calls a timeout before the snap.

## Playing online (v7 and v8)

1. Both players choose **Online Room Code**.
2. One player clicks **Create Code** and sends the 4-letter code, or the link from **Copy Invite Link**, to a friend.
3. The other player enters the code and clicks **Join**, or just opens the link.
4. Each player picks their own team, then the player who created the room clicks **Kick Off**.

Whoever has the ball plays offense: pick a play, snap, run with drag/arrow keys, pass with A/S/D/W (or Space for the most open receiver), and hand off with E. The other player calls the coverage and controls one defender (yellow ring): tap any defender to take it over, or press Q to jump to the one nearest the ball. The offense can snap once the defense has called its coverage, or after 5 seconds.

v6 works the same way with Blue vs Red teams and a 5-character code.

Players connect directly to each other over WebRTC using [PeerJS](https://peerjs.com/). The public PeerJS server is used only for matchmaking, so there is no game server to run, and the page works on GitHub Pages as-is. The browser that created the room runs the game and streams it to the other player. Both players need an internet connection.

## Running locally

Open `index.html` in a browser, or open any individual HTML file directly to view a specific version. To try online play on one machine, serve the folder (for example `python3 -m http.server 8765`) and open the game in two browser windows.

## Publishing

This repository is configured for GitHub Pages and publishes from the `main` branch root.
