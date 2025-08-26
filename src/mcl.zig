const std = @import("std");
const mdfunc = @import("mdfunc");
const build = @import("build.zig.zon");

pub const registers = @import("registers.zig");
pub const cc_link = @import("cc_link.zig");

pub const Config = @import("Config.zig");
pub const Axis = @import("Axis.zig");
pub const Station = @import("Station.zig");
pub const Line = @import("Line.zig");

pub const version: std.SemanticVersion =
    std.SemanticVersion.parse(build.version) catch unreachable;

pub var lines: []const Line = &.{};

// Identical slice of lines as above without the const modifier, allowing the
// MCL library to initialize lines but preventing consumers from mutating.
var _lines: []Line = &.{};

pub const Direction = registers.Direction;

var used_channels: [4]bool = .{false} ** 4;
var allocator: ?std.mem.Allocator = null;

/// Initialize the MCL library. This must be run before any other MCL library
/// functions, except functions in `Config.zig`, are called. This must also be
/// re-run after every configuration change to the system.
pub fn init(a: std.mem.Allocator, config: Config) !void {
    used_channels = .{false} ** 4;
    _lines = try a.alloc(Line, config.lines.len);
    errdefer a.free(_lines);

    for (config.lines) |line| {
        for (line.ranges) |range| {
            used_channels[@intFromEnum(range.channel)] = true;
        }
    }

    for (config.lines, 0..) |line, line_idx| {
        try Line.init(a, &_lines[line_idx], @intCast(line_idx), line);
    }
    lines = _lines;
    allocator = a;
}

pub fn deinit() void {
    if (allocator) |_| {
        for (_lines) |*line| {
            line.deinit();
        }
    }
    if (allocator) |a| a.free(_lines);

    _lines = &.{};
    lines = &.{};
    allocator = null;
}

/// Opens all channels used in all configured lines.
pub fn open() !void {
    for (used_channels, 0..) |used, i| {
        if (used) {
            const chan: cc_link.Channel = @enumFromInt(i);
            chan.open() catch |e| switch (e) {
                mdfunc.Error.@"66: Channel-opened error" => {},
                else => return e,
            };
        }
    }
}

/// Closes all channels used in all configured lines.
pub fn close() !void {
    for (used_channels, 0..) |used, i| {
        if (used) {
            const chan: cc_link.Channel = @enumFromInt(i);
            chan.close() catch |e| switch (e) {
                else => return e,
            };
        }
    }
}

test {
    std.testing.refAllDeclsRecursive(@This());
}

test "Init with 256 lines with 1 driver on each line" {
    var config: [256]Config.Line = undefined;
    for (&config) |*line| {
        line.ranges = try std.testing.allocator.alloc(Config.Line.Range, 1);
    }
    defer for (&config) |*line| {
        std.testing.allocator.free(line.ranges);
    };
    for (&config, 0..) |*line, i| {
        line.*.axes = 3;
        for (line.ranges) |*range| {
            range.*.channel = switch (i) {
                0...63 => .cc_link_1slot,
                64...127 => .cc_link_2slot,
                128...191 => .cc_link_3slot,
                192...255 => .cc_link_4slot,
                else => unreachable,
            };
            range.*.start = @intCast(i % 64 + 1);
            range.*.end = @intCast(i % 64 + 1);
        }
    }
    try init(std.testing.allocator, .{ .lines = &config });
    defer deinit();
}
