const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const exe = b.addExecutable(.{
        .name = "bricks",
        .root_source_file = b.path("me/game.zig"),
        .target = target,
    });
    const check_step = b.step("check", "");
    check_step.dependOn(&exe.step);

    exe.linkLibC();
    exe.linkSystemLibrary("m");

    if (target.result.isDarwin()) {
        exe.linkFramework("IOKit");
        exe.linkFramework("Cocoa");
    }
    exe.linkSystemLibrary("opengl32");
    exe.linkSystemLibrary("gdi32");
    exe.linkSystemLibrary("winmm");

    exe.addIncludePath(b.path("../raylib/src"));
    exe.addLibraryPath(b.path("../raylib/src"));
    exe.linkSystemLibrary("raylib");

    b.installArtifact(exe);

    const game_exe = b.addRunArtifact(exe);
    const play_step = b.step("play", "");
    play_step.dependOn(&game_exe.step);
    const exe2 = b.addExecutable(.{
        .name = "fonts",
        .root_source_file = b.path("me/showFont.zig"),
        .target = target,
    });
    check_step.dependOn(&exe2.step);
    exe2.linkLibC();
    exe2.linkSystemLibrary("m");

    exe2.addIncludePath(b.path("../raylib/src"));
    exe2.addLibraryPath(b.path("../raylib/src"));
    exe2.linkSystemLibrary("raylib");

    if (target.result.isDarwin()) {
        exe2.linkFramework("IOKit");
        exe2.linkFramework("Cocoa");
    }

    const font_exe = b.addRunArtifact(exe2);
    const font_step = b.step("font", "");
    font_step.dependOn(&font_exe.step);
}
