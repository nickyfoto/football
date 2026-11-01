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
- `football_v7.html`: latest version, Blitz Breaker 2026 (NFL rosters, play-calling, 3D camera; 1P vs AI, 2P coach mode and online play)
- `index.html`: GitHub Pages entry point that redirects to the latest version

## Playing online (v7)

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
