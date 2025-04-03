const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mdfunc_lib_path = b.option(
        []const u8,
        "mdfunc",
        "Specify the path to the MELSEC static library artifact.",
    ) orelse if (target.result.cpu.arch == .x86_64)
        "vendor/mdfunc/lib/x64/MdFunc32.lib"
    else
        "vendor/mdfunc/lib/mdfunc32.lib";

    const mdfunc_mock_build = b.option(
        bool,
        "mdfunc_mock",
        "Enable building a mock version of the MELSEC data link library.",
    ) orelse (target.result.os.tag != .windows);

    const mdfunc = b.dependency("mdfunc", .{
        .target = target,
        .optimize = optimize,
        .mdfunc = mdfunc_lib_path,
        .mock = mdfunc_mock_build,
    });

    const build_zig_zon = b.createModule(.{
        .root_source_file = b.path("build.zig.zon"),
        .target = target,
        .optimize = optimize,
    });

    _ = b.addModule("mcl", .{
        .root_source_file = b.path("src/mcl.zig"),
        .imports = &.{
            .{ .name = "mdfunc", .module = mdfunc.module("mdfunc") },
            .{ .name = "build.zig.zon", .module = build_zig_zon },
        },
    });

    const mdfunc_mock = b.dependency("mdfunc", .{
        .target = target,
        .optimize = optimize,
        .mdfunc = mdfunc_lib_path,
        .mock = true,
    });

    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/mcl.zig"),
        .target = target,
        .optimize = optimize,
    });
    unit_tests.root_module.addImport("mdfunc", mdfunc_mock.module("mdfunc"));
    unit_tests.root_module.addImport("build.zig.zon", build_zig_zon);

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);

    // Check step is same as test, as there is no output artifact.
    const check = b.step("check", "Check if foo compiles");
    check.dependOn(&run_unit_tests.step);
}
