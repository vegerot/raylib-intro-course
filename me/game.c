/*******************************************************************************************
*
*   PROJECT:        BLOCKS GAME
*   LESSON 01:      raylib intro
*   DESCRIPTION:    Introduction to raylib and the basic videogames life cycle
*
*   COMPILATION (Windows - MinGW):
*       gcc -o $(NAME_PART).exe $(FILE_NAME) -lraylib -lopengl32 -lgdi32 -lwinmm
-Wall -std=c99
*
*   COMPILATION (Linux - GCC):
*       gcc -o $(NAME_PART).exe $(FILE_NAME) -lraylib -lGL -lm -lpthread -ldl
-lrt -lX11
*
*   Example originally created with raylib 2.0, last time updated with
raylib 4.2

*   Example licensed under an unmodified zlib/libpng license, which is an
OSI-certified,
*   BSD-like license that allows static linking with closed source software
*
*   Copyright (c) 2017-2022 Ramon Santamaria (@raysan5)
*
********************************************************************************************/

#include <time.h>

#include "raylib.h"

//----------------------------------------------------------------------------------
// Types and Structures Definition
//----------------------------------------------------------------------------------

#define PLAYER_LIVES 5
#define BRICKS_LINES 5
#define BRICKS_PER_LINE 20

#define BRICKS_POSITION_Y 50

// LESSON 01: Window initialization and screens management
typedef enum GameScreen { LOGO, TITLE, GAMEPLAY, ENDING } GameScreen;

typedef struct {
  Vector2 position;
  Vector2 velocity;
  Vector2 size;
  Rectangle bounds;
  int lives;
} Player;

typedef struct {
  Vector2 position;
  Vector2 velocity;
  float radius;
  bool active;
} Ball;

typedef struct {
  Vector2 position;
  Vector2 size;
  Rectangle bounds;
  int resistance;
  bool active;
} Brick;

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
int main(void) {
  // Initialization
  //--------------------------------------------------------------------------------------
  const int screenWidth = 800;
  const int screenHeight = 450;

  // LESSON 01: Window initialization and screens management
  InitWindow(screenWidth, screenHeight, "PROJECT: BLOCKS GAME");

  // NOTE: Load resources (textures, fonts, audio) after Window initialization

  // Game required variables
  GameScreen screen = LOGO; // Current game screen state

  int framesCounter = 0; // General purpose frames counter
  struct timespec start;
  clock_gettime(CLOCK_MONOTONIC_RAW, &start);
  bool gamePaused = false; // Game paused state toggle

  Player player = {
      .position = {screenWidth / 2.0, screenHeight * 7.0 / 8},
      .velocity = (Vector2){8.0f, 0.0f},
      .size = {100, 24},
      .lives = PLAYER_LIVES,
  };
  const int ballRadius = 10;
  Ball ball = {.radius = ballRadius,
               .position =
                   {
                       .x = player.position.x + player.size.x / 2,
                       .y = player.position.y - ballRadius * 2,
                   },
               .velocity = {69.0f, -42.0f},
               .active = false

  };

  Brick bricks[BRICKS_LINES][BRICKS_PER_LINE] = {0};
  const float brickWidth = (float)screenWidth / BRICKS_PER_LINE;
  const float brickHeight = 20;

  // initialize bricks
  for (int r = 0; r < BRICKS_LINES; ++r) {
    for (int c = 0; c < BRICKS_PER_LINE; ++c) {
      bricks[r][c] = (Brick){
          .size = {brickWidth, 20},
          .position = {c * brickWidth, r * brickHeight + BRICKS_POSITION_Y},
          .bounds =
              (Rectangle){
                  c * brickWidth,
                  r * brickHeight + BRICKS_POSITION_Y,
                  .width = brickWidth,
                  .height = brickHeight,
              },
          .active = true};
    }
  }

  int const fps = 240;
  SetTargetFPS(fps); // Set desired framerate (frames per second)
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!WindowShouldClose()) // Detect window close button or ESC key
  {
    // Update
    //----------------------------------------------------------------------------------
    switch (screen) {
    case LOGO: {
      if (framesCounter > 3 * fps || IsKeyPressed(KEY_ENTER)) {
        screen = TITLE; // Change to TITLE screen after 3 seconds
        framesCounter = 0;
      }

      // Update LOGO screen data here!
      framesCounter++;

    } break;
    case TITLE: {
      if (IsKeyPressed(KEY_ENTER))
        screen = GAMEPLAY;
      // Update TITLE screen data here!

      framesCounter++;

      // LESSON 03: Inputs management (keyboard, mouse)

    } break;
    case GAMEPLAY: {
      if (IsKeyPressed(KEY_ENTER))
        screen = ENDING;
      if (!gamePaused) {
        // TODO: Gameplay logic
        ++framesCounter;
      }
      // Draw GAMEPLAY screen data here!

      Vector2 maybeNextPos = {ball.position.x + ball.velocity.x / fps,
                              ball.position.y + ball.velocity.y / fps};
      // NOTE: We're multiplying by 1.1 so it gets a little faster every time
      if (maybeNextPos.x > screenWidth || maybeNextPos.x < 0)
        ball.velocity.x *= -1.1;
      if (maybeNextPos.y > screenHeight || maybeNextPos.y < 0)
        ball.velocity.y *= -1.1;
      ball.position.x += ball.velocity.x / fps;
      ball.position.y += ball.velocity.y / fps;

    } break;
    case ENDING: {
      if (IsKeyPressed(KEY_ENTER))
        screen = TITLE;
      // Update END screen data here!

      framesCounter++;

      // LESSON 03: Inputs management (keyboard, mouse)

    } break;
    default:
      break;
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    BeginDrawing();
    {

      ClearBackground(RAYWHITE);

      switch (screen) {
      case LOGO: {
        // TODO: Draw LOGO screen here!
        DrawText("LOGO SCREEN", 20, 20, 40, LIGHTGRAY);
        DrawText("WAIT for 3 SECONDS...", 290, 220, 20, GRAY);

      } break;
      case TITLE: {
        // TODO: Draw TITLE screen here!
        char const *text = "PRESS ENTER to JUMP to GAMEPLAY SCREEN";
        int fontSize = 20;
        DrawRectangle(0, 0, screenWidth, screenHeight, GREEN);
        DrawText("TITLE SCREEN", 20, 20, 40, DARKGREEN);
        if ((framesCounter / (fps / 2) % 2 == 0)) {
          DrawText(text, screenWidth / 2 - MeasureText(text, fontSize) / 2, 220,
                   fontSize, DARKGREEN);
        }

      } break;
      case GAMEPLAY: {
        // TODO: Draw GAMEPLAY screen here!

        char *text = "PRESS ENTER to JUMP to ENDING SCREEN";
        int fontSize = 20;
        DrawRectangle(0, 0, screenWidth, screenHeight, PURPLE);
        DrawText("GAMEPLAY SCREEN", 20, 20, 40, MAROON);
        DrawText(text, screenWidth / 2 - MeasureText(text, fontSize) / 2, 220,
                 fontSize, MAROON);

        // LESSON 02: Draw basic shapes (circle, rectangle)

        // draw bricks
        for (int r = 0; r < BRICKS_LINES; ++r) {
          for (int c = 0; c < BRICKS_PER_LINE; ++c) {
            if (bricks[r][c].active) {
              Color color = (r + c) % 2 == 0 ? GRAY : DARKGRAY;
              DrawRectangleV(bricks[r][c].position, bricks[r][c].size, color);
            }
          }
        }

        DrawRectangle(player.position.x, player.position.y, player.size.x,
                      player.size.y, BLACK);
        DrawCircleV(ball.position, ball.radius, MAROON);

        // Draw GUI; player lives
        for (int l = 0; l < player.lives; ++l)
          DrawRectangle(20 + 40 * l, screenHeight - 30, 35, 10, LIGHTGRAY);

        if (gamePaused)
          DrawText("GAME PAUSED", screenWidth / 2,
                   MeasureText("GAME PAUSED", 40) / 2, screenHeight / 2 + 60,
                   GRAY);

      } break;
      case ENDING: {
        // TODO: Draw ENDING screen here!
        char *text = "PRESS ENTER to RETURN to TITLE SCREEN";
        int fontSize = 20;
        DrawRectangle(0, 0, screenWidth, screenHeight, BLUE);
        DrawText("ENDING SCREEN", 20, 20, 40, DARKBLUE);
        if ((framesCounter / (fps / 2)) % 2 == 0)
          DrawText(text, screenWidth / 2 - MeasureText(text, fontSize) / 2, 220,
                   fontSize, DARKBLUE);

      } break;
      default:
        break;
      }

      // DrawFPS(0, 0);
      // DrawText(TextFormat("FPS 2: %i", GetFPS()), 0, 10, 20, RED);
      struct timespec end;
      clock_gettime(CLOCK_MONOTONIC_RAW, &end);

      float frame_time_s =
          (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9;

      double fps = 1 / frame_time_s;
      start = end;
      DrawText(TextFormat("FPS: %.1f", fps), 0, 20, 20, BLACK);
    }

    EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------

  // NOTE: Unload any loaded resources (texture, fonts, audio)

  CloseWindow(); // Close window and OpenGL context
  //--------------------------------------------------------------------------------------

  return 0;
}
