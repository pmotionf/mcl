//! This module represents the host PC's connection to the motion system.
const connection = @This();

const std = @import("std");
const mdfunc = @import("mdfunc");

pub const Station = @import("connection/Station.zig");

// Restricts available channels for connection to 4 CC-Link slots.
pub const Channel = enum(u2) {
    cc_link_1slot = 0,
    cc_link_2slot = 1,
    cc_link_3slot = 2,
    cc_link_4slot = 3,

    pub const Index = struct {
        index: Station.Index,
        channel: Channel,

        /// Poll and update station from channel.
        pub fn poll(
            index: Index,
        ) (ConnectionError || StateError || MelsecError)!void {
            const p: i32 = try index.channel.openedPath();
            var stations_list = try index.channel.initializedStations();

            try receiveX(
                p,
                .{ .start = index.index, .end = index.index },
                std.mem.asBytes(&stations_list.x[index.index]),
            );
            try receiveWr(
                p,
                .{ .start = index.index, .end = index.index },
                std.mem.asBytes(&stations_list.wr[index.index]),
            );
            try receiveY(
                p,
                .{ .start = index.index, .end = index.index },
                std.mem.asBytes(&stations_list.y[index.index]),
            );
            try receiveWw(
                p,
                .{ .start = index.index, .end = index.index },
                std.mem.asBytes(&stations_list.ww[index.index]),
            );
        }

        pub fn pollX(
            index: Index,
        ) (ConnectionError || StateError || MelsecError)!void {
            const p: i32 = try index.channel.openedPath();
            var stations_list = try index.channel.initializedStations();
            try receiveX(
                p,
                .{ .start = index.index, .end = index.index },
                std.mem.asBytes(&stations_list.x[index.index]),
            );
        }

        pub fn pollY(
            index: Index,
        ) (ConnectionError || StateError || MelsecError)!void {
            const p: i32 = try index.channel.openedPath();
            var stations_list = try index.channel.initializedStations();
            try receiveY(
                p,
                .{ .start = index.index, .end = index.index },
                std.mem.asBytes(&stations_list.y[index.index]),
            );
        }

        pub fn pollWr(
            index: Index,
        ) (ConnectionError || StateError || MelsecError)!void {
            const p: i32 = try index.channel.openedPath();
            var stations_list = try index.channel.initializedStations();
            try receiveWr(
                p,
                .{ .start = index.index, .end = index.index },
                std.mem.asBytes(&stations_list.wr[index.index]),
            );
        }

        pub fn pollWw(
            index: Index,
        ) (ConnectionError || StateError || MelsecError)!void {
            const p: i32 = try index.channel.openedPath();
            var stations_list = try index.channel.initializedStations();
            try receiveWw(
                p,
                .{ .start = index.index, .end = index.index },
                std.mem.asBytes(&stations_list.ww[index.index]),
            );
        }

        /// Get mutable reference to station state. Station state must be
        /// updated with polls, and synchronizes to motion system when sent.
        pub fn reference(index: Channel.Index) StateError!Station.Reference {
            var stations_list = try index.channel.initializedStations();
            return .{
                .x = &stations_list.x[index.index],
                .y = &stations_list.y[index.index],
                .wr = &stations_list.wr[index.index],
                .ww = &stations_list.ww[index.index],
            };
        }

        pub fn X(index: Index) StateError!*Station.X {
            var stations_list = try index.channel.initializedStations();
            return &stations_list.x[index.index];
        }

        pub fn Y(index: Index) StateError!*Station.Y {
            var stations_list = try index.channel.initializedStations();
            return &stations_list.y[index.index];
        }

        pub fn Wr(index: Index) StateError!*Station.Wr {
            var stations_list = try index.channel.initializedStations();
            return &stations_list.wr[index.index];
        }

        pub fn Ww(index: Index) StateError!*Station.Ww {
            var stations_list = try index.channel.initializedStations();
            return &stations_list.ww[index.index];
        }

        pub fn setY(
            index: Index,
            /// Bitwise offset of desired field (0..).
            offset: u6,
        ) (StateError || MelsecError)!void {
            const p: i32 = try index.channel.openedPath();
            const devno: i32 = @as(i32, index.index) * @bitSizeOf(Station.Y) +
                @as(i32, offset);
            try mdfunc.devSetEx(p, 0, 0xFF, .DevY, devno);
        }

        pub fn resetY(
            index: Index,
            /// Bitwise offset of desired field (0..).
            offset: u6,
        ) (StateError || MelsecError)!void {
            const p: i32 = try index.channel.openedPath();
            const devno: i32 = @as(i32, index.index) * @bitSizeOf(Station.Y) +
                @as(i32, offset);
            try mdfunc.devRstEx(p, 0, 0xFF, .DevY, devno);
        }

        /// Send station's local Ww and Y registers to motion system.
        pub fn send(
            index: Index,
        ) (ConnectionError || StateError || MelsecError)!void {
            const p: i32 = try index.channel.openedPath();
            const stations_list = try index.channel.initializedStations();
            try connection.sendWw(
                p,
                .{ .start = index.index, .end = index.index },
                std.mem.asBytes(&stations_list.ww[index.index]),
            );
            try connection.sendY(
                p,
                .{ .start = index.index, .end = index.index },
                std.mem.asBytes(&stations_list.y[index.index]),
            );
        }

        pub fn sendY(
            index: Channel.Index,
        ) (ConnectionError || StateError || MelsecError)!void {
            const p: i32 = try index.channel.openedPath();
            const stations_list = try index.channel.initializedStations();
            try connection.sendY(
                p,
                .{ .start = index.index, .end = index.index },
                std.mem.asBytes(&stations_list.y[index.index]),
            );
        }

        pub fn sendWw(
            index: Channel.Index,
        ) (ConnectionError || StateError || MelsecError)!void {
            const p: i32 = try index.channel.openedPath();
            const stations_list = try index.channel.initializedStations();
            try connection.sendWw(
                p,
                .{ .start = index.index, .end = index.index },
                std.mem.asBytes(&stations_list.ww[index.index]),
            );
        }
    };

    pub const Range = struct {
        indices: Station.IndexRange,
        channel: Channel,

        pub fn len(range: Range) usize {
            return @as(usize, range.indices.end - range.indices.start) + 1;
        }

        pub fn index(range: Range, i: usize) !Index {
            if (i >= range.len()) return error.IndexOutOfRange;
            const offset: Station.Index = @intCast(i);
            return .{
                .index = range.indices.start + offset,
                .channel = range.channel,
            };
        }

        /// Poll and update station inclusive range from channel.
        pub fn poll(
            range: Range,
        ) (ConnectionError || StateError || MelsecError)!void {
            const end_exclusive: u7 = @as(u7, range.indices.end) + 1;
            const p: i32 = try range.channel.openedPath();
            var stations_list = try range.channel.initializedStations();
            const start: Station.Index = range.indices.start;

            try receiveX(
                p,
                range.indices,
                std.mem.sliceAsBytes(stations_list.x[start..end_exclusive]),
            );
            try receiveWr(
                p,
                range.indices,
                std.mem.sliceAsBytes(stations_list.wr[start..end_exclusive]),
            );
            try receiveY(
                p,
                range.indices,
                std.mem.sliceAsBytes(stations_list.y[start..end_exclusive]),
            );
            try receiveWw(
                p,
                range.indices,
                std.mem.sliceAsBytes(stations_list.ww[start..end_exclusive]),
            );
        }

        pub fn pollX(
            range: Range,
        ) (ConnectionError || StateError || MelsecError)!void {
            const p: i32 = try range.channel.openedPath();
            var stations_list = try range.channel.initializedStations();
            const end_exclusive: u7 = @as(u7, @intCast(range.indices.end)) + 1;
            const start = range.indices.start;
            try receiveX(
                p,
                range.indices,
                std.mem.sliceAsBytes(stations_list.x[start..end_exclusive]),
            );
        }

        pub fn pollY(
            range: Range,
        ) (ConnectionError || StateError || MelsecError)!void {
            const p: i32 = try range.channel.openedPath();
            var stations_list = try range.channel.initializedStations();
            const end_exclusive: u7 = @as(u7, @intCast(range.indices.end)) + 1;
            const start = range.indices.start;
            try receiveY(
                p,
                range.indices,
                std.mem.sliceAsBytes(stations_list.y[start..end_exclusive]),
            );
        }

        pub fn pollWr(
            range: Range,
        ) (ConnectionError || StateError || MelsecError)!void {
            const p: i32 = try range.channel.openedPath();
            var stations_list = try range.channel.initializedStations();
            const end_exclusive: u7 = @as(u7, range.indices.end) + 1;
            const start = range.indices.start;
            try receiveWr(
                p,
                range.indices,
                std.mem.sliceAsBytes(stations_list.wr[start..end_exclusive]),
            );
        }

        pub fn pollWw(
            range: Range,
        ) (ConnectionError || StateError || MelsecError)!void {
            const p: i32 = try range.channel.openedPath();
            var stations_list = try range.channel.initializedStations();
            const end_exclusive: u7 = @as(u7, range.indices.end) + 1;
            const start = range.indices.start;
            try receiveWw(
                p,
                range.indices,
                std.mem.sliceAsBytes(stations_list.ww[start..end_exclusive]),
            );
        }

        /// Send channel's station inclusive range of local Ww and Y registers
        /// to motion system.
        pub fn send(
            range: Range,
        ) (ConnectionError || StateError || MelsecError)!void {
            const end_exclusive: u7 = @as(u7, range.indices.end) + 1;
            const p: i32 = try range.channel.openedPath();
            const stations_list = try range.channel.initializedStations();
            const start = range.indices.start;

            try connection.sendWw(
                p,
                range.indices,
                std.mem.sliceAsBytes(stations_list.ww[start..end_exclusive]),
            );
            try connection.sendY(
                p,
                range.indices,
                std.mem.sliceAsBytes(stations_list.y[start..end_exclusive]),
            );
        }

        pub fn sendY(
            range: Range,
        ) (ConnectionError || StateError || MelsecError)!void {
            const end_exclusive: u7 = @as(u7, range.indices.end) + 1;
            const p: i32 = try range.channel.openedPath();
            const stations_list = try range.channel.initializedStations();
            const start = range.indices.start;

            try connection.sendY(
                p,
                range.indices,
                std.mem.sliceAsBytes(stations_list.y[start..end_exclusive]),
            );
        }

        pub fn sendWw(
            range: Range,
        ) (ConnectionError || StateError || MelsecError)!void {
            const end_exclusive: u7 = @as(u7, range.indices.end) + 1;
            const p: i32 = try range.channel.openedPath();
            const stations_list = try range.channel.initializedStations();
            const start = range.indices.start;

            try connection.sendWw(
                p,
                range.indices,
                std.mem.sliceAsBytes(stations_list.ww[start..end_exclusive]),
            );
        }
    };

    pub fn toMdfunc(self: Channel) mdfunc.Channel {
        return switch (self) {
            .cc_link_1slot => mdfunc.Channel.@"CC-Link (1 slot)",
            .cc_link_2slot => mdfunc.Channel.@"CC-Link (2 slot)",
            .cc_link_3slot => mdfunc.Channel.@"CC-Link (3 slot)",
            .cc_link_4slot => mdfunc.Channel.@"CC-Link (4 slot)",
        };
    }

    pub fn open(channel: Channel) MelsecError!void {
        const index: u2 = @intFromEnum(channel);
        if (mdfunc.open(channel.toMdfunc())) |p| {
            paths[index] = p;
        } else |err| switch (err) {
            connection.MelsecError.@"66: Channel-opened error" => {},
            else => |e| return e,
        }
        connection.stations[index] = .{};
    }

    pub fn close(channel: Channel) (StateError || MelsecError)!void {
        const index: u2 = @intFromEnum(channel);
        if (paths[index]) |p| {
            try mdfunc.close(p);
            paths[index] = null;
            connection.stations[index] = null;
        } else {
            return StateError.ChannelUnopened;
        }
    }

    /// Get path of channel.
    fn path(self: Channel) ?i32 {
        return paths[@intFromEnum(self)];
    }

    /// Get path of channel, asserting that the path is opened.
    fn openedPath(self: Channel) StateError!i32 {
        const chan_idx: u2 = @intFromEnum(self);
        if (paths[chan_idx]) |p| {
            return p;
        } else {
            return StateError.ChannelUnopened;
        }
    }

    /// Get stations of channel. Constant station list is returned as fields
    /// are mutable slices.
    fn stations(self: Channel) ?MultiArrayStation {
        return connection.stations[@intFromEnum(self)];
    }

    /// Get stations of channel asserting that the station list is initialized.
    fn initializedStations(self: Channel) StateError!*MultiArrayStation {
        const chan_idx: u2 = @intFromEnum(self);
        if (connection.stations[chan_idx]) |*s| {
            return s;
        } else {
            return StateError.ChannelStationsUninitialized;
        }
    }
};

// Up to 64 stations connected per path.
const max_stations: comptime_int = 64;

const MultiArrayStation = struct {
    x: [max_stations]Station.X = [_]Station.X{.{}} ** max_stations,
    y: [max_stations]Station.Y = [_]Station.Y{.{}} ** max_stations,
    wr: [max_stations]Station.Wr = [_]Station.Wr{.{}} ** max_stations,
    ww: [max_stations]Station.Ww = [_]Station.Ww{.{}} ** max_stations,
};

// Up to 4 paths, one per CC-Link slot.
var paths: [4]?i32 = .{
    null,
    null,
    null,
    null,
};

var stations: [4]?MultiArrayStation = .{
    null,
    null,
    null,
    null,
};

pub const MelsecError = mdfunc.Error;
pub const ConnectionError = error{
    UnexpectedReadSizeX,
    UnexpectedReadSizeY,
    UnexpectedReadSizeWr,
    UnexpectedReadSizeWw,
    UnexpectedSendSizeY,
    UnexpectedSendSizeWw,
};
pub const StateError = error{
    ChannelUnopened,
    ChannelStationsUninitialized,
};

fn receiveX(
    path: i32,
    range: Station.IndexRange,
    dest: []u8,
) (ConnectionError || MelsecError)!void {
    const read_bytes = try mdfunc.receiveEx(
        path,
        0,
        0xFF,
        .DevX,
        @as(i32, range.start) * @bitSizeOf(Station.X),
        dest,
    );
    const range_len: usize = @as(usize, range.end - range.start) + 1;
    if (read_bytes != @sizeOf(Station.X) * range_len) {
        return ConnectionError.UnexpectedReadSizeX;
    }
}

fn receiveY(
    path: i32,
    range: Station.IndexRange,
    dest: []u8,
) (ConnectionError || MelsecError)!void {
    const read_bytes = try mdfunc.receiveEx(
        path,
        0,
        0xFF,
        .DevY,
        @as(i32, range.start) * @bitSizeOf(Station.Y),
        dest,
    );
    const range_len: usize = @as(usize, range.end - range.start) + 1;
    if (read_bytes != @sizeOf(Station.Y) * range_len) {
        return ConnectionError.UnexpectedReadSizeY;
    }
}

fn receiveWr(
    path: i32,
    range: Station.IndexRange,
    dest: []u8,
) (ConnectionError || MelsecError)!void {
    const read_bytes = try mdfunc.receiveEx(
        path,
        0,
        0xFF,
        .DevWr,
        @as(i32, range.start) * 16,
        dest,
    );
    const range_len: usize = @as(usize, range.end - range.start) + 1;
    if (read_bytes != @sizeOf(Station.Wr) * range_len) {
        return ConnectionError.UnexpectedReadSizeWr;
    }
}

fn receiveWw(
    path: i32,
    range: Station.IndexRange,
    dest: []u8,
) (ConnectionError || MelsecError)!void {
    const read_bytes = try mdfunc.receiveEx(
        path,
        0,
        0xFF,
        .DevWw,
        @as(i32, range.start) * 16,
        dest,
    );
    const range_len: usize = @as(usize, range.end - range.start) + 1;
    if (read_bytes != @sizeOf(Station.Ww) * range_len) {
        return ConnectionError.UnexpectedReadSizeWw;
    }
}

fn sendY(
    path: i32,
    range: Station.IndexRange,
    source: []const u8,
) (ConnectionError || MelsecError)!void {
    const bytes_sent = try mdfunc.sendEx(
        path,
        0,
        0xFF,
        .DevY,
        @as(i32, range.start) * @bitSizeOf(Station.Y),
        source,
    );
    const range_len: usize = @as(usize, range.end - range.start) + 1;
    if (bytes_sent != @sizeOf(Station.Y) * range_len) {
        return ConnectionError.UnexpectedSendSizeY;
    }
}

fn sendWw(
    path: i32,
    range: Station.IndexRange,
    source: []const u8,
) (ConnectionError || MelsecError)!void {
    const bytes_sent = try mdfunc.sendEx(
        path,
        0,
        0xFF,
        .DevWw,
        @as(i32, range.start) * 16,
        source,
    );
    const range_len: usize = @as(usize, range.end - range.start) + 1;
    if (bytes_sent != @sizeOf(Station.Ww) * range_len) {
        return ConnectionError.UnexpectedSendSizeWw;
    }
}
