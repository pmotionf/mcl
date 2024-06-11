const Line = @This();

const std = @import("std");
const mdfunc = @import("mdfunc");
const connection = @import("connection.zig");
const Station = @import("Station.zig");

// The maximum number of stations is also the maximum number of lines, as
// there can be a minimum of one station per line.
pub const Index = Station.Index;
pub const Id = Station.Id;

pub const Axis = struct {
    pub const Index = std.math.IntFittingRange(0, 64 * 4 * 3 - 1);
    pub const Id = std.math.IntFittingRange(1, 64 * 4 * 3);
};

pub const ConnectionRange = struct {
    channel: connection.Channel,
    range: connection.Range,
};

index: Index,

/// Total number of axes in line.
axes: Axis.Id,

/// Stations that make up line.
stations: []Station,

x: []Station.X,
y: []Station.Y,
wr: []Station.Wr,
ww: []Station.Ww,

connection: []ConnectionRange,

pub fn poll(line: Line) !void {
    var range_offset: usize = 0;
    for (line.connection) |range| {
        const path = try range.channel.openedPath();
        const range_len: usize =
            @as(usize, range.range.end - range.range.start) + 1;
        defer range_offset += range_len;

        const x_read_bytes = try mdfunc.receiveEx(
            path,
            0,
            0xFF,
            .DevX,
            @as(i32, range.range.start) * @bitSizeOf(Station.X),
            std.mem.sliceAsBytes(line.x[range_offset..][0..range_len]),
        );
        if (x_read_bytes != @sizeOf(Station.X) * range_len) {
            return connection.Error.UnexpectedReadSizeX;
        }

        const y_read_bytes = try mdfunc.receiveEx(
            path,
            0,
            0xFF,
            .DevY,
            @as(i32, range.range.start) * @bitSizeOf(Station.Y),
            std.mem.sliceAsBytes(line.y[range_offset..][0..range_len]),
        );
        if (y_read_bytes != @sizeOf(Station.Y) * range_len) {
            return connection.Error.UnexpectedReadSizeY;
        }

        const wr_read_bytes = try mdfunc.receiveEx(
            path,
            0,
            0xFF,
            .DevWr,
            @as(i32, range.range.start) * 16, // 16 from MELSEC manual.
            std.mem.sliceAsBytes(line.wr[range_offset..][0..range_len]),
        );
        if (wr_read_bytes != @sizeOf(Station.Wr) * range_len) {
            return connection.Error.UnexpectedReadSizeWr;
        }
    }
}

pub fn pollX(line: Line) (connection.Error || mdfunc.Error)!void {
    var range_offset: usize = 0;
    for (line.connection) |range| {
        const path = try range.channel.openedPath();
        const range_len: usize =
            @as(usize, range.range.end - range.range.start) + 1;
        defer range_offset += range_len;

        const read_bytes = try mdfunc.receiveEx(
            path,
            0,
            0xFF,
            .DevX,
            @as(i32, range.range.start) * @bitSizeOf(Station.X),
            std.mem.sliceAsBytes(line.x[range_offset..][0..range_len]),
        );
        if (read_bytes != @sizeOf(Station.X) * range_len) {
            return connection.Error.UnexpectedReadSizeX;
        }
    }
}

pub fn pollY(line: Line) (connection.Error || mdfunc.Error)!void {
    var range_offset: usize = 0;
    for (line.connection) |range| {
        const path = try range.channel.openedPath();
        const range_len: usize =
            @as(usize, range.range.end - range.range.start) + 1;
        defer range_offset += range_len;

        const read_bytes = try mdfunc.receiveEx(
            path,
            0,
            0xFF,
            .DevY,
            @as(i32, range.range.start) * @bitSizeOf(Station.Y),
            std.mem.sliceAsBytes(line.y[range_offset..][0..range_len]),
        );
        if (read_bytes != @sizeOf(Station.Y) * range_len) {
            return connection.Error.UnexpectedReadSizeY;
        }
    }
}

pub fn pollWr(line: Line) (connection.Error || mdfunc.Error)!void {
    var range_offset: usize = 0;
    for (line.connection) |range| {
        const path = try range.channel.openedPath();
        const range_len: usize =
            @as(usize, range.range.end - range.range.start) + 1;
        defer range_offset += range_len;

        const read_bytes = try mdfunc.receiveEx(
            path,
            0,
            0xFF,
            .DevWr,
            @as(i32, range.range.start) * 16, // 16 from MELSEC manual.
            std.mem.sliceAsBytes(line.wr[range_offset..][0..range_len]),
        );
        if (read_bytes != @sizeOf(Station.Wr) * range_len) {
            return connection.Error.UnexpectedReadSizeWr;
        }
    }
}

pub fn pollWw(line: Line) (connection.Error || mdfunc.Error)!void {
    var range_offset: usize = 0;
    for (line.connection) |range| {
        const path = try range.channel.openedPath();
        const range_len: usize =
            @as(usize, range.range.end - range.range.start) + 1;
        defer range_offset += range_len;

        const read_bytes = try mdfunc.receiveEx(
            path,
            0,
            0xFF,
            .DevWw,
            @as(i32, range.start) * 16, // 16 from MELSEC manual.
            std.mem.sliceAsBytes(line.ww[range_offset..][0..range_len]),
        );
        if (read_bytes != @sizeOf(Station.Ww) * range_len) {
            return connection.Error.UnexpectedReadSizeWw;
        }
    }
}

pub fn send(line: Line) (connection.Error || mdfunc.Error)!void {
    var range_offset: usize = 0;
    for (line.connection) |range| {
        const path = try range.channel.openedPath();
        const range_len: usize =
            @as(usize, range.range.end - range.range.start) + 1;
        defer range_offset += range_len;

        const y_sent_bytes = try mdfunc.receiveEx(
            path,
            0,
            0xFF,
            .DevY,
            @as(i32, range.start) * @bitSizeOf(Station.Y),
            std.mem.sliceAsBytes(line.y[range_offset..][0..range_len]),
        );
        if (y_sent_bytes != @sizeOf(Station.Y) * range_len) {
            return connection.Error.UnexpectedSendSizeY;
        }

        const ww_sent_bytes = try mdfunc.receiveEx(
            path,
            0,
            0xFF,
            .DevWw,
            @as(i32, range.start) * 16, // 16 from MELSEC manual.
            std.mem.sliceAsBytes(line.ww[range_offset..][0..range_len]),
        );
        if (ww_sent_bytes != @sizeOf(Station.Ww) * range_len) {
            return connection.Error.UnexpectedSendSizeWw;
        }
    }
}

pub fn sendY(line: Line) (connection.Error || mdfunc.Error)!void {
    var range_offset: usize = 0;
    for (line.connection) |range| {
        const path = try range.channel.openedPath();
        const range_len: usize =
            @as(usize, range.range.end - range.range.start) + 1;
        defer range_offset += range_len;

        const sent_bytes = try mdfunc.receiveEx(
            path,
            0,
            0xFF,
            .DevY,
            @as(i32, range.start) * @bitSizeOf(Station.Y),
            std.mem.sliceAsBytes(line.y[range_offset..][0..range_len]),
        );
        if (sent_bytes != @sizeOf(Station.Y) * range_len) {
            return connection.Error.UnexpectedSendSizeY;
        }
    }
}

pub fn sendWw(line: Line) (connection.Error || mdfunc.Error)!void {
    var range_offset: usize = 0;
    for (line.connection) |range| {
        const path = try range.channel.openedPath();
        const range_len: usize =
            @as(usize, range.range.end - range.range.start) + 1;
        defer range_offset += range_len;

        const sent_bytes = try mdfunc.receiveEx(
            path,
            0,
            0xFF,
            .DevWw,
            @as(i32, range.start) * 16, // 16 from MELSEC manual.
            std.mem.sliceAsBytes(line.ww[range_offset..][0..range_len]),
        );
        if (sent_bytes != @sizeOf(Station.Ww) * range_len) {
            return connection.Error.UnexpectedSendSizeWw;
        }
    }
}

/// Return the first station and local axis index found that holds the
/// provided slider ID.
pub fn search(line: *const Line, slider_id: u16) !?struct {
    Station,
    Station.Axis.Index,
} {
    var total_axes: Line.Axis.Id = 0;
    for (line.stations) |station| {
        for (0..3) |_axis| {
            if (total_axes == line.axes) break;
            const axis: Station.Axis.Index = @intCast(_axis);
            if (station.wr.slider_number.axis(axis) == slider_id) {
                return .{ station, axis };
            }
            total_axes += 1;
        }
    }
    return null;
}
