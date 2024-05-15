const std = @import("std");

const v = @import("version");
const mdfunc = @import("mdfunc");

pub const version: std.SemanticVersion =
    std.SemanticVersion.parse(v.mcl_version) catch unreachable;

/// Direct access to underlying CC-Link connection to motion system.
pub const connection = @import("connection.zig");

pub var lines: []const Line = undefined;

pub const Direction = connection.Station.Direction;

const StationIndex = connection.Station.Index;

pub const Station = struct {
    connection: connection.Channel.Index,
    line: *const Line = undefined,
    index: Index = undefined,

    /// Index within configured line, spanning across connection ranges.
    pub const Index = u8;

    /// Inclusive range of stations in line. Each range only spans within one
    /// CC-Link connection channel.
    pub const Range = struct {
        connection: connection.Channel.Range,
        start: Index = undefined,
        end: Index = undefined,
        line: *const Line = undefined,

        pub fn len(range: Range) usize {
            return @as(usize, range.end - range.start) + 1;
        }
    };

    pub fn prev(station: Station) ?Station {
        if (station.index > 0) {
            return station.line.station(station.index - 1) catch {
                unreachable;
            };
        } else return null;
    }

    pub fn next(station: Station) ?Station {
        if (station.index < station.line.numStations() - 1) {
            return station.line.station(station.index + 1) catch {
                unreachable;
            };
        } else return null;
    }
};

pub const Line = struct {
    index: Index,
    /// Total number of axes in line.
    axes: u10,
    /// Ranges that make up line, in order from back to front.
    ranges: []Station.Range,

    pub const Index = u8;

    /// Inclusive index range of stations in line.
    pub const IndexRange = struct {
        start: Index,
        end: Index,
    };

    pub fn numStations(line: Line) u9 {
        var stations: usize = 0;
        for (line.ranges) |range| {
            stations += range.len();
        }
        return @intCast(stations);
    }

    pub fn connect(line: Line) !void {
        for (line.ranges) |range| {
            try range.connection.channel.open();
            for (0..range.connection.len()) |i| {
                const index = try range.connection.index(i);
                const y = try index.Y();
                y.*.cc_link_enable = true;
            }
            try range.connection.sendY();
        }
    }

    pub fn disconnect(line: Line) !void {
        for (line.ranges) |range| {
            for (0..range.connection.len()) |i| {
                const index = try range.connection.index(i);
                const y = try index.Y();
                y.*.cc_link_enable = false;
            }
            try range.connection.sendY();
        }
    }

    pub fn station(line: *const Line, index: Line.Index) !Station {
        var station_counter: Line.Index = index;
        for (line.ranges) |range| {
            const range_len: Line.Index = @intCast(range.connection.len());
            if (station_counter < range_len) {
                const idx: StationIndex = range.connection.indices.start +
                    @as(StationIndex, @intCast(station_counter));
                return .{
                    .connection = .{
                        .index = idx,
                        .channel = range.connection.channel,
                    },
                    .index = index,
                    .line = line,
                };
            }
            station_counter -= range_len;
        } else {
            return error.IndexOutOfRange;
        }
    }

    pub fn axisStation(line: *const Line, axis: u10) !Station {
        return try line.station(@intCast(@divTrunc(axis, 3)));
    }

    pub fn poll(line: Line) !void {
        for (line.ranges) |range| {
            try range.connection.poll();
        }
    }

    pub fn pollX(line: Line) !void {
        for (line.ranges) |range| {
            try range.connection.pollX();
        }
    }

    pub fn pollWr(line: Line) !void {
        for (line.ranges) |range| {
            try range.connection.pollWr();
        }
    }

    pub fn send(line: Line) !void {
        for (line.ranges) |range| {
            try range.connection.send();
        }
    }

    pub fn sendY(line: Line) !void {
        for (line.ranges) |range| {
            try range.connection.sendY();
        }
    }

    pub fn sendWw(line: Line) !void {
        for (line.ranges) |range| {
            try range.connection.sendWw();
        }
    }

    /// Return the first station and local axis index found that holds the
    /// provided slider ID.
    pub fn search(line: *const Line, slider_id: u16) !?struct { Station, u2 } {
        var line_index: Line.Index = 0;
        for (line.ranges) |range| {
            for (0..range.connection.len()) |i| {
                const index = try range.connection.index(i);
                const wr = try index.Wr();
                for (0..3) |_j| {
                    const j: u2 = @intCast(_j);
                    if (wr.sliderNumber(j) == slider_id) {
                        return .{ .{
                            .connection = index,
                            .index = line_index,
                            .line = line,
                        }, j };
                    }
                }
                line_index += 1;
            }
        } else {
            return null;
        }
    }
};

// Buffer that can store maximum ranges (one range per station).
var all_ranges: [64 * 4]Station.Range = undefined;
// Buffer that can store maximum lines (one line per station).
var all_lines: [64 * 4]Line = undefined;

pub fn init(system_lines: []const Line) !void {
    if (system_lines.len < 1 or system_lines.len > 64 * 4) {
        return error.InvalidNumberOfLines;
    }

    // Lines validation before overwriting potential pre-existing lines.
    {
        var used_stations: [4][64]bool =
            [_][64]bool{[_]bool{false} ** 64} ** 4;
        for (system_lines) |line| {
            if (line.ranges.len < 1 or line.ranges.len > 64 * 4) {
                return error.InvalidLineStationRanges;
            }
            if (line.axes < 1 or line.axes > 64 * 4 * 3) {
                return error.InvalidLineAxes;
            }
            var total_stations: u9 = 0;
            for (line.ranges) |range| {
                if (range.connection.indices.end <
                    range.connection.indices.start)
                {
                    return error.InvalidStationRange;
                }
                const start: usize = range.connection.indices.start;
                const end: usize = @as(
                    usize,
                    range.connection.indices.end,
                ) + 1;
                const channel_idx: u2 = @intFromEnum(range.connection.channel);
                if (!std.mem.allEqual(
                    bool,
                    used_stations[channel_idx][start..end],
                    false,
                )) {
                    return error.InvalidStationRedefinition;
                }
                @memset(
                    used_stations[channel_idx][start..end],
                    true,
                );

                total_stations += @intCast(end - start);
            }
            // Minimum number of axes is 3 axes per each station, with one axis
            // at the last station.
            const min_axes: u10 = (total_stations - 1) * 3 + 1;
            // Maximum number of axes is 3 axes for every station.
            const max_axes: u10 = total_stations * 3;
            if (line.axes < min_axes or line.axes > max_axes) {
                return error.InvalidLineAxes;
            }
        }
    }

    // Copy lines to local buffers.
    var ranges_offset: usize = 0;
    @memcpy(all_lines[0..system_lines.len], system_lines);
    lines = all_lines[0..system_lines.len];
    for (system_lines, 0..) |line, line_index| {
        const ranges_end: usize = ranges_offset + line.ranges.len;
        @memcpy(
            all_ranges[ranges_offset..ranges_end],
            line.ranges,
        );
        all_lines[line_index].index = line_index;
        all_lines[line_index].ranges = all_ranges[ranges_offset..ranges_end];

        var range_start: Line.Index = 0;
        for (all_lines[line_index].ranges) |*range| {
            const range_len: Line.Index =
                range.connection.indices.end - range.connection.indices.start;
            range.start = range_start;
            range.end = range_start + range_len;
            range_start += range_len + 1;
            range.line = &all_lines[line_index];
        }

        ranges_offset += line.ranges.len;
    }
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
    const back_ref = try back.connection.reference();
    const front_ref = try back.connection.reference();

    const back_slider = back_ref.wr.slider_number.axis3;
    const front_slider = front_ref.wr.slider_number.axis1;

    const back_state = back_ref.wr.slider_state.axis3;
    const front_state = front_ref.wr.slider_state.axis1;

    if (back_slider != front_slider) return null;

    if (dir == .backward) {
        if (back_state == .NextAxisAuxiliary or
            back_state == .NextAxisCompleted or back_state == .None)
        {
            try front.connection.setY(0x9);
            return .{ front, .backward };
        } else if (front_state == .PrevAxisAuxiliary or
            front_state == .PrevAxisCompleted or front_state == .None)
        {
            try back.connection.setY(0xA);
            return .{ back, .forward };
        }
    }
    // dir == .forward
    else {
        if ((front_state == .PrevAxisAuxiliary or
            front_state == .PrevAxisCompleted) and back.index > 0)
        {
            const prev_station = back.prev().?;
            try prev_station.connection.setY(0xA);
            return .{ prev_station, .forward };
        } else if (back_state == .NextAxisAuxiliary or
            back_state == .NextAxisCompleted)
        {
            try back.connection.setY(0x9);
            return .{ back, .backward };
        }
    }
    return null;
}

/// Opens all channels used in all configured lines.
pub fn open() !void {
    var used_channels: [4]bool = .{ false, false, false, false };
    for (lines) |line| {
        for (line.ranges) |range| {
            used_channels[@intFromEnum(range.connection.channel)] = true;
        }
    }
    for (used_channels, 0..) |used, i| {
        if (used) {
            const chan: connection.Channel = @enumFromInt(i);
            try chan.open();
        }
    }
}

/// Closes all channels used in all configured lines.
pub fn close() !void {
    var used_channels: [4]bool = .{ false, false, false, false };
    for (lines) |line| {
        for (line.ranges) |range| {
            used_channels[@intFromEnum(range.connection.channel)] = true;
        }
    }
    for (used_channels, 0..) |used, i| {
        if (used) {
            const chan: connection.Channel = @enumFromInt(i);
            try chan.close();
        }
    }
}
