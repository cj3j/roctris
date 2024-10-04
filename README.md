# Roctris
Roctris is a minimal clone of a popular video game, created to learn the Roc programming language.

![](roctris.gif)

It has only been compiled and tested on Linux Mint 22 (Ubuntu 24.04)

## Installation 

1. Download and install [Roc](https://github.com/roc-lang/roc), either from source or from the nightly build.
2. Build the host: `roc dev --linker=legacy ./platform/main-build.roc`
3. Build and run Roctris: `roc dev --linker=legacy ./game/roctris.roc`

## Playing

- Spacebar to start the game from the intro screen
- Left/Right arrow keys to move
- Up arrow key to rotate
- Down array key to move down one space
- Spacebar to drop to the bottom
- Q or ctrl+c to quit
