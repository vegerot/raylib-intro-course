build: ./me/game
./me/game: ./me/game.c
	cc -o me/game me/game.c -Wall -std=c2x -D_DEFAULT_SOURCE -Wall -Wextra -Wpedantic -g -D_DEFAULT_SOURCE -I. -I/home/max/workspace/github.com/raysan5/raylib/src -I/home/max/workspace/github.com/raysan5/raylib/src/external  -I/home/max/workspace/github.com/raysan5/raylib/src/external/glfw/include -L. -L/home/max/workspace/github.com/raysan5/raylib/src -L/home/max/workspace/github.com/raysan5/raylib/src -L../raylib/zig-out/lib -lraylib -lGL -lm -lpthread -ldl -lrt -lX11 -latomic -DPLATFORM_DESKTOP -DPLATFORM_DESKTOP_GLFW


play: ./me/game
	./me/game
