Welcome to the very basic Dots game!

# Setup

If you are using a standard Debian Linux distribution a few libraries are required. These can be installed as follows: 

```bash 
sudo apt-get install libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev
```

The game requires the ruby gem 'ruby2d' in order to run. This can be installed with the following command:
```
gem install ruby2d
```

# Instructions 
Use the WASD keys to draw lines on the corresponding sides of the square the mouse is currently hovering over.
Q - will quit the game 
R - will reset the game

# Goal 
Once all possible squares have been made on the board, the player with the most squares wins.
