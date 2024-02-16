const std = @import("std");

const mcs_version_string = @import("version.zig").mcs_version;
pub const mcs_version = std.SemanticVersion.parse(mcs_version_string) catch {
    unreachable;
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const target_arch = target.result.cpu.arch;

    const optimize = b.standardOptimizeOption(.{});

    const version = b.addModule("version", .{
        .root_source_file = .{ .path = "version.zig" },
    });

    const mod = b.addModule("mcs", .{
        .root_source_file = .{ .path = "src/mcs.zig" },
        .imports = &.{
            .{ .name = "version", .module = version },
        },
    });
    mod.addIncludePath(.{ .path = "lib/Mdfunc/include" });

    const lib = b.addSharedLibrary(.{
        .name = "MCS",
        .root_source_file = .{ .path = "src/mcs_c.zig" },
        .target = target,
        .optimize = optimize,
        .version = mcs_version,
    });
    lib.root_module.addImport("version", version);
    lib.root_module.addImport("mcs", mod);
    if (target_arch == .x86_64) {
        lib.root_module.addLibraryPath(.{ .path = "lib/Mdfunc/lib/x64" });
        lib.root_module.linkSystemLibrary("MdFunc32", .{
            .needed = true,
            .preferred_link_mode = .Static,
        });
    } else {
        lib.root_module.addLibraryPath(.{ .path = "lib/Mdfunc/lib" });
        lib.root_module.linkSystemLibrary("mdfunc32", .{
            .needed = true,
            .preferred_link_mode = .Static,
        });
    }
    lib.linkLibC();

    const lib_compile_step = b.step(
        "MCS",
        "Compile MCS Library",
    );
    lib_compile_step.dependOn(&b.addInstallArtifact(lib, .{}).step);
    lib_compile_step.dependOn(
        &b.addInstallHeaderFile("include/MCS.h", "MCS.h").step,
    );
    b.getInstallStep().dependOn(lib_compile_step);

    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/mcs.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_main_tests = b.addRunArtifact(main_tests);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);
}
