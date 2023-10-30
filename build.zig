const std = @import("std");

const mcs_version_string = @import("version.zig").mcs_version;
pub const mcs_version = std.SemanticVersion.parse(mcs_version_string) catch {
    unreachable;
};

fn linkMdFunc(
    artifact: *std.Build.Step.Compile,
    target_arch: std.Target.Cpu.Arch,
) void {
    artifact.addIncludePath(.{ .path = "lib/Mdfunc/include" });

    if (target_arch == .x86_64) {
        artifact.addLibraryPath(.{ .path = "lib/Mdfunc/lib/x64" });
        artifact.linkSystemLibrary2("MdFunc32", .{
            .preferred_link_mode = .Static,
        });
    } else {
        artifact.addLibraryPath(.{ .path = "lib/Mdfunc/lib" });
        artifact.linkSystemLibrary2("mdfunc32", .{
            .preferred_link_mode = .Static,
        });
    }
}

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    const target_arch = target.cpu_arch orelse
        @import("builtin").target.cpu.arch;

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const version = b.addModule("version", .{
        .source_file = .{ .path = "version.zig" },
    });

    const mod = b.addModule("mcs", .{
        .source_file = .{ .path = "src/mcs.zig" },
        .dependencies = &[_]std.Build.ModuleDependency{.{
            .name = "version",
            .module = version,
        }},
    });

    const lib = b.addSharedLibrary(.{
        .name = "MCS",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "src/mcs_c.zig" },
        .target = target,
        .optimize = optimize,
        .version = mcs_version,
    });
    switch (optimize) {
        .Debug, .ReleaseSafe => lib.bundle_compiler_rt = true,
        .ReleaseFast, .ReleaseSmall => lib.disable_stack_probing = true,
    }
    lib.addModule("version", version);
    lib.addModule("mcs", mod);
    lib.linkLibC();
    lib.force_pic = true;
    // lib.compress_debug_sections = .zstd;
    // lib.rc_includes = .msvc;
    linkMdFunc(lib, target_arch);

    const lib_compile_step = b.step(
        "MCS",
        "Compile MCS Library",
    );
    lib_compile_step.dependOn(&b.addInstallArtifact(lib, .{}).step);
    lib_compile_step.dependOn(
        &b.addInstallHeaderFile("include/MCS.h", "MCS.h").step,
    );
    b.getInstallStep().dependOn(lib_compile_step);

    // MELSEC Data Link Library inclusion
    // b.getInstallStep().dependOn(
    // &b.addInstallLibFile(.{ .path = mdfunc_path }, "mdfunc.lib").step,
    // );
    // const mdfunc_link_step = b.addSystemCommand(&[4][]const u8{
    // "lib.exe",
    // "/OUT:MCS_Export.lib",
    // "MCS.lib",
    // "mdfunc.lib",
    // });
    // mdfunc_link_step.step.dependOn(lib_compile_step);
    // b.getInstallStep().dependOn(&mdfunc_link_step.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/mcs.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_main_tests = b.addRunArtifact(main_tests);

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build test`
    // This will evaluate the `test` step rather than the default, which is "install".
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);
}
