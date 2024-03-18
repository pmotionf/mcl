const std = @import("std");

const v = @import("version");
const mdfunc = @import("mdfunc");

pub const version: std.SemanticVersion =
    std.SemanticVersion.parse(v.mcl_version) catch unreachable;

/// Direct access to underlying CC-Link connection to motion system.
pub const connection = @import("connection.zig");

pub var lines: []const Line = undefined;

const StationIndex = connection.Station.Index;

pub const Station = struct {
    index: StationIndex,
    channel: connection.Channel,

    pub const Range = struct {
        indices: connection.Station.IndexRange,
        channel: connection.Channel,

        pub fn poll(range: Range) !void {
            try connection.pollStations(range.channel, range.indices);
        }

        pub fn pollX(range: Range) !void {
            try connection.pollStationsX(range.channel, range.indices);
        }

        pub fn pollWr(range: Range) !void {
            try connection.pollStationsWr(range.channel, range.indices);
        }

        pub fn send(range: Range) !void {
            try connection.sendStations(range.channel, range.indices);
        }

        pub fn sendY(range: Range) !void {
            try connection.sendStation(range.channel, range.indices);
        }

        pub fn sendWw(range: Range) !void {
            try connection.sendStation(range.channel, range.indices);
        }
    };

    pub fn poll(station: Station) !void {
        try connection.pollStation(station.channel, station.index);
    }

    pub fn pollX(station: Station) !void {
        try connection.pollStationX(station.channel, station.index);
    }

    pub fn pollWr(station: Station) !void {
        try connection.pollStationWr(station.channel, station.index);
    }

    pub fn reference(station: Station) !connection.Station.Reference {
        return try connection.station(station.channel, station.index);
    }

    pub fn X(station: Station) !*connection.Station.X {
        return try connection.stationX(station.channel, station.index);
    }

    pub fn Y(station: Station) !*connection.Station.Y {
        return try connection.stationY(station.channel, station.index);
    }

    pub fn Wr(station: Station) !*connection.Station.Wr {
        return try connection.stationWr(station.channel, station.index);
    }

    pub fn Ww(station: Station) !*connection.Station.Ww {
        return try connection.stationWw(station.channel, station.index);
    }

    pub fn setY(station: Station, offset: u6) !void {
        try connection.setStationY(station.channel, station.index, offset);
    }

    pub fn resetY(station: Station, offset: u6) !void {
        try connection.resetStationY(station.channel, station.index, offset);
    }

    pub fn send(station: Station) !void {
        try connection.sendStation(station.channel, station.index);
    }

    pub fn sendY(station: Station) !void {
        try connection.sendStationY(station.channel, station.index);
    }

    pub fn sendWw(station: Station) !void {
        try connection.sendStationWw(station.channel, station.index);
    }
};

pub const Line = struct {
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
        var stations: u9 = 0;
        for (line.ranges) |range| {
            stations += @intCast(range.indices.end - range.indices.start);
            stations += 1;
        }
        return stations;
    }

    pub fn connect(line: Line) !void {
        for (line.ranges) |range| {
            connection.openChannel(range.channel) catch |e| {
                switch (e) {
                    connection.MelsecError.@"66: Channel-opened error" => {},
                    else => {
                        return e;
                    },
                }
            };
            const end: usize = @as(usize, range.indices.end) + 1;
            for (range.indices.start..end) |_i| {
                const i: connection.Station.Index = @intCast(_i);
                const y = try connection.stationY(range.channel, i);
                y.*.cc_link_enable = true;
            }
            try connection.sendStationsY(range.channel, range.indices);
        }
    }

    pub fn disconnect(line: Line) !void {
        var used_channels: [4]bool = .{ false, false, false, false };
        for (line.ranges) |range| {
            const end: usize = @as(usize, range.indices.end) + 1;
            for (range.indices.start..end) |_i| {
                const i: connection.Station.Index = @intCast(_i);
                const y = try connection.stationY(range.channel, i);
                y.*.cc_link_enable = false;
            }
            try connection.sendStationsY(range.channel, range.indices);
            used_channels[@intFromEnum(range.channel)] = true;
        }
        for (used_channels, 0..) |used, i| {
            if (used) {
                try connection.closeChannel(@enumFromInt(i));
            }
        }
    }

    pub fn station(line: Line, index: Line.Index) !Station {
        var station_counter: Line.Index = index;
        for (line.ranges) |range| {
            const range_len: Line.Index =
                @as(Line.Index, range.indices.end - range.indices.start) + 1;
            if (station_counter < range_len) {
                const idx: StationIndex = range.indices.start +
                    @as(StationIndex, @intCast(station_counter));
                return .{ .index = idx, .channel = range.channel };
            }
            station_counter -= range_len;
        } else {
            return error.IndexOutOfRange;
        }
    }

    pub fn poll(line: Line) !void {
        for (line.ranges) |range| {
            try range.poll();
        }
    }

    pub fn pollX(line: Line) !void {
        for (line.ranges) |range| {
            try range.pollX();
        }
    }

    pub fn pollWr(line: Line) !void {
        for (line.ranges) |range| {
            try range.pollWr();
        }
    }

    pub fn send(line: Line) !void {
        for (line.ranges) |range| {
            try range.send();
        }
    }

    pub fn sendY(line: Line) !void {
        for (line.ranges) |range| {
            try range.sendY();
        }
    }

    pub fn sendWw(line: Line) !void {
        for (line.ranges) |range| {
            try range.sendWw();
        }
    }

    /// Return the first station and local axis index found that holds the
    /// provided slider ID.
    pub fn search(line: Line, slider_id: i16) !?struct { Line.Index, u2 } {
        var station_index: Line.Index = 0;
        for (line.ranges) |range| {
            const end: usize = @as(usize, range.indices.end) + 1;
            for (range.indices.start..end) |_i| {
                const i: StationIndex = @intCast(_i);
                const wr = try connection.stationWr(range.channel, i);
                for (0..3) |_j| {
                    const j: u2 = @intCast(_j);
                    if (wr.sliderNumber(j) == slider_id) {
                        return .{ station_index, j };
                    }
                }
                station_index += 1;
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
                if (range.indices.end < range.indices.start) {
                    return error.InvalidStationRange;
                }
                const start: usize = range.indices.start;
                const end: usize = @as(usize, range.indices.end) + 1;
                const channel_idx: u2 = @intFromEnum(range.channel);
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
    for (system_lines, 0..) |line, line_counter| {
        const ranges_end: usize = ranges_offset + line.ranges.len;
        @memcpy(
            all_ranges[ranges_offset..ranges_end],
            line.ranges,
        );
        all_lines[line_counter].ranges = all_ranges[ranges_offset..ranges_end];
        ranges_offset += line.ranges.len;
    }
}
