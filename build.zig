const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const exe = b.addExecutable(.{
        .name = "raylib-zig",
        .root_source_file = b.path("me/game.zig"),
        .target = target,
    });
    const check_step = b.step("check", "");
    check_step.dependOn(&exe.step);

    exe.linkLibC();
    exe.linkSystemLibrary("m");

    exe.addIncludePath(b.path("../raylib/src"));
    exe.addLibraryPath(b.path("../raylib/src"));
    exe.linkSystemLibrary("raylib");

    if (target.result.isDarwin()) {
        exe.linkFramework("IOKit");
        exe.linkFramework("Cocoa");
    }

    b.installArtifact(exe);

    const game_exe = b.addRunArtifact(exe);
    const play_step = b.step("play", "");
    play_step.dependOn(&game_exe.step);
}
