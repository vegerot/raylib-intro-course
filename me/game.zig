const std = @import("std");
const raylib = @cImport({
    @cInclude("raylib.h");
});
const cTime = @cImport({
    @cInclude("time.h");
});

const PLAYER_LIVES = 5;
const BRICKS_LINES = 5;
const BRICKS_PER_LINE = 20;
const BRICKS_POSITION_Y = 50;

const GameScreen = enum {
    LOGO,
    TITLE,
    GAMEPLAY,
    ENDING,
};

const Player = struct {
    position: raylib.Vector2,
    velocity: raylib.Vector2,
    size: raylib.Vector2,
    bounds: raylib.Rectangle,
    lives: i32,
};

const Ball = struct {
    position: raylib.Vector2,
    velocity: raylib.Vector2,
    radius: f32,
    active: bool,
};

const Brick = struct {
    position: raylib.Vector2,
    size: raylib.Vector2,
    bounds: raylib.Rectangle,
    resistance: i32,
    active: bool,
};

pub fn main() void {
    // INIT
    const screenWidth = 800;
    const screenHeight = 450;

    raylib.InitWindow(screenWidth, screenHeight, "PROJECT: BLOCKS GAME");

    var screen: GameScreen = .LOGO;
    var framesCounter: u32 = 0;
    var start: cTime.timespec = undefined;
    _ = cTime.clock_gettime(cTime.CLOCK_MONOTONIC_RAW, &start);
    const gamePaused: bool = false;

    const player = Player{
        .position = raylib.Vector2{ .x = screenWidth / 2.0, .y = screenHeight * 7.0 / @as(f32, @floatFromInt(8)) },
        .velocity = raylib.Vector2{ .x = 8.0, .y = 0.0 },
        .size = raylib.Vector2{ .x = 100, .y = 24 },
        .lives = PLAYER_LIVES,
        .bounds = raylib.Rectangle{
            .x = 0,
            .y = 0,
            .height = 0,
            .width = 0,
        },
    };
    const ballRadius = 10;
    var ball = Ball{
        .radius = ballRadius,
        .position = raylib.Vector2{ .x = player.position.x + player.size.x / 2, .y = player.position.y - ballRadius * 2 },
        .velocity = raylib.Vector2{ .x = 69.0, .y = -42.0 },
        .active = false,
    };

    // init bricks
    var bricks: [BRICKS_LINES][BRICKS_PER_LINE]Brick = undefined;
    const brickWidth = screenWidth / BRICKS_PER_LINE;
    const brickHeight = 20.0;
    for (&bricks, 0..) |*brickRow, r| {
        for (brickRow, 0..) |*brick, c| {
            const rFloat = @as(f32, @floatFromInt(r));
            const cFloat = @as(f32, @floatFromInt(c));

            brick.* = Brick{
                .size = raylib.Vector2{ .x = brickWidth, .y = 20.0 },
                .position = raylib.Vector2{
                    .x = cFloat * brickWidth,
                    .y = rFloat * brickHeight + BRICKS_POSITION_Y,
                },
                .bounds = raylib.Rectangle{
                    .x = cFloat * brickWidth,
                    .y = rFloat * brickHeight + BRICKS_POSITION_Y,
                    .width = brickWidth,
                    .height = brickHeight,
                },
                .active = true,
                .resistance = 0,
            };
        }
    }

    const fps = 240;
    raylib.SetTargetFPS(fps);

    while (!raylib.WindowShouldClose()) {
        switch (screen) {
            .LOGO => {
                if (framesCounter > 3 * fps or raylib.IsKeyPressed(raylib.KEY_ENTER)) {
                    screen = .TITLE;
                    framesCounter = 0;
                }
                framesCounter += 1;
            },
            .TITLE => {
                if (raylib.IsKeyPressed(raylib.KEY_ENTER)) screen = .GAMEPLAY;
                framesCounter += 1;

                player.lives = PLAYER_LIVES;
            },
            .GAMEPLAY => {
                if (raylib.IsKeyPressed(raylib.KEY_ENTER)) screen = .ENDING;
                if (!gamePaused) {
                    framesCounter += 1;
                }

                const maybeNextPos = raylib.Vector2{ .x = ball.position.x + ball.velocity.x / fps, .y = ball.position.y + ball.velocity.y / fps };
                if (maybeNextPos.x > screenWidth or maybeNextPos.x < 0) ball.velocity.x *= -1.1;
                if (maybeNextPos.y > screenHeight or maybeNextPos.y < 0) ball.velocity.y *= -1.1;
                ball.position.x += ball.velocity.x / fps;
                ball.position.y += ball.velocity.y / fps;
            },
            .ENDING => {
                if (raylib.IsKeyPressed(raylib.KEY_ENTER)) screen = .TITLE;
                framesCounter += 1;
            },
        }

        raylib.BeginDrawing();
        defer raylib.EndDrawing();

        raylib.ClearBackground(raylib.RAYWHITE);

        switch (screen) {
            .LOGO => {
                raylib.DrawText("LOGO SCREEN", 20, 20, 40, raylib.LIGHTGRAY);
                raylib.DrawText("WAIT for 3 SECONDS...", 290, 220, 20, raylib.GRAY);
            },
            .TITLE => {
                const text = "PRESS ENTER to JUMP to GAMEPLAY SCREEN";
                const fontSize = 20;
                raylib.DrawRectangle(0, 0, screenWidth, screenHeight, raylib.GREEN);
                raylib.DrawText("TITLE SCREEN", 20, 20, 40, raylib.DARKGREEN);
                const textStartPoint: c_int = screenWidth / 2 - @divFloor(raylib.MeasureText(text, fontSize), 2);
                if ((framesCounter / (fps / 2) % 2) == 0) {
                    raylib.DrawText(text, textStartPoint, 220, fontSize, raylib.DARKGREEN);
                }
            },
            .GAMEPLAY => {
                const text = "PRESS ENTER to JUMP to ENDING SCREEN";
                const fontSize = 20;
                raylib.DrawRectangle(0, 0, screenWidth, screenHeight, raylib.PURPLE);
                raylib.DrawText("GAMEPLAY SCREEN", 20, 20, 40, raylib.MAROON);
                const textStartPoint = screenWidth / 2 - @divFloor(raylib.MeasureText(text, fontSize), 2);
                raylib.DrawText(text, textStartPoint, 220, fontSize, raylib.MAROON);

                for (bricks, 0..) |brickRow, r| {
                    for (brickRow, 0..) |brick, c| {
                        if (brick.active) {
                            const color = if ((r + c) % 2 == 0) raylib.GRAY else raylib.DARKGRAY;
                            raylib.DrawRectangleV(bricks[r][c].position, bricks[r][c].size, color);
                        }
                    }
                }

                raylib.DrawRectangleV(player.position, player.size, raylib.BLACK);
                raylib.DrawCircleV(ball.position, ball.radius, raylib.MAROON);

                for (0..player.lives) |l| {
                    raylib.DrawRectangle(@intCast(20 + 40 * l), screenHeight - 30, 35, 10, raylib.LIGHTGRAY);
                }

                if (gamePaused) {
                    raylib.DrawText("GAME PAUSED", screenWidth / 2, raylib.MeasureText("GAME PAUSED", 40) / 2, screenHeight / 2 + 60, raylib.GRAY);
                }
            },
            .ENDING => {
                const text = "PRESS ENTER to RETURN to TITLE SCREEN";
                const fontSize = 20;
                raylib.DrawRectangle(0, 0, screenWidth, screenHeight, raylib.BLUE);
                raylib.DrawText("ENDING SCREEN", 20, 20, 40, raylib.DARKBLUE);
                const textStartPoint = screenWidth / 2 - @divFloor(raylib.MeasureText(text, fontSize), 2);
                if ((framesCounter / (fps / 2) % 2) == 0) {
                    raylib.DrawText(text, textStartPoint, 220, fontSize, raylib.DARKBLUE);
                }
            },
        }

        var end: cTime.timespec = undefined;
        _ = cTime.clock_gettime(cTime.CLOCK_MONOTONIC_RAW, &end);

        const frame_time_s: f32 = @as(f32, @floatFromInt(end.tv_sec - start.tv_sec)) + @as(f32, @floatFromInt(end.tv_nsec - start.tv_nsec)) / (1e9);
        const fps_calc = 1.0 / frame_time_s;
        start = end;
        raylib.DrawText(raylib.TextFormat("FPS: %.1f", fps_calc), 0, 20, 20, raylib.BLACK);
    }

    raylib.CloseWindow();
}
