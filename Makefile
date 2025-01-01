build: ./me/game
./me/game: ./me/game.c
	cc -o me/game me/game.c -Wall -std=c2x -D_DEFAULT_SOURCE -Wall -Wextra -Wpedantic -g -D_DEFAULT_SOURCE -I. -I/home/max/workspace/github.com/raysan5/raylib/src -I/home/max/workspace/github.com/raysan5/raylib/src/external/glfw/include -L/home/max/workspace/github.com/raysan5/raylib/src -L/home/max/workspace/github.com/raysan5/raylib/src -lraylib -lm -DPLATFORM_DESKTOP -DPLATFORM_DESKTOP_GLFW


play: ./me/game
	./me/game
