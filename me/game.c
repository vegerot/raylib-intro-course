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

// LESSON 01: Window initialization and screens management
typedef enum GameScreen { LOGO, TITLE, GAMEPLAY, ENDING } GameScreen;

// TODO: Define required structs

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

  // TODO: Define and Initialize game variables

  int const fps = 10;

  SetTargetFPS(fps); // Set desired framerate (frames per second)
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!WindowShouldClose()) // Detect window close button or ESC key
  {
    // Update
    //----------------------------------------------------------------------------------
    switch (screen) {
    case LOGO: {
      // Update LOGO screen data here!

      framesCounter++;

      if (framesCounter > 3*fps) {
        screen = TITLE; // Change to TITLE screen after 3 seconds
        framesCounter = 0;
      }

    } break;
    case TITLE: {
      // Update TITLE screen data here!

      framesCounter++;

      // LESSON 03: Inputs management (keyboard, mouse)
      if (IsKeyPressed(KEY_ENTER))
        screen = GAMEPLAY;

    } break;
    case GAMEPLAY: {
      // Update GAMEPLAY screen data here!

      if (!gamePaused) {
        // TODO: Gameplay logic
          ++framesCounter;
      }

      if (IsKeyPressed(KEY_ENTER))
        screen = ENDING;

    } break;
    case ENDING: {
      // Update END screen data here!

      framesCounter++;

      // LESSON 03: Inputs management (keyboard, mouse)
      if (IsKeyPressed(KEY_ENTER))
        screen = TITLE;

    } break;
    default:
      break;
    }
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    BeginDrawing();

    ClearBackground(RAYWHITE);
    // DrawText(GetFPS(), 0, 0, 14, DARKGRAY);

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
      DrawText(text, screenWidth / 2 - MeasureText(text, fontSize) / 2, 220,
               fontSize, DARKGREEN);

    } break;
    case GAMEPLAY: {
      // TODO: Draw GAMEPLAY screen here!
      char *text = "PRESS ENTER to JUMP to ENDING SCREEN";
      int fontSize = 20;
      DrawRectangle(0, 0, screenWidth, screenHeight, PURPLE);
      DrawText("GAMEPLAY SCREEN", 20, 20, 40, MAROON);
      DrawText(text, screenWidth / 2 - MeasureText(text, fontSize) / 2, 220,
               fontSize, MAROON);

    } break;
    case ENDING: {
      // TODO: Draw ENDING screen here!
      char *text = "PRESS ENTER to RETURN to TITLE SCREEN";
      int fontSize = 20;
      DrawRectangle(0, 0, screenWidth, screenHeight, BLUE);
      DrawText("ENDING SCREEN", 20, 20, 40, DARKBLUE);
      DrawText(text, screenWidth / 2 - MeasureText(text, fontSize) / 2, 220,
               fontSize, DARKBLUE);

    } break;
    default:
      break;
    }

    DrawFPS(0, 0);
    DrawText(TextFormat("FPS 2: %i", GetFPS()), 0, 10, 20, RED);
    struct timespec end;
    clock_gettime(CLOCK_MONOTONIC_RAW, &end);

    float frame_time_s = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9;

    double fps = 1 / frame_time_s;
    start = end;
    DrawText(TextFormat("FPS 3: %.1f", fps), 0, 40, 40, BLACK);

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

