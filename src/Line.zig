const Line = @This();
const Axis = @import("Axis.zig");

const std = @import("std");
const mdfunc = @import("mdfunc");
const connection = @import("connection.zig");
const Station = @import("Station.zig");

// The maximum number of stations is also the maximum number of lines, as
// there can be a minimum of one station per line.
pub const Index = Station.Index;
pub const Id = Station.Id;

pub const ConnectionRange = struct {
    channel: connection.Channel,
    range: connection.Range,
};

index: Index,
id: Id,

/// Axes that make up line. Each axis contains both its own line index and
/// local station index.
axes: []Axis,

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
            @as(i32, range.range.start) * 16, // 16 from MELSEC manual.
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
            @as(i32, range.range.start) * @bitSizeOf(Station.Y),
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
            @as(i32, range.range.start) * 16, // 16 from MELSEC manual.
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
            @as(i32, range.range.start) * @bitSizeOf(Station.Y),
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
            @as(i32, range.range.start) * 16, // 16 from MELSEC manual.
            std.mem.sliceAsBytes(line.ww[range_offset..][0..range_len]),
        );
        if (sent_bytes != @sizeOf(Station.Ww) * range_len) {
            return connection.Error.UnexpectedSendSizeWw;
        }
    }
}

/// Return the axis of the specified slider, if found in the system. If the
/// slider is split across two axes, then the auxiliary axis will be included
/// in the result tuple.
pub fn search(line: *const Line, slider_id: u16) !?struct { Axis, ?Axis } {
    var result: struct { Axis, ?Axis } = .{ undefined, null };

    for (line.axes) |axis| {
        const station = axis.station;
        const wr = station.wr;
        if (wr.slider_number.axis(axis.index.station) == slider_id) {
            result.@"0" = axis;

            if (axis.index.station == 2 and axis.id.line < line.axes.len) {
                const next_axis = line.axes[axis.index.line + 1];
                const next_station = next_axis.station;
                const next_wr = next_station.wr;

                if (next_wr.slider_number.axis(
                    next_axis.index.station,
                ) == slider_id) {
                    result.@"1" = next_axis;
                }
            }

            break;
        }
    } else {
        return null;
    }

    // If there are two detected contiguous axes, determine which is primary
    // and auxiliary.
    if (result.@"1") |*aux| {
        const main: *Axis = &result.@"0";
        const station = main.station;
        const wr = station.wr;
        const state = wr.slider_state.axis(main.index.station);
        if (state == .NextAxisAuxiliary or state == .NextAxisCompleted or
            state == .PrevAxisAuxiliary or state == .PrevAxisCompleted)
        {
            const temp = main.*;
            main.* = aux.*;
            aux.* = temp;
        } else if (state == .None) {
            const aux_station: *const Station = aux.station;
            const aux_wr = aux_station.wr;
            const aux_state = aux_wr.slider_state.axis(aux.index.station);
            if (aux_state != .None and
                aux_state != .NextAxisAuxiliary and
                aux_state != .NextAxisCompleted and
                aux_state != .PrevAxisAuxiliary and
                aux_state != .PrevAxisCompleted)
            {
                const temp = main.*;
                main.* = aux.*;
                aux.* = temp;
            }
        }
    }

    return result;
}
