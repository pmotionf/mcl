//! This module represents the host PC's connection to the motion system.
const connection = @This();

const std = @import("std");
const mdfunc = @import("mdfunc");

pub const Station = @import("connection/Station.zig");
const Index = Station.Index;
const Range = Station.IndexRange;

// Restricts available channels for connection to 4 CC-Link slots.
pub const Channel = enum(u2) {
    cc_link_1slot = 0,
    cc_link_2slot = 1,
    cc_link_3slot = 2,
    cc_link_4slot = 3,

    pub fn toMdfunc(self: Channel) mdfunc.Channel {
        return switch (self) {
            .cc_link_1slot => mdfunc.Channel.@"CC-Link (1 slot)",
            .cc_link_2slot => mdfunc.Channel.@"CC-Link (2 slot)",
            .cc_link_3slot => mdfunc.Channel.@"CC-Link (3 slot)",
            .cc_link_4slot => mdfunc.Channel.@"CC-Link (4 slot)",
        };
    }

    /// Get path of channel.
    fn path(self: Channel) ?i32 {
        return paths[@intFromEnum(self)];
    }

    /// Get path of channel, asserting that the path is opened.
    fn openedPath(self: Channel) !i32 {
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
    /// Constant station list is returned as fields are mutable slices.
    fn initializedStations(self: Channel) MultiArrayStation {
        const chan_idx: u2 = @intFromEnum(self);
        if (connection.stations[chan_idx]) |s| {
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

pub fn openChannel(channel: Channel) MelsecError!void {
    const index: u2 = @intFromEnum(channel);
    paths[index] = try mdfunc.open(channel.toMdfunc());
    stations[index] = .{};
}

pub fn closeChannel(channel: Channel) (StateError || MelsecError)!void {
    const index: u2 = @intFromEnum(channel);
    if (paths[index]) |path| {
        try mdfunc.close(path);
        paths[index] = null;
        stations[index] = null;
    } else {
        return StateError.ChannelUnopened;
    }
}

/// Poll and update station inclusive range from channel.
pub fn pollStations(
    channel: Channel,
    range: Range,
) (ConnectionError || StateError || MelsecError)!void {
    const end_exclusive: u7 = @as(u7, @intCast(range.end)) + 1;
    const path: i32 = try channel.openedPath();
    const stations_list = try channel.initializedStations();

    try receiveX(
        path,
        range,
        std.mem.sliceAsBytes(stations_list.x[range.start..end_exclusive]),
    );
    try receiveWr(
        path,
        range,
        std.mem.sliceAsBytes(stations_list.wr[range.start..end_exclusive]),
    );
    try receiveY(
        path,
        range,
        std.mem.sliceAsBytes(stations_list.y[range.start..end_exclusive]),
    );
    try receiveWw(
        path,
        range,
        std.mem.sliceAsBytes(stations_list.ww[range.start..end_exclusive]),
    );
}

pub fn pollStationsX(
    channel: Channel,
    range: Range,
) (ConnectionError || StateError || MelsecError)!void {
    const path: i32 = try channel.openedPath();
    const stations_list = try channel.initializedStations();
    const end_exclusive: u7 = @as(u7, @intCast(range.end)) + 1;
    try receiveX(
        path,
        range,
        std.mem.sliceAsBytes(stations_list.x[range.start..end_exclusive]),
    );
}

pub fn pollStationsWr(
    channel: Channel,
    range: Range,
) (ConnectionError || StateError || MelsecError)!void {
    const path: i32 = try channel.openedPath();
    const stations_list = try channel.initializedStations();
    const end_exclusive: u7 = @as(u7, @intCast(range.end)) + 1;
    try receiveWr(
        path,
        range,
        std.mem.sliceAsBytes(stations_list.wr[range.start..end_exclusive]),
    );
}

/// Poll and update station from channel.
pub fn pollStation(
    channel: Channel,
    index: Index,
) (ConnectionError || StateError || MelsecError)!void {
    const path: i32 = try channel.openedPath();
    const stations_list = try channel.initializedStations();

    try receiveX(
        path,
        .{ .start = index, .end = index },
        std.mem.asBytes(&stations_list.x[index]),
    );
    try receiveWr(
        path,
        .{ .start = index, .end = index },
        std.mem.asBytes(&stations_list.wr[index]),
    );
    try receiveY(
        path,
        .{ .start = index, .end = index },
        std.mem.asBytes(&stations_list.y[index]),
    );
    try receiveWw(
        path,
        .{ .start = index, .end = index },
        std.mem.asBytes(&stations_list.ww[index]),
    );
}

pub fn pollStationX(
    channel: Channel,
    index: Index,
) (ConnectionError || StateError || MelsecError)!void {
    const path: i32 = try channel.openedPath();
    const stations_list = try channel.initializedStations();
    try receiveX(
        path,
        .{ .start = index, .end = index },
        std.mem.asBytes(&stations_list.x[index]),
    );
}

pub fn pollStationWr(
    channel: Channel,
    index: Index,
) (ConnectionError || StateError || MelsecError)!void {
    const path: i32 = try channel.openedPath();
    const stations_list = try channel.initializedStations();
    try receiveWr(
        path,
        .{ .start = index, .end = index },
        std.mem.asBytes(&stations_list.wr[index]),
    );
}

/// Get mutable reference to station state. Station state must be updated with
/// polls, and will only synchronize to motion system if sent.
pub fn station(
    channel: Channel,
    index: Index,
) StateError!Station.Reference {
    const stations_list = try channel.initializedStations();
    return .{
        .x = &stations_list.x[index],
        .y = &stations_list.y[index],
        .wr = &stations_list.wr[index],
        .ww = &stations_list.ww[index],
    };
}

pub fn stationX(channel: Channel, index: Index) StateError!*Station.X {
    const stations_list = try channel.initializedStations();
    return &stations_list.x[index];
}

pub fn stationY(channel: Channel, index: Index) StateError!*Station.Y {
    const stations_list = try channel.initializedStations();
    return &stations_list.y[index];
}

pub fn stationWr(channel: Channel, index: Index) StateError!*Station.Wr {
    const stations_list = try channel.initializedStations();
    return &stations_list.wr[index];
}

pub fn stationWw(channel: Channel, index: Index) StateError!*Station.Ww {
    const stations_list = try channel.initializedStations();
    return &stations_list.ww[index];
}

pub fn setStationY(
    channel: Channel,
    index: Index,
    /// Bitwise offset of desired field (0..).
    y_offset: u6,
) (StateError || MelsecError)!void {
    const path: i32 = try channel.openedPath();
    try mdfunc.devSetEx(
        path,
        0,
        0xFF,
        .DevY,
        @as(i32, index) * @bitSizeOf(Station.Y) + @as(i32, y_offset),
    );
}

pub fn resetStationY(
    channel: Channel,
    station_index: u6,
    /// Bitwise offset of desired field (0..).
    y_offset: u6,
) (StateError || MelsecError)!void {
    const path: i32 = try channel.openedPath();
    try mdfunc.devRstEx(
        path,
        0,
        0xFF,
        .DevY,
        @as(i32, station_index) * @bitSizeOf(Station.Y) + @as(i32, y_offset),
    );
}

/// Send station's local Ww and Y registers, in that order, to motion system.
pub fn sendStation(
    channel: Channel,
    index: Index,
) (ConnectionError || StateError || MelsecError)!void {
    const path: i32 = try channel.openedPath();
    const stations_list = try channel.initializedStations();
    try send(
        path,
        .{ .start = index, .end = index },
        .DevWw,
        std.mem.asBytes(&stations_list.ww[index]),
    );
    try send(
        path,
        .{ .start = index, .end = index },
        .DevY,
        std.mem.asBytes(&stations_list.y[index]),
    );
}

pub fn sendStationY(
    channel: Channel,
    index: Index,
) (ConnectionError || StateError || MelsecError)!void {
    const path: i32 = try channel.openedPath();
    const stations_list = try channel.initializedStations();
    try send(
        path,
        .{ .start = index, .end = index },
        .DevY,
        std.mem.asBytes(&stations_list.y[index]),
    );
}

pub fn sendStationWw(
    channel: Channel,
    index: Index,
) (ConnectionError || StateError || MelsecError)!void {
    const path: i32 = try channel.openedPath();
    const stations_list = try channel.initializedStations();
    try send(
        path,
        .{ .start = index, .end = index },
        .DevWw,
        std.mem.asBytes(&stations_list.ww[index]),
    );
}

/// Send channel's station inclusive range of local Ww and Y registers, in that
/// order, to motion system.
pub fn sendStations(
    channel: Channel,
    range: Range,
) (ConnectionError || StateError || MelsecError)!void {
    const end_exclusive: u7 = @as(u7, range.end) + 1;
    const path: i32 = try channel.openedPath();
    const stations_list = try channel.initializedStations();

    try send(
        path,
        range,
        .DevWw,
        std.mem.sliceAsBytes(stations_list.ww[range.start..end_exclusive]),
    );
    try send(
        path,
        range,
        .DevY,
        std.mem.sliceAsBytes(stations_list.y[range.start..end_exclusive]),
    );
}

pub fn sendStationsY(
    channel: Channel,
    range: Range,
) (ConnectionError || StateError || MelsecError)!void {
    const end_exclusive: u7 = @as(u7, range.end) + 1;
    const path: i32 = try channel.openedPath();
    const stations_list = try channel.initializedStations();
    try send(
        path,
        range,
        .DevY,
        std.mem.sliceAsBytes(stations_list.y[range.start..end_exclusive]),
    );
}

pub fn sendStationsWw(
    channel: Channel,
    range: Range,
) (ConnectionError || StateError || MelsecError)!void {
    const end_exclusive: u7 = @as(u7, range.end) + 1;
    const path: i32 = try channel.openedPath();
    const stations_list = try channel.initializedStations();
    try send(
        path,
        range,
        .DevWw,
        std.mem.sliceAsBytes(stations_list.ww[range.start..end_exclusive]),
    );
}

fn receiveX(
    path: i32,
    range: Range,
    dest: []u8,
) (ConnectionError || MelsecError)!void {
    const read_bytes = try mdfunc.receiveEx(
        path,
        0,
        0xFF,
        .DevX,
        @as(i32, @intCast(range.start)) * @bitSizeOf(Station.X),
        dest,
    );
    if (read_bytes != @sizeOf(Station.X) * (@as(
        usize,
        @intCast(range.end - range.start),
    ) + 1)) {
        return ConnectionError.UnexpectedReadSizeX;
    }
}

fn receiveY(
    path: i32,
    range: Range,
    dest: []u8,
) (ConnectionError || MelsecError)!void {
    const read_bytes = try mdfunc.receiveEx(
        path,
        0,
        0xFF,
        .DevY,
        @as(i32, @intCast(range.start)) * @bitSizeOf(Station.Y),
        dest,
    );
    if (read_bytes != @sizeOf(Station.Y) * (@as(
        usize,
        @intCast(range.end - range.start),
    ) + 1)) {
        return ConnectionError.UnexpectedReadSizeY;
    }
}

fn receiveWr(
    path: i32,
    range: Range,
    dest: []u8,
) (ConnectionError || MelsecError)!void {
    const read_bytes = try mdfunc.receiveEx(
        path,
        0,
        0xFF,
        .DevWr,
        @as(i32, @intCast(range.start)) * 16,
        dest,
    );
    if (read_bytes != @sizeOf(Station.Wr) * (@as(
        usize,
        @intCast(range.end - range.start),
    ) + 1)) {
        return ConnectionError.UnexpectedReadSizeWr;
    }
}

fn receiveWw(
    path: i32,
    range: Range,
    dest: []u8,
) (ConnectionError || MelsecError)!void {
    const read_bytes = try mdfunc.receiveEx(
        path,
        0,
        0xFF,
        .DevWw,
        @as(i32, @intCast(range.start)) * 16,
        dest,
    );
    if (read_bytes != @sizeOf(Station.Ww) * (@as(
        usize,
        @intCast(range.end - range.start),
    ) + 1)) {
        return ConnectionError.UnexpectedReadSizeWw;
    }
}

fn send(
    path: i32,
    range: Range,
    device: mdfunc.Device,
    source: []const u8,
) (ConnectionError || MelsecError)!void {
    const devno: i32 = 16 * @as(i32, range.start);
    const bytes_sent = try mdfunc.sendEx(path, 0, 0xFF, device, devno, source);
    switch (device) {
        .DevY => {
            if (bytes_sent != @sizeOf(Station.Y) * (@as(
                usize,
                @intCast(range.start - range.end),
            ) + 1)) {
                return ConnectionError.UnexpectedSendSizeY;
            }
        },
        .DevWw => {
            if (bytes_sent != @sizeOf(Station.Ww) * (@as(
                usize,
                @intCast(range.start - range.end),
            ) + 1)) {
                return ConnectionError.UnexpectedSendSizeWw;
            }
        },
        // Only Wr and Y devices are valid to send.
        else => unreachable,
    }
}
