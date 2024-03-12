const std = @import("std");

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

    _ = b.addModule("mcl", .{
        .root_source_file = .{ .path = "src/mcl.zig" },
        .imports = &.{
            .{ .name = "version", .module = version },
            .{ .name = "mdfunc", .module = mdfunc.module("mdfunc") },
        },
    });
}
