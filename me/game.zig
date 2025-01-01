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
    lives: u32,
    pub fn updateBounds(self: *Player) void {
        self.bounds = raylib.Rectangle{
            .x = self.position.x,
            .y = self.position.y,
            .width = self.size.x,
            .height = self.size.y,
        };
    }
};

const BallCollisionWithWallDetection = struct {
    x: enum {
        none,
        left,
        right,
    },
    y: enum {
        none,
        top,
        bottom,
    },
};

const Ball = struct {
    position: raylib.Vector2,
    velocity: raylib.Vector2,
    radius: f32,
    isActive: bool,
    pub fn detectWallCollision(self: *Ball, screenSize: raylib.Vector2) BallCollisionWithWallDetection {
        var result = BallCollisionWithWallDetection{ .x = .none, .y = .none };
        if (self.position.x - self.radius < 0) {
            result.x = .left;
        } else if (self.position.x + self.radius > screenSize.x) {
            result.x = .right;
        }

        if (self.position.y - self.radius < 0) {
            result.y = .top;
        } else if (self.position.y + self.radius > screenSize.y) {
            result.y = .bottom;
        }
        return result;
    }
    pub fn resolveWallCollision(self: *Ball, detectionResult: BallCollisionWithWallDetection, screenSize: raylib.Vector2) void {
        std.debug.assert(detectionResult.y != .bottom); // we should have skipped this code
        if (detectionResult.x != .none) {
            self.velocity.x *= -1;
            if (detectionResult.x == .left) {
                self.position.x = self.radius;
            } else {
                std.debug.assert(detectionResult.x == .right);
                self.position.x = screenSize.x - self.radius;
            }
        }
        if (detectionResult.y == .top) {
            self.*.velocity.y *= -1;
            self.position.y = self.radius;
        }
    }
    pub fn step(self: *Ball, fps: f32) void {
        self.position.x += self.velocity.x / fps;
        self.position.y += self.velocity.y / fps;
    }
    pub fn invertVelocity(self: *Ball) void {
        self.velocity.x *= -1;
        self.velocity.y *= -1;
    }
    pub fn goFaster(self: *Ball) void {
        const speedMultiplier = 1.1;
        self.velocity.x *= speedMultiplier;
        self.velocity.y *= speedMultiplier;
        std.debug.print("{} going faster...{}\n", .{ colCount, self.velocity });
        colCount += 1;
    }

    pub fn calculateNewVelocityAfterPaddleHit(self: *Ball, paddle: *Player) f32 {
        const paddleMidpoint = paddle.position.x + paddle.size.x / 2;
        const distanceFromMidpoint = self.position.x - paddleMidpoint;
        const normalizedDistanceAlongMidpoint = distanceFromMidpoint / paddle.size.x;
        return normalizedDistanceAlongMidpoint * 117;
    }
};

const Brick = struct {
    position: raylib.Vector2,
    size: raylib.Vector2,
    bounds: raylib.Rectangle,
    resistance: i32,
    isActive: bool,
};

const Game = struct {
    framesCounter: u32,
    screen: GameScreen,
    isPaused: bool,
    player: Player,
    ball: Ball,
    bricks: [BRICKS_LINES][BRICKS_PER_LINE]Brick,
};

const MyV = struct {
    x: i8,
};
var colCount: c_int = 0;

pub fn main() void {
    // INIT
    const screenSize: raylib.Vector2 = raylib.Vector2{ .x = 800, .y = 450 };

    raylib.InitWindow(screenSize.x, screenSize.y, "PROJECT: BLOCKS GAME");
    defer raylib.CloseWindow();
    const initial_fps = 24;
    var fps_float: f32 = @floatFromInt(initial_fps);

    const ballRadius = 10;
    const initialPlayerPosition = raylib.Vector2{
        .x = screenSize.x / 2.0,
        .y = screenSize.y * 7.0 / @as(f32, @floatFromInt(8)),
    };
    const initialPlayerSize = raylib.Vector2{
        .x = 100,
        .y = 24,
    };
    var game: Game = Game{
        .framesCounter = 0,
        .screen = .LOGO,
        .isPaused = false,
        .player = Player{
            .position = initialPlayerPosition,
            .velocity = raylib.Vector2{
                .x = 690.0,
                .y = 420.0,
            },
            .size = initialPlayerSize,
            .lives = PLAYER_LIVES,
            .bounds = raylib.Rectangle{
                .x = -1,
                .y = -1,
                .height = -1,
                .width = -1,
            },
        },
        .ball = Ball{
            .radius = ballRadius,
            .position = raylib.Vector2{
                .x = initialPlayerPosition.x + initialPlayerSize.x / 2,
                .y = initialPlayerPosition.y - ballRadius * 2,
            },
            .velocity = raylib.Vector2{
                .x = 69,
                .y = -42.0,
            },
            .isActive = true,
        },
        .bricks = undefined,
    };
    var start: cTime.timespec = undefined;
    _ = cTime.clock_gettime(cTime.CLOCK_MONOTONIC_RAW, &start);

    // init bricks
    const brickWidth = screenSize.x / BRICKS_PER_LINE;
    const brickHeight = 20.0;
    for (&game.bricks, 0..) |*brickRow, r| {
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
                .isActive = true,
                .resistance = 0,
            };
        }
    }

    while (!raylib.WindowShouldClose()) {
        // calculate fps
        {
            var end: cTime.timespec = undefined;
            _ = cTime.clock_gettime(cTime.CLOCK_MONOTONIC_RAW, &end);

            const frame_time_s: f32 = @as(f32, @floatFromInt(end.tv_sec - start.tv_sec)) + @as(f32, @floatFromInt(end.tv_nsec - start.tv_nsec)) / (1e9);
            const fps_calc = 1.0 / frame_time_s;
            fps_float = fps_calc;
            start = end;
        }
        // UPDATE
        {
            switch (game.screen) {
                .LOGO => {
                    if (game.framesCounter > 3 * initial_fps or raylib.IsKeyPressed(raylib.KEY_ENTER)) {
                        game.screen = .TITLE;
                        game.framesCounter = 0;
                    }
                    game.framesCounter += 1;
                },
                .TITLE => {
                    if (raylib.IsKeyPressed(raylib.KEY_ENTER)) game.screen = .GAMEPLAY;
                    game.framesCounter += 1;

                    game.player.lives = PLAYER_LIVES;
                },
                .GAMEPLAY => gameplay: {
                    if (raylib.IsKeyPressed(raylib.KEY_ENTER)) game.screen = .ENDING;
                    // fast-forward: for debugging
                    if (raylib.IsKeyPressed(raylib.KEY_PERIOD)) {
                        game.ball.velocity.x *= 2;
                        game.ball.velocity.y *= 2;
                    }
                    if (raylib.IsKeyPressed(raylib.KEY_P) or raylib.IsKeyPressed(raylib.KEY_SPACE)) game.isPaused = !game.isPaused;
                    if (!game.ball.isActive) {
                        // reset ball after losing
                        game.ball.position = raylib.Vector2{
                            .x = game.player.position.x + game.player.size.x / 2,
                            .y = game.player.position.y - game.player.size.y / 2 - game.ball.radius / 2,
                        };
                        game.ball.velocity = raylib.Vector2{
                            .x = 42.0,
                            .y = -69.0,
                        };
                        game.ball.isActive = true;
                        game.isPaused = true;
                    }
                    if (game.isPaused) {
                        break :gameplay;
                    }

                    game.framesCounter += 1;

                    // input
                    if (raylib.IsKeyDown(raylib.KEY_LEFT)) game.player.position.x -= game.player.velocity.x / fps_float;
                    if (raylib.IsKeyDown(raylib.KEY_RIGHT)) game.player.position.x += game.player.velocity.x / fps_float;
                    if (raylib.IsKeyDown(raylib.KEY_UP)) game.player.position.y -= game.player.velocity.y / fps_float;
                    if (raylib.IsKeyDown(raylib.KEY_DOWN)) game.player.position.y += game.player.velocity.y / fps_float;
                    _ = clampPosition(&game.player.position, game.player.size, screenSize);
                    game.player.updateBounds();

                    // physics
                    // game.ball.position = raylib.Vector2{
                    //     .x = game.ball.position.x + game.ball.velocity.x / fps_float,
                    //     .y = game.ball.position.y + game.ball.velocity.y / fps_float,
                    // };
                    game.ball.step(fps_float);
                    const detectBallCollisionWithWall = game.ball.detectWallCollision(screenSize);
                    const didLose = detectBallCollisionWithWall.y == .bottom;
                    if (didLose) {
                        game.ball.isActive = false;
                        game.player.lives -= 1;
                        if (game.player.lives <= 0) {
                            game.screen = .ENDING;
                        }
                        break :gameplay;
                    }
                    game.ball.resolveWallCollision(detectBallCollisionWithWall, screenSize);

                    if (raylib.CheckCollisionCircleRec(game.ball.position, game.ball.radius, game.player.bounds)) {
                        const newXVelocity = game.ball.calculateNewVelocityAfterPaddleHit(&game.player);
                        game.ball.velocity.x = newXVelocity;
                        game.ball.velocity.y *= -1;
                        game.ball.goFaster();
                        game.ball.step(fps_float);
                    }
                    for (&game.bricks) |*brickRow| {
                        for (brickRow) |*brick| {
                            if (!brick.isActive) continue;
                            if (raylib.CheckCollisionCircleRec(game.ball.position, game.ball.radius, brick.bounds)) {
                                brick.isActive = false;
                                game.ball.velocity.y *= -1;
                                game.ball.goFaster();
                                break;
                            }
                        }
                    }
                },
                .ENDING => {
                    if (raylib.IsKeyPressed(raylib.KEY_ENTER)) game.screen = .TITLE;
                    game.framesCounter += 1;
                },
            }
        }

        // DRAW
        {
            raylib.BeginDrawing();
            defer raylib.EndDrawing();

            raylib.ClearBackground(raylib.RAYWHITE);

            switch (game.screen) {
                .LOGO => {
                    raylib.DrawText("LOGO SCREEN", 20, 20, 40, raylib.LIGHTGRAY);
                    raylib.DrawText("WAIT for 3 SECONDS...", 290, 220, 20, raylib.GRAY);
                },
                .TITLE => {
                    const text = "PRESS ENTER to JUMP to GAMEPLAY SCREEN";
                    const fontSize = 20;
                    raylib.DrawRectangle(0, 0, screenSize.x, screenSize.y, raylib.GREEN);
                    raylib.DrawText("TITLE SCREEN", 20, 20, 40, raylib.DARKGREEN);
                    const textStartPoint: i32 = @intFromFloat(screenSize.x / 2 - @as(f32, @floatFromInt(raylib.MeasureText(text, fontSize))) / 2);
                    if ((game.framesCounter / (initial_fps / 2) % 2) == 0) {
                        raylib.DrawText(text, textStartPoint, 220, fontSize, raylib.DARKGREEN);
                    }
                },
                .GAMEPLAY => {
                    raylib.DrawRectangle(
                        0,
                        0,
                        screenSize.x,
                        screenSize.y,
                        raylib.PURPLE,
                    );
                    raylib.DrawText("GAMEPLAY SCREEN", 20, 20, 40, raylib.MAROON);

                    for (game.bricks, 0..) |brickRow, r| {
                        for (brickRow, 0..) |brick, c| {
                            if (brick.isActive) {
                                const color = if ((r + c) % 2 == 0) raylib.GRAY else raylib.DARKGRAY;
                                raylib.DrawRectangleV(game.bricks[r][c].position, game.bricks[r][c].size, color);
                            }
                        }
                    }

                    raylib.DrawRectangleV(game.player.position, game.player.size, raylib.BLACK);
                    raylib.DrawCircleV(game.ball.position, game.ball.radius, raylib.MAROON);

                    for (0..game.player.lives) |l| {
                        raylib.DrawRectangle(@intCast(20 + 40 * l), screenSize.y - 30, 35, 10, raylib.LIGHTGRAY);
                    }

                    if (game.isPaused) {
                        const paused_text = "GAME PAUSED. PRESS SPACE to RESUME";
                        const fontSize = 20;
                        raylib.DrawText(
                            paused_text,
                            @as(i32, @intFromFloat(screenSize.x / 2)) - @divFloor(raylib.MeasureText(paused_text, fontSize), 2),
                            screenSize.y / 2.0,
                            fontSize,
                            raylib.GRAY,
                        );
                    }
                },
                .ENDING => {
                    const text = "PRESS ENTER to RETURN to TITLE SCREEN";
                    const fontSize = 20;
                    raylib.DrawRectangle(
                        0,
                        0,
                        screenSize.x,
                        screenSize.y,
                        raylib.BLUE,
                    );
                    raylib.DrawText("ENDING SCREEN", 20, 20, 40, raylib.DARKBLUE);
                    const textStartPoint: i32 = @intFromFloat(screenSize.x / 2 - @as(f32, @floatFromInt(raylib.MeasureText(text, fontSize))) / 2);
                    if ((game.framesCounter / (initial_fps / 2) % 2) == 0) {
                        raylib.DrawText(text, textStartPoint, 220, fontSize, raylib.DARKBLUE);
                    }
                },
            }
            raylib.DrawText(raylib.TextFormat("FPS: %.1f", fps_float), 0, 20, 20, raylib.BLACK);
        }
    }
}

fn clampPosition(pos: *raylib.Vector2, size: raylib.Vector2, screenSize: raylib.Vector2) void {
    if (pos.x < 0) {
        pos.x = 0;
    }
    if (pos.x + size.x > screenSize.x) {
        pos.x = screenSize.x - size.x;
    }
    if (pos.y < 0) {
        pos.y = 0;
    }
    if (pos.y + size.y > screenSize.y) {
        pos.y = screenSize.y - size.y;
    }
}
