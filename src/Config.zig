const Config = @This();

const std = @import("std");
const connection = @import("connection.zig");
const mcl = @import("mcl.zig");

lines: []Line,

pub const Line = struct {
    /// Total number of axes in line.
    axes: mcl.Line.Axis.Id,

    /// CC-Link Station ranges.
    ranges: []Range,

    pub const Range = struct {
        /// CC-Link Channel.
        channel: connection.Channel,
        /// CC-Link Station ID. Start of range, inclusive.
        start: connection.Id,
        /// CC-Link Station ID. End of range, inclusive.
        end: connection.Id,
    };
};

pub fn validate(c: Config) !void {
    if (c.lines.len == 0 or c.lines.len > 64 * 4) {
        return error.ConfigInvalidNumberOfLines;
    }

    var total_stations_num: usize = 0;
    var used_cc_link_stations: [64 * 4]bool = .{false} ** (64 * 4);

    for (c.lines) |line| {
        var total_line_stations: usize = 0;
        if (line.axes == 0 or line.axes > 64 * 4 * 3) {
            return error.ConfigInvalidLineAxes;
        }

        const required_stations: usize = (line.axes - 1) / 3 + 1;

        for (line.ranges) |range| {
            if (range.start == 0 or range.start > 64) {
                return error.ConfigInvalidLineRangeStart;
            }
            if (range.end < range.start or range.end > 64) {
                return error.ConfigInvalidLineRangeEnd;
            }
            const channel_offset: usize =
                64 * @as(usize, @intFromEnum(range.channel));
            for (range.start - 1..range.end) |range_index| {
                if (used_cc_link_stations[channel_offset + range_index]) {
                    return error.ConfigOverlappingLineStationRanges;
                }
                used_cc_link_stations[channel_offset + range_index] = true;
                total_stations_num += 1;
                total_line_stations += 1;
            }
        }

        if (total_line_stations != required_stations) {
            return error.ConfigInvalidLineAxesForStations;
        }
    }

    if (total_stations_num == 0 or total_stations_num > 64 * 4) {
        return error.ConfigInvalidTotalNumberOfStations;
    }
}
