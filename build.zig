const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const exe = b.addExecutable(.{
        .name = "raylib-zig",
        .root_source_file = b.path("me/game.zig"),
        .target = target,
    });

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

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "");
    run_step.dependOn(&run_exe.step);
}
