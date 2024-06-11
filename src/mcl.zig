const std = @import("std");
const mdfunc = @import("mdfunc");
const v = @import("version");
const registers = @import("registers.zig");
const connection = @import("connection.zig");

pub const Config = @import("Config.zig");
pub const Station = @import("Station.zig");
pub const Line = @import("Line.zig");

pub const version: std.SemanticVersion =
    std.SemanticVersion.parse(v.mcl_version) catch unreachable;

pub var lines: []const Line = undefined;

pub const Distance = registers.Distance;
pub const Direction = registers.Direction;

// Buffer that can store maximum stations.
var all_stations: [64 * 4]Station = undefined;

// Buffer that can store maximum lines (one line per station).
var all_lines: [64 * 4]Line = undefined;

// Buffer that can store maximum ranges (one range per station).
var all_ranges: [64 * 4]Line.ConnectionRange = undefined;

// Buffers that can store maximum registers. Within buffer, registers are
// stored in order of use in flattened line ranges.
var all_x: [64 * 4]registers.X = .{std.mem.zeroes(registers.X)} ** (64 * 4);
var all_y: [64 * 4]registers.Y = .{std.mem.zeroes(registers.Y)} ** (64 * 4);
var all_wr: [64 * 4]registers.Wr = .{std.mem.zeroes(registers.Wr)} ** (64 * 4);
var all_ww: [64 * 4]registers.Ww = .{std.mem.zeroes(registers.Ww)} ** (64 * 4);

var used_channels: [4]bool = .{false} ** 4;

/// Initialize the MCL library. This must be run before any other MCL library
/// functions, except functions in `Config.zig`, are called. This must also be
/// re-run after every configuration change to the system.
pub fn init(config: Config) void {
    var ranges_offset: usize = 0;
    var stations_offset: usize = 0;

    used_channels = .{false} ** 4;

    for (config.lines, 0..) |line, i| {
        var num_stations: usize = 0;

        for (line.ranges, 0..) |range, range_i| {
            used_channels[@intFromEnum(range.channel)] = true;
            all_ranges[ranges_offset..][range_i] = .{
                .channel = range.channel,
                .range = .{
                    .start = @intCast(range.start - 1),
                    .end = @intCast(range.end - 1),
                },
            };
            for (range.start - 1..range.end) |station_i| {
                all_x[stations_offset..][num_stations] =
                    std.mem.zeroes(Station.X);
                all_y[stations_offset..][num_stations] =
                    std.mem.zeroes(Station.Y);
                all_wr[stations_offset..][num_stations] =
                    std.mem.zeroes(Station.Wr);
                all_ww[stations_offset..][num_stations] =
                    std.mem.zeroes(Station.Ww);
                all_stations[i] = .{
                    .line = &all_lines[i],
                    .index = @intCast(num_stations),
                    .x = &all_x[stations_offset..][num_stations],
                    .y = &all_y[stations_offset..][num_stations],
                    .wr = &all_wr[stations_offset..][num_stations],
                    .ww = &all_ww[stations_offset..][num_stations],
                    .connection = .{
                        .channel = range.channel,
                        .index = @intCast(station_i),
                    },
                };
                num_stations += 1;
            }
        }
        defer ranges_offset += line.ranges.len;
        defer stations_offset += num_stations;

        all_lines[i] = .{
            .index = @intCast(i),
            .axes = line.axes,
            .stations = undefined,
            .x = all_x[stations_offset..][0..num_stations],
            .y = all_y[stations_offset..][0..num_stations],
            .wr = all_wr[stations_offset..][0..num_stations],
            .ww = all_ww[stations_offset..][0..num_stations],
            .connection = all_ranges[ranges_offset..][0..line.ranges.len],
        };
    }
    lines = all_lines[0..config.lines.len];
}

/// Stop traffic transmission between drivers when a slider is between two
/// stations and must move in a direction. If traffic transmission is stopped,
/// the station and direction from which transmission was stopped is returned
/// as a tuple.
pub fn stopTrafficTransmission(
    back: Station,
    front: Station,
    dir: Direction,
) !?struct { Station, Direction } {
    const back_slider = back.wr.slider_number.axis3;
    const front_slider = front.wr.slider_number.axis1;

    const back_state = back.wr.slider_state.axis3;
    const front_state = front.wr.slider_state.axis1;

    if (back_slider != front_slider) return null;

    if (dir == .backward) {
        if (back_state == .NextAxisAuxiliary or
            back_state == .NextAxisCompleted or back_state == .None)
        {
            try front.setY(0x9);
            return .{ front, .backward };
        } else if (front_state == .PrevAxisAuxiliary or
            front_state == .PrevAxisCompleted or front_state == .None)
        {
            try back.setY(0xA);
            return .{ back, .forward };
        }
    }
    // dir == .forward
    else {
        if ((front_state == .PrevAxisAuxiliary or
            front_state == .PrevAxisCompleted) and back.index > 0)
        {
            const prev_station = back.prev().?;
            try prev_station.setY(0xA);
            return .{ prev_station, .forward };
        } else if (back_state == .NextAxisAuxiliary or
            back_state == .NextAxisCompleted)
        {
            try back.setY(0x9);
            return .{ back, .backward };
        }
    }
    return null;
}

/// Opens all channels used in all configured lines.
pub fn open() !void {
    for (used_channels, 0..) |used, i| {
        if (used) {
            const chan: connection.Channel = @enumFromInt(i);
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
            const chan: connection.Channel = @enumFromInt(i);
            chan.close() catch |e| switch (e) {
                else => return e,
            };
        }
    }
}
