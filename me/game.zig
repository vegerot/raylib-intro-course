const std = @import("std");
const builtin = @import("builtin");

const raylib = @cImport({
    @cInclude("raylib.h");
});

const is_posix = switch (builtin.os.tag) {
    .windows, .uefi, .wasi => false,
    else => true,
};

const GameTime = if (is_posix) struct {
    const cTime = @cImport({
        @cInclude("time.h");
    });
    const Self = @This();
    pub fn init() Self {
        var self: Self = undefined;
        self._start_of_game = undefined;
        std.debug.assert(0 == cTime.clock_gettime(cTime.CLOCK_MONOTONIC, &self._start_of_game));
        self._start_of_frame = self._start_of_game;
        return self;
    }
    pub fn GetTimeFromGameStart(self: *Self) f32 {
        var end_of_frame: cTime.timespec = undefined;
        std.debug.assert(0 == cTime.clock_gettime(cTime.CLOCK_MONOTONIC, &end_of_frame));
        return (@as(f32, @floatFromInt(end_of_frame.tv_sec)) - @as(f32, @floatFromInt(self._start_of_game.tv_sec))) + (@as(f32, @floatFromInt(end_of_frame.tv_nsec)) - @as(f32, @floatFromInt(self._start_of_game.tv_nsec))) / 1_000_000_000.0;
    }
    pub fn GetFrameTime(self: *Self) f32 {
        var end_of_frame: cTime.timespec = undefined;
        std.debug.assert(0 == cTime.clock_gettime(cTime.CLOCK_MONOTONIC, &end_of_frame));
        const elapsed_seconds = @as(f32, @floatFromInt(end_of_frame.tv_sec)) - @as(f32, @floatFromInt(self._start_of_frame.tv_sec));
        const elapsed_nanos = @as(f32, @floatFromInt(end_of_frame.tv_nsec)) - @as(f32, @floatFromInt(self._start_of_frame.tv_nsec));
        self._start_of_frame = end_of_frame;
        return elapsed_seconds + elapsed_nanos / 1_000_000_000.0;
    }
    _start_of_game: cTime.timespec,
    _start_of_frame: cTime.timespec,
} else struct {
    const cWindows = @cImport({
        @cInclude("Windows.h");
    });
    const Self = @This();
    pub fn init() Self {
        var self: Self = undefined;
        std.debug.assert(cWindows.QueryPerformanceFrequency(&self._frequency) != 0);
        std.debug.assert(cWindows.QueryPerformanceCounter(&self._start_of_game) != 0);
        self._start_of_frame = self._start_of_game;
        return self;
    }
    pub fn GetTimeFromGameStart(self: *Self) f32 {
        var end_of_frame: cWindows.LARGE_INTEGER = undefined;
        std.debug.assert(cWindows.QueryPerformanceCounter(&end_of_frame) != 0);
        return (@as(f32, @floatFromInt(end_of_frame.QuadPart)) - @as(f32, @floatFromInt(self._start_of_game.QuadPart))) / @as(f32, @floatFromInt(self._frequency.QuadPart));
    }
    pub fn GetFrameTime(self: *Self) f32 {
        var end_of_frame: cWindows.LARGE_INTEGER = undefined;
        std.debug.assert(cWindows.QueryPerformanceCounter(&end_of_frame) != 0);
        const elapsed_ticks = end_of_frame.QuadPart - self._start_of_frame.QuadPart;
        const frame_time_s = @as(f32, @floatFromInt(elapsed_ticks)) / @as(f32, @floatFromInt(self._frequency.QuadPart));
        self._start_of_frame = end_of_frame;
        return frame_time_s;
    }
    _start_of_game: cWindows.LARGE_INTEGER,
    _start_of_frame: cWindows.LARGE_INTEGER,
    _frequency: cWindows.LARGE_INTEGER,
};

const PLAYER_LIVES = 5;
const BRICKS_LINES = 5;
const BRICKS_PER_LINE = 20;
const BRICKS_POSITION_Y = 50;

const GameScreen = enum {
    ERROR,
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
    previousBallPosition: @typeInfo(@This()).position,
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

    pub fn detectPaddleCollision(self: *Ball, previousBallPosition: raylib.Vector2, paddle: Player) bool {
        const ballPositionSmear = raylib.Rectangle{
            .x = previousBallPosition.x,
            .y = previousBallPosition.y,
            .width = self.position.x - previousBallPosition.x,
            .height = self.position.y - previousBallPosition.y,
        };
        const hitPaddleBetweenThisFrameAndLast = raylib.CheckCollisionRecs(ballPositionSmear, paddle.bounds);

        const isHittingPaddle = raylib.CheckCollisionCircleRec(self.position, self.radius, paddle.bounds);
        return hitPaddleBetweenThisFrameAndLast or isHittingPaddle;
    }

    pub fn detectBrickCollision(self: *Ball, previousBallPosition: raylib.Vector2, brick: *Brick) bool {
        const ballPositionSmear = raylib.Rectangle{
            .x = previousBallPosition.x,
            .y = previousBallPosition.y,
            .width = self.position.x - previousBallPosition.x,
            .height = self.position.y - previousBallPosition.y,
        };
        const hitBrickBetweenThisFrameAndLast = raylib.CheckCollisionRecs(ballPositionSmear, brick.bounds);

        const isHittingBrick = raylib.CheckCollisionCircleRec(self.position, self.radius, brick.bounds);
        if (isHittingBrick) return true;
        return hitBrickBetweenThisFrameAndLast or isHittingBrick;
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
    isMuted: bool,
    shouldFlashText: bool,
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
    var screenSize: raylib.Vector2 = .{ .x = 800, .y = 450 };

    raylib.InitWindow(@intFromFloat(screenSize.x), @intFromFloat(screenSize.y), "PROJECT: BLOCKS GAME");
    defer raylib.CloseWindow();
    raylib.SetWindowState(raylib.FLAG_WINDOW_RESIZABLE);

    const initial_fps = raylib.GetMonitorRefreshRate(raylib.GetCurrentMonitor());
    var fps_float: f32 = @floatFromInt(initial_fps);
    raylib.SetTargetFPS(initial_fps);

    const textures: struct {
        logo: raylib.Texture2D,
        ball: raylib.Texture2D,
        paddle: raylib.Texture2D,
        brick: raylib.Texture2D,
    } = .{
        .logo = raylib.LoadTexture("lessons/resources/raylib_logo.png"),
        .ball = raylib.LoadTexture("lessons/resources/ball.png"),
        .paddle = raylib.LoadTexture("lessons/resources/paddle.png"),
        .brick = raylib.LoadTexture("lessons/resources/brick.png"),
    };

    const font = raylib.LoadFont("lessons/resources/setback.png");
    defer raylib.UnloadFont(font);

    raylib.InitAudioDevice();

    const sounds: struct {
        start: raylib.Sound,
        bounce: raylib.Sound,
        explode: raylib.Sound,
    } = .{
        .start = raylib.LoadSound("lessons/resources/start.wav"),
        .bounce = raylib.LoadSound("lessons/resources/bounce.wav"),
        .explode = raylib.LoadSound("lessons/resources/explosion.wav"),
    };

    const music: raylib.Music = raylib.LoadMusicStream("lessons/resources/music.mp3");
    defer raylib.UnloadMusicStream(music);

    var shouldShowHitboxes = false;
    var shouldShowFps = true;
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
        .isMuted = false,
        .shouldFlashText = true,
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
    var fpsMeasurer: GameTime = GameTime.init();

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

    raylib.PlayMusicStream(music);
    while (!raylib.WindowShouldClose()) {
        var shouldPlaySound: struct {
            music: bool,
            start: bool,
            bounce: bool,
            explode: bool,
        } = .{
            .music = true,
            .start = false,
            .bounce = false,
            .explode = false,
        };

        // UPDATE
        {
            // calculate fps
            // technically this should be at the end of the frame, but it's close enough

            const frame_time_s = fpsMeasurer.GetFrameTime();
            if (std.math.isInf(frame_time_s) and game.framesCounter < 69) {}
            fps_float = 1.0 / frame_time_s;
            const elapsed_seconds = fpsMeasurer.GetTimeFromGameStart();
            game.shouldFlashText = @rem(@as(i16, @intFromFloat(elapsed_seconds)), 2) == 0;

            // update screen size
            screenSize = .{
                .x = @floatFromInt(raylib.GetScreenWidth()),
                .y = @floatFromInt(raylib.GetScreenHeight()),
            };

            if (raylib.IsKeyPressed('M')) game.isMuted = !game.isMuted;
            switch (game.screen) {
                .ERROR => {
                    unreachable;
                },
                .LOGO => {
                    if (game.framesCounter > 3 * @as(i32, @intFromFloat(fps_float)) or raylib.IsKeyPressed(raylib.KEY_ENTER) or raylib.IsMouseButtonDown(raylib.MOUSE_BUTTON_LEFT)) {
                        game.screen = .TITLE;
                        game.framesCounter = 0;
                    }
                    game.framesCounter += 1;
                },
                .TITLE => {
                    if (raylib.IsKeyPressed(raylib.KEY_ENTER) or raylib.IsMouseButtonDown(raylib.MOUSE_BUTTON_LEFT)) {
                        game.screen = .GAMEPLAY;
                        shouldPlaySound.start = true;
                    }
                    game.framesCounter += 1;

                    game.player.lives = PLAYER_LIVES;
                },
                .GAMEPLAY => gameplay: {
                    // meta input
                    if (raylib.IsKeyPressed(raylib.KEY_ENTER)) game.screen = .ENDING;
                    //// fast-forward: for debugging
                    if (raylib.IsKeyPressed(raylib.KEY_PERIOD)) {
                        game.ball.velocity.x *= 2;
                        game.ball.velocity.y *= 2;
                    }
                    if (raylib.IsKeyPressed(raylib.KEY_P) or raylib.IsKeyPressed(raylib.KEY_SPACE)) game.isPaused = !game.isPaused;
                    if (raylib.IsMouseButtonDown(raylib.MOUSE_BUTTON_LEFT)) {
                        game.isPaused = false;
                    }
                    if (raylib.IsKeyPressed('H')) shouldShowHitboxes = !shouldShowHitboxes;
                    if (raylib.IsKeyPressed('F')) shouldShowFps = !shouldShowFps;

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
                        break :gameplay;
                    }
                    if (game.isPaused) {
                        break :gameplay;
                    }

                    game.framesCounter += 1;

                    // movement input
                    if (raylib.IsKeyDown(raylib.KEY_LEFT) or raylib.IsKeyDown('A')) game.player.position.x -= game.player.velocity.x / fps_float;
                    if (raylib.IsKeyDown(raylib.KEY_RIGHT) or raylib.IsKeyDown('D')) game.player.position.x += game.player.velocity.x / fps_float;
                    if (raylib.IsKeyDown(raylib.KEY_UP) or raylib.IsKeyDown('W')) game.player.position.y -= game.player.velocity.y / fps_float;
                    if (raylib.IsKeyDown(raylib.KEY_DOWN) or raylib.IsKeyDown('S')) game.player.position.y += game.player.velocity.y / fps_float;
                    if (raylib.IsMouseButtonDown(raylib.MOUSE_BUTTON_LEFT)) game.player.position = .{
                        .x = @as(f32, @floatFromInt(raylib.GetMouseX())) - game.player.size.x / 2,
                        .y = @as(f32, @floatFromInt(raylib.GetMouseY())) - game.player.size.y / 2,
                    };

                    const mouseMove = raylib.GetMouseDelta();
                    game.player.position.x += mouseMove.x;
                    game.player.position.y += mouseMove.y;
                    clampPosition(&game.player.position, game.player.size, screenSize);
                    game.player.updateBounds();

                    // physics
                    const previousBallPosition = game.ball.position;
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

                    if (game.ball.detectPaddleCollision(previousBallPosition, game.player)) {
                        const newXVelocity = game.ball.calculateNewVelocityAfterPaddleHit(&game.player);
                        game.ball.velocity.x = newXVelocity;
                        game.ball.velocity.y *= -1;
                        game.ball.step(fps_float);

                        shouldPlaySound.bounce = true;
                    }
                    for (&game.bricks) |*brickRow| {
                        for (brickRow) |*brick| {
                            if (!brick.isActive) continue;
                            if (game.ball.detectBrickCollision(previousBallPosition, brick)) {
                                brick.isActive = false;
                                game.ball.velocity.y *= -1;
                                game.ball.goFaster();
                                shouldPlaySound.explode = true;

                                break;
                            }
                        }
                    }
                },
                .ENDING => {
                    if (raylib.IsKeyPressed(raylib.KEY_ENTER) or raylib.IsMouseButtonDown(raylib.MOUSE_BUTTON_LEFT)) game.screen = .TITLE;
                    game.framesCounter += 1;
                },
            }
        }

        // SOUND
        snd: {
            if (game.isMuted) {
                break :snd;
            }
            raylib.UpdateMusicStream(music);
            if (shouldPlaySound.start) {
                raylib.PlaySound(sounds.start);
            }
            if (shouldPlaySound.bounce) {
                raylib.PlaySound(sounds.bounce);
            }
            if (shouldPlaySound.explode) {
                raylib.PlaySound(sounds.explode);
            }
        }

        // DRAW
        {
            raylib.BeginDrawing();
            defer raylib.EndDrawing();

            raylib.ClearBackground(raylib.RAYWHITE);

            switch (game.screen) {
                .ERROR => unreachable,
                .LOGO => {
                    raylib.DrawTextureV(
                        textures.logo,
                        raylib.Vector2{
                            .x = screenSize.x / 2 - @as(f32, @floatFromInt(textures.logo.width)) / 2.0,
                            .y = screenSize.y / 2 - @as(f32, @floatFromInt(textures.logo.height)) / 2.0,
                        },
                        raylib.WHITE,
                    );
                    raylib.DrawText("LOGO SCREEN", 20, 20, 40, raylib.LIGHTGRAY);
                    raylib.DrawText("Powered by", 290, 220, 20, raylib.GRAY);
                },
                .TITLE => {
                    raylib.DrawRectangle(0, 0, @intFromFloat(screenSize.x), @intFromFloat(screenSize.y), raylib.GREEN);
                    // raylib.DrawText("TITLE SCREEN", 20, 20, 40, raylib.DARKGREEN);
                    const text = "BLOCKS";
                    const fontSize = 160;
                    const textPosition: raylib.Vector2 = .{
                        .x = screenSize.x / 2 - @as(f32, @floatFromInt(raylib.MeasureText(text, fontSize))) / 2,
                        .y = screenSize.y / 5,
                    };

                    raylib.DrawTextEx(font, text, textPosition, 160, 10, raylib.MAROON);

                    const flashingText = "PRESS ENTER to JUMP to GAMEPLAY SCREEN";
                    const flashingTextFontSize = 20;
                    const flashTextStartPoint: i32 = @intFromFloat(screenSize.x / 2 - @as(f32, @floatFromInt(raylib.MeasureText(flashingText, flashingTextFontSize))) / 2);
                    if (game.shouldFlashText) {
                        raylib.DrawText(flashingText, flashTextStartPoint, @intFromFloat(screenSize.y / 2), flashingTextFontSize, raylib.DARKGREEN);
                    }
                },
                .GAMEPLAY => {
                    raylib.DrawRectangle(
                        0,
                        0,
                        @intFromFloat(screenSize.x),
                        @intFromFloat(screenSize.y),
                        raylib.PURPLE,
                    );
                    // raylib.DrawText("GAMEPLAY SCREEN", 20, 20, 40, raylib.MAROON);

                    for (game.bricks, 0..) |brickRow, r| {
                        for (brickRow, 0..) |brick, c| {
                            if (!brick.isActive) continue;
                            const color = if ((r + c) % 2 == 0) raylib.GRAY else raylib.DARKGRAY;
                            raylib.DrawTextureV(textures.brick, brick.position, color);
                        }
                    }
                    raylib.DrawTextureV(textures.paddle, game.player.position, raylib.RAYWHITE);
                    raylib.DrawTextureV(
                        textures.ball,
                        .{ .x = game.ball.position.x - game.ball.radius, .y = game.ball.position.y - game.ball.radius },
                        raylib.MAROON,
                    );

                    if (shouldShowHitboxes) {
                        raylib.BeginBlendMode(raylib.BLEND_ADD_COLORS);
                        defer raylib.EndBlendMode();
                        for (game.bricks, 0..) |brickRow, r| {
                            for (brickRow, 0..) |brick, c| {
                                if (brick.isActive) {
                                    const color = if ((r + c) % 2 == 0) raylib.GRAY else raylib.DARKGRAY;
                                    raylib.DrawRectangleV(game.bricks[r][c].position, game.bricks[r][c].size, color);
                                }
                            }
                        }
                        raylib.DrawRectangleV(game.player.position, game.player.size, raylib.RAYWHITE);
                        raylib.DrawCircleV(game.ball.position, game.ball.radius, raylib.MAROON);
                    }
                    for (0..game.player.lives) |l| {
                        // raylib.DrawRectangle(@intCast(20 + 40 * l), @as(i32, @intFromFloat(screenSize.y)) - 30, 35, 10, raylib.LIGHTGRAY);
                        raylib.DrawTextureEx(textures.paddle, .{
                            .x = @floatFromInt(10 + 40 * l),
                            .y = screenSize.y - 30,
                        }, 0, 0.35, raylib.RAYWHITE);
                    }

                    if (game.isPaused) {
                        const paused_text = "GAME PAUSED. PRESS SPACE to RESUME";
                        const fontSize = 20;
                        raylib.DrawText(
                            paused_text,
                            @as(i32, @intFromFloat(screenSize.x / 2)) - @divFloor(raylib.MeasureText(paused_text, fontSize), 2),
                            @as(i32, @intFromFloat(screenSize.y / 2)),
                            fontSize,
                            raylib.GRAY,
                        );
                    }
                },
                .ENDING => {
                    raylib.DrawRectangle(
                        0,
                        0,
                        @intFromFloat(screenSize.x),
                        @intFromFloat(screenSize.y),
                        raylib.BLUE,
                    );
                    const text = "GAME OVER";
                    const fontSize = 80;
                    const textPosition: raylib.Vector2 = .{
                        .x = screenSize.x / 2 - @as(f32, @floatFromInt(raylib.MeasureText(text, fontSize))) / 2,
                        .y = screenSize.y / 4,
                    };
                    raylib.DrawTextEx(font, text, textPosition, fontSize, 6, raylib.MAROON);

                    const flashingText = "PRESS ENTER to RETURN to TITLE SCREEN";
                    const flashingFontSize = 20;
                    raylib.DrawText("ENDING SCREEN", 20, 20, 40, raylib.DARKBLUE);
                    const flashingTextStartPoint: i32 = @intFromFloat(screenSize.x / 2 - @as(f32, @floatFromInt(raylib.MeasureText(flashingText, flashingFontSize))) / 2);
                    if (game.shouldFlashText) {
                        raylib.DrawText(flashingText, flashingTextStartPoint, 220, flashingFontSize, raylib.DARKBLUE);
                    }
                },
            }
            if (shouldShowFps)
                raylib.DrawText(raylib.TextFormat("FPS: %.1f", fps_float), 0, 20, 20, raylib.BLACK);
        }
    }
    inline for (comptime std.meta.fields(@TypeOf(textures))) |field| {
        const texture = @field(textures, field.name);
        raylib.UnloadTexture(texture);
    }
    inline for (comptime std.meta.fields(@TypeOf(sounds))) |field| {
        const sound = @field(sounds, field.name);
        defer raylib.UnloadSound(sound);
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
