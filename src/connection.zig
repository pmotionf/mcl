//! This module represents the host PC's connection to the motion system.
const std = @import("std");
const mdfunc = @import("mdfunc");

pub const Station = @import("connection/Station.zig");

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
    } else {
        return StateError.ChannelUnopened;
    }
}

/// Poll and update station inclusive range from channel.
pub fn pollStations(
    channel: Channel,
    start_station_index: u6,
    end_station_index: u6,
) (ConnectionError || StateError || MelsecError)!void {
    const end_station_exclusive: u7 = @as(u7, @intCast(end_station_index)) + 1;
    const num_stations: usize = end_station_exclusive - start_station_index;
    const index: u2 = @intFromEnum(channel);
    var path: i32 = undefined;
    var stations_list: *MultiArrayStation = undefined;
    if (paths[index]) |p| {
        path = p;
        if (stations[index]) |*s| {
            stations_list = s;
        } else {
            return StateError.ChannelStationsUninitialized;
        }
    } else {
        return StateError.ChannelUnopened;
    }

    const x_read_bytes = try mdfunc.receiveEx(
        path,
        0,
        0xFF,
        .DevX,
        @as(i32, @intCast(start_station_index)) * @bitSizeOf(Station.X),
        std.mem.sliceAsBytes(
            stations_list.x[start_station_index..end_station_exclusive],
        ),
    );
    if (x_read_bytes != @sizeOf(Station.X) * num_stations) {
        return ConnectionError.UnexpectedReadSizeX;
    }

    const wr_read_bytes = try mdfunc.receiveEx(
        path,
        0,
        0xFF,
        .DevWr,
        @as(i32, @intCast(start_station_index)) * 16,
        std.mem.sliceAsBytes(
            stations_list.wr[start_station_index..end_station_exclusive],
        ),
    );
    if (wr_read_bytes != @sizeOf(Station.Wr) * num_stations) {
        return ConnectionError.UnexpectedReadSizeWr;
    }

    const y_read_bytes = try mdfunc.receiveEx(
        path,
        0,
        0xFF,
        .DevY,
        @as(i32, @intCast(start_station_index)) * @bitSizeOf(Station.Y),
        std.mem.sliceAsBytes(
            stations_list.y[start_station_index..end_station_exclusive],
        ),
    );
    if (y_read_bytes != @sizeOf(Station.Y) * num_stations) {
        return ConnectionError.UnexpectedReadSizeY;
    }

    const ww_read_bytes = try mdfunc.receiveEx(
        path,
        0,
        0xFF,
        .DevWw,
        @as(i32, @intCast(start_station_index)) * 16,
        std.mem.sliceAsBytes(
            stations_list.ww[start_station_index..end_station_exclusive],
        ),
    );
    if (ww_read_bytes != @sizeOf(Station.Ww) * num_stations) {
        return ConnectionError.UnexpectedReadSizeWw;
    }
}

/// Poll and update station from channel.
pub fn pollStation(
    channel: Channel,
    station_index: u6,
) (ConnectionError || StateError || MelsecError)!void {
    const index: u2 = @intFromEnum(channel);
    var path: i32 = undefined;
    var stations_list: *MultiArrayStation = undefined;
    if (paths[index]) |p| {
        path = p;
        if (stations[index]) |*s| {
            stations_list = s;
        } else {
            return StateError.ChannelStationsUninitialized;
        }
    } else {
        return StateError.ChannelUnopened;
    }

    const x_read_bytes = try mdfunc.receiveEx(
        path,
        0,
        0xFF,
        .DevX,
        @as(i32, @intCast(station_index)) * @bitSizeOf(Station.X),
        std.mem.asBytes(&stations_list.x[station_index]),
    );
    if (x_read_bytes != @sizeOf(Station.X)) {
        return ConnectionError.UnexpectedReadSizeX;
    }

    const wr_read_bytes = try mdfunc.receiveEx(
        path,
        0,
        0xFF,
        .DevWr,
        @as(i32, @intCast(station_index)) * 16,
        std.mem.asBytes(&stations_list.wr[station_index]),
    );
    if (wr_read_bytes != @sizeOf(Station.Wr)) {
        return ConnectionError.UnexpectedReadSizeWr;
    }

    const y_read_bytes = try mdfunc.receiveEx(
        path,
        0,
        0xFF,
        .DevY,
        @as(i32, @intCast(station_index)) * @bitSizeOf(Station.Y),
        std.mem.asBytes(&stations_list.y[station_index]),
    );
    if (y_read_bytes != @sizeOf(Station.Y)) {
        return ConnectionError.UnexpectedReadSizeY;
    }

    const ww_read_bytes = try mdfunc.receiveEx(
        path,
        0,
        0xFF,
        .DevWw,
        @as(i32, @intCast(station_index)) * 16,
        std.mem.asBytes(&stations_list.ww[station_index]),
    );
    if (ww_read_bytes != @sizeOf(Station.Ww)) {
        return ConnectionError.UnexpectedReadSizeWw;
    }
}

/// Get mutable reference to station state. Station state must be updated with
/// polls, and will only synchronize to motion system if sent.
pub fn station(
    channel: Channel,
    station_index: u6,
) StateError!Station.Reference {
    const index: u2 = @intFromEnum(channel);
    if (stations[index]) |*s| {
        return .{
            .x = &s.x[station_index],
            .y = &s.y[station_index],
            .wr = &s.wr[station_index],
            .ww = &s.ww[station_index],
        };
    } else {
        return StateError.ChannelStationsUninitialized;
    }
}

pub fn stationX(channel: Channel, station_index: u6) StateError!*Station.X {
    const index: u2 = @intFromEnum(channel);
    if (stations[index]) |*s| {
        return &s.x[station_index];
    } else {
        return StateError.ChannelStationsUninitialized;
    }
}

pub fn stationY(channel: Channel, station_index: u6) StateError!*Station.Y {
    const index: u2 = @intFromEnum(channel);
    if (stations[index]) |*s| {
        return &s.y[station_index];
    } else {
        return StateError.ChannelStationsUninitialized;
    }
}

pub fn stationWr(channel: Channel, station_index: u6) StateError!*Station.Wr {
    const index: u2 = @intFromEnum(channel);
    if (stations[index]) |*s| {
        return &s.wr[station_index];
    } else {
        return StateError.ChannelStationsUninitialized;
    }
}

pub fn stationWw(channel: Channel, station_index: u6) StateError!*Station.Ww {
    const index: u2 = @intFromEnum(channel);
    if (stations[index]) |*s| {
        return &s.ww[station_index];
    } else {
        return StateError.ChannelStationsUninitialized;
    }
}

pub fn setStationY(
    channel: Channel,
    station_index: u6,
    /// Bitwise offset of desired field (0..).
    y_offset: u6,
) (StateError || MelsecError)!void {
    const index: u2 = @intFromEnum(channel);
    const path: i32 = if (paths[index]) |p|
        p
    else
        return StateError.ChannelUnopened;

    try mdfunc.devSetEx(
        path,
        0,
        0xFF,
        .DevY,
        @as(i32, station_index) * @bitSizeOf(Station.Y) + @as(i32, y_offset),
    );
}

pub fn resetStationY(
    channel: Channel,
    station_index: u6,
    /// Bitwise offset of desired field (0..).
    y_offset: u6,
) (StateError || MelsecError)!void {
    const index: u2 = @intFromEnum(channel);
    const path: i32 = if (paths[index]) |p|
        p
    else
        return StateError.ChannelUnopened;

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
    station_index: u6,
) (ConnectionError || StateError || MelsecError)!void {
    const index: u2 = @intFromEnum(channel);
    const path: i32 = if (paths[index]) |p|
        p
    else
        return StateError.ChannelUnopened;

    if (stations[index]) |*stations_list| {
        const devno: i32 = 16 * @as(i32, station_index);

        const ww_bytes_sent: i32 = try mdfunc.sendEx(
            path,
            0,
            0xFF,
            .DevWw,
            devno,
            std.mem.asBytes(&stations_list.ww[station_index]),
        );
        if (ww_bytes_sent != @sizeOf(Station.Ww)) {
            return ConnectionError.UnexpectedSendSizeWw;
        }

        const y_bytes_sent: i32 = try mdfunc.sendEx(
            path,
            0,
            0xFF,
            .DevY,
            devno,
            std.mem.asBytes(&stations_list.y[station_index]),
        );
        if (y_bytes_sent != @sizeOf(Station.Y)) {
            return ConnectionError.UnexpectedSendSizeY;
        }
    } else {
        return StateError.ChannelStationsUninitialized;
    }
}

pub fn sendStationY(
    channel: Channel,
    station_index: u6,
) (ConnectionError || StateError || MelsecError)!void {
    const index: u2 = @intFromEnum(channel);
    const path: i32 = if (paths[index]) |p|
        p
    else
        return StateError.ChannelUnopened;

    if (stations[index]) |*stations_list| {
        const devno: i32 = 16 * @as(i32, station_index);
        const bytes_sent: i32 = try mdfunc.sendEx(
            path,
            0,
            0xFF,
            .DevY,
            devno,
            std.mem.asBytes(&stations_list.y[station_index]),
        );
        if (bytes_sent != @sizeOf(Station.Y)) {
            return ConnectionError.UnexpectedSendSizeY;
        }
    }
}

pub fn sendStationWw(
    channel: Channel,
    station_index: u6,
) (ConnectionError || StateError || MelsecError)!void {
    const index: u2 = @intFromEnum(channel);
    const path: i32 = if (paths[index]) |p|
        p
    else
        return StateError.ChannelUnopened;

    if (stations[index]) |*stations_list| {
        const devno: i32 = 16 * @as(i32, station_index);
        const bytes_sent: i32 = try mdfunc.sendEx(
            path,
            0,
            0xFF,
            .DevWw,
            devno,
            std.mem.asBytes(&stations_list.ww[station_index]),
        );
        if (bytes_sent != @sizeOf(Station.Ww)) {
            return ConnectionError.UnexpectedSendSizeWw;
        }
    }
}

/// Send channel's station inclusive range of local Ww and Y registers, in that
/// order, to motion system.
pub fn sendStations(
    channel: Channel,
    start_station_index: u6,
    end_station_index: u6,
) (ConnectionError || StateError || MelsecError)!void {
    const end_station_exclusive: u7 = @as(u7, end_station_index) + 1;
    const num_stations: usize = end_station_exclusive - start_station_index;
    const index: u2 = @intFromEnum(channel);
    const path: i32 = if (paths[index]) |p|
        p
    else
        return StateError.ChannelUnopened;

    if (stations[index]) |*stations_list| {
        const devno: i32 = 16 * @as(i32, start_station_index);

        const ww_bytes_sent: i32 = try mdfunc.sendEx(
            path,
            0,
            0xFF,
            .DevWw,
            devno,
            std.mem.sliceAsBytes(
                stations_list.ww[start_station_index..end_station_exclusive],
            ),
        );
        if (ww_bytes_sent != @sizeOf(Station.Ww) * num_stations) {
            return ConnectionError.UnexpectedSendSizeWw;
        }

        const y_bytes_sent: i32 = try mdfunc.sendEx(
            path,
            0,
            0xFF,
            .DevY,
            devno,
            std.mem.sliceAsBytes(
                stations_list.y[start_station_index..end_station_exclusive],
            ),
        );
        if (y_bytes_sent != @sizeOf(Station.Y) * num_stations) {
            return ConnectionError.UnexpectedSendSizeY;
        }
    }
}

pub fn sendStationsY(
    channel: Channel,
    start_station_index: u6,
    end_station_index: u6,
) (ConnectionError || StateError || MelsecError)!void {
    const end_station_exclusive: u7 = @as(u7, end_station_index) + 1;
    const num_stations: usize = end_station_exclusive - start_station_index;
    const index: u2 = @intFromEnum(channel);
    const path: i32 = if (paths[index]) |p|
        p
    else
        return StateError.ChannelUnopened;

    if (stations[index]) |*stations_list| {
        const devno: i32 = 16 * @as(i32, start_station_index);
        const y_bytes_sent: i32 = try mdfunc.sendEx(
            path,
            0,
            0xFF,
            .DevY,
            devno,
            std.mem.sliceAsBytes(
                stations_list.y[start_station_index..end_station_exclusive],
            ),
        );
        if (y_bytes_sent != @sizeOf(Station.Y) * num_stations) {
            return ConnectionError.UnexpectedSendSizeY;
        }
    }
}

pub fn sendStationsWw(
    channel: Channel,
    start_station_index: u6,
    end_station_index: u6,
) (ConnectionError || StateError || MelsecError)!void {
    const end_station_exclusive: u7 = @as(u7, end_station_index) + 1;
    const num_stations: usize = end_station_exclusive - start_station_index;
    const index: u2 = @intFromEnum(channel);
    const path: i32 = if (paths[index]) |p|
        p
    else
        return StateError.ChannelUnopened;

    if (stations[index]) |*stations_list| {
        const devno: i32 = 16 * @as(i32, start_station_index);
        const ww_bytes_sent: i32 = try mdfunc.sendEx(
            path,
            0,
            0xFF,
            .DevWw,
            devno,
            std.mem.sliceAsBytes(
                stations_list.ww[start_station_index..end_station_exclusive],
            ),
        );
        if (ww_bytes_sent != @sizeOf(Station.Ww) * num_stations) {
            return ConnectionError.UnexpectedSendSizeWw;
        }
    }
}
