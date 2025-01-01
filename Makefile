build: ./me/game
./me/game: ./me/game.c
	cc -Wall -Wextra -Wpedantic -Werror -I../raylib/src/ -L../ -lraylib -framework IOKit -framework Cocoa me/game.c -o me/game

play: ./me/game
	./me/game
