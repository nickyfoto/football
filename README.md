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
- `football_v6.html`: latest version, Blitz Breaker Online (two-player online play, plus solo)
- `index.html`: GitHub Pages entry point that redirects to the latest version

## Playing online (v6)

1. One player clicks **Create Game** and becomes Blue. Send the room code or the copied link to a friend.
2. The other player enters the code and clicks **Join** (or just opens the link) and becomes Red.
3. Blue clicks **Kick Off**.

Whoever has the ball plays offense: run with drag/arrow keys, Space to pass to the most open receiver, 1-3 to pick a receiver, E to hand off. The other player controls one defender (ringed and labelled YOU): move it with drag/arrow keys, and press Q or Space to switch to the defender nearest the ball (before the snap it cycles through all of them).

Players connect directly to each other over WebRTC using [PeerJS](https://peerjs.com/). The public PeerJS server is used only for matchmaking, so there is no game server to run, and the page works on GitHub Pages as-is. Blue's browser runs the game and streams it to Red. Both players need an internet connection.

## Running locally

Open `index.html` in a browser, or open any individual HTML file directly to view a specific version. To try online play on one machine, serve the folder (for example `python3 -m http.server 8765`) and open the game in two browser windows.

## Publishing

This repository is configured for GitHub Pages and publishes from the `main` branch root.
