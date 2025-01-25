const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("stringz", .{ .root_source_file = b.path("src/stringz.zig") });

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/strings.zig"),
        .target = target,
        .optimize = optimize,
    });

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&lib_unit_tests.step);
}
