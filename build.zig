const std = @import("std");

const mcl_version_string = @import("version.zig").mcl_version;
pub const mcl_version = std.SemanticVersion.parse(mcl_version_string) catch {
    unreachable;
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const version = b.addModule("version", .{
        .root_source_file = .{ .path = "version.zig" },
    });

    const mdfunc_lib_path = b.option(
        []const u8,
        "mdfunc",
        "Specify the path to the MELSEC static library artifact.",
    ) orelse if (target.result.cpu.arch == .x86_64)
        b.pathFromRoot("vendor/mdfunc/lib/x64/MdFunc32.lib")
    else
        b.pathFromRoot("vendor/mdfunc/lib/mdfunc32.lib");

    const mdfunc = b.dependency("mdfunc", .{
        .target = target,
        .optimize = optimize,
        .mdfunc = mdfunc_lib_path,
    });

    const mod = b.addModule("mcl", .{
        .root_source_file = .{ .path = "src/mcl.zig" },
        .imports = &.{
            .{ .name = "version", .module = version },
            .{ .name = "mdfunc", .module = mdfunc.module("mdfunc") },
        },
    });

    const lib = b.addSharedLibrary(.{
        .name = "MCL",
        .root_source_file = .{ .path = "src/mcl_c.zig" },
        .target = target,
        .optimize = optimize,
        .version = mcl_version,
    });
    lib.root_module.addImport("version", version);
    lib.root_module.addImport("mcl", mod);

    const lib_compile_step = b.step(
        "MCL",
        "Compile Motion Control Library",
    );
    lib_compile_step.dependOn(&b.addInstallArtifact(lib, .{}).step);
    lib_compile_step.dependOn(
        &b.addInstallHeaderFile("include/MCL.h", "MCL.h").step,
    );
    b.getInstallStep().dependOn(lib_compile_step);

    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/mcl.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_main_tests = b.addRunArtifact(main_tests);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);
}
