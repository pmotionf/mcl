const std = @import("std");

const v = @import("version");
const mdfunc = @import("mdfunc");

pub const Station = @import("Station.zig");
pub const Channel = mdfunc.Channel;
pub const StationReference = struct {
    x: *Station.X,
    y: *Station.Y,
    wr: *Station.Wr,
    ww: *Station.Ww,
};

const MultiArrayStation = struct {
    x: [64]Station.X = [_]Station.X{.{}} ** 64,
    y: [64]Station.Y = [_]Station.Y{.{}} ** 64,
    wr: [64]Station.Wr = [_]Station.Wr{.{}} ** 64,
    ww: [64]Station.Ww = [_]Station.Ww{.{}} ** 64,
};

/// Up to 4 paths, each path representing a CC-Link card in a different slot.
var paths: [4]?i32 = .{
    null,
    null,
    null,
    null,
};
/// Maximum of 64 Stations per connected CC-Link card, at 1x extended cyclic.
/// At 4x, should be a maximum of 16 Stations per connected CC-Link card.
var stations: [4]?MultiArrayStation = .{
    null,
    null,
    null,
    null,
};

pub fn version() std.SemanticVersion {
    // Version string guaranteed to be correct, defined in `version.zig`.
    return std.SemanticVersion.parse(v.mcl_version) catch unreachable;
}

pub fn openChannel(channel: Channel) !void {
    const index = try getChannelIndex(channel);
    paths[index] = try mdfunc.open(channel);
    stations[index] = .{};
}

pub fn closeChannel(channel: Channel) !void {
    const index = try getChannelIndex(channel);
    if (paths[index]) |path| {
        try mdfunc.close(path);
        paths[index] = null;
        stations[index] = null;
    } else {
        return error.ChannelUnopened;
    }
}

pub fn pollChannel(
    channel: Channel,
    start_station_index: u6,
    end_station_index: u6,
) !void {
    if (end_station_index < start_station_index) {
        return error.InvalidStationIndex;
    }
    const end_station_exclusive: u7 = @as(u7, @intCast(end_station_index)) + 1;
    const num_stations: usize = end_station_exclusive - start_station_index;
    const index = try getChannelIndex(channel);
    var path: i32 = undefined;
    var stations_list: *MultiArrayStation = undefined;
    if (paths[index]) |p| {
        path = p;
        if (stations[index]) |*s| {
            stations_list = s;
        } else {
            return error.ChannelStationsUninitialized;
        }
    } else {
        return error.ChannelUnopened;
    }
    const x_read_bytes = try mdfunc.receiveEx(
        path,
        0,
        0xFF,
        .DevX,
        0x0,
        std.mem.sliceAsBytes(
            stations_list.x[start_station_index..end_station_exclusive],
        ),
    );
    if (x_read_bytes != @sizeOf(Station.X) * num_stations) {
        return error.UnexpectedXReadSize;
    }
    const wr_read_bytes = try mdfunc.receiveEx(
        path,
        0,
        0xFF,
        .DevY,
        0x0,
        std.mem.sliceAsBytes(
            stations_list.wr[start_station_index..end_station_exclusive],
        ),
    );
    if (wr_read_bytes != @sizeOf(Station.Wr) * num_stations) {
        return error.UnexpectedWrReadSize;
    }
    const y_read_bytes = try mdfunc.receiveEx(
        path,
        0,
        0xFF,
        .DevY,
        0x0,
        std.mem.sliceAsBytes(
            stations_list.y[start_station_index..end_station_exclusive],
        ),
    );
    if (y_read_bytes != @sizeOf(Station.Y) * num_stations) {
        return error.UnexpectedYReadSize;
    }
    const ww_read_bytes = try mdfunc.receiveEx(
        path,
        0,
        0xFF,
        .DevWw,
        0x0,
        std.mem.sliceAsBytes(
            stations_list.ww[start_station_index..end_station_exclusive],
        ),
    );
    if (ww_read_bytes != @sizeOf(Station.Ww) * num_stations) {
        return error.UnexpectedWwReadSize;
    }
}

pub fn pollStation(channel: Channel, station_index: u6) !void {
    const index = try getChannelIndex(channel);
    const path: i32 = try getPath(channel);

    const stations_list: *MultiArrayStation = if (stations[index]) |*s|
        s
    else
        return error.ChannelStationsUninitialized;

    const x_read_bytes = try mdfunc.receiveEx(
        path,
        0,
        0xFF,
        .DevX,
        @as(i32, @intCast(station_index)) * @bitSizeOf(Station.X),
        std.mem.asBytes(&stations_list.x[station_index]),
    );
    if (x_read_bytes != @sizeOf(Station.X)) {
        return error.UnexpectedXReadSize;
    }
    const wr_read_bytes = try mdfunc.receiveEx(
        path,
        0,
        0xFF,
        .DevY,
        @as(i32, @intCast(station_index)) * @bitSizeOf(Station.Wr),
        std.mem.asBytes(&stations_list.wr[station_index]),
    );
    if (wr_read_bytes != @sizeOf(Station.Wr)) {
        return error.UnexpectedWrReadSize;
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
        return error.UnexpectedYReadSize;
    }
    const ww_read_bytes = try mdfunc.receiveEx(
        path,
        0,
        0xFF,
        .DevWw,
        @as(i32, @intCast(station_index)) * @bitSizeOf(Station.Ww),
        std.mem.asBytes(&stations_list.ww[station_index]),
    );
    if (ww_read_bytes != @sizeOf(Station.Ww)) {
        return error.UnexpectedWwReadSize;
    }
}

pub fn getStation(channel: Channel, station_index: u6) !StationReference {
    const index = try getChannelIndex(channel);
    if (stations[index]) |*s| {
        return .{
            .x = &s.x[station_index],
            .y = &s.y[station_index],
            .wr = &s.wr[station_index],
            .ww = &s.ww[station_index],
        };
    } else {
        return error.ChannelStationsUninitialized;
    }
}

pub fn getStationX(channel: Channel, station_index: u6) !*Station.X {
    const index = try getChannelIndex(channel);
    if (stations[index]) |*s| {
        return &s.x[station_index];
    } else {
        return error.ChannelStationsUninitialized;
    }
}

pub fn getStationY(channel: Channel, station_index: u6) !*Station.Y {
    const index = try getChannelIndex(channel);
    if (stations[index]) |*s| {
        return &s.y[station_index];
    } else {
        return error.ChannelStationsUninitialized;
    }
}

pub fn getStationWr(channel: Channel, station_index: u6) !*Station.Wr {
    const index = try getChannelIndex(channel);
    if (stations[index]) |*s| {
        return &s.wr[station_index];
    } else {
        return error.ChannelStationsUninitialized;
    }
}

pub fn getStationWw(channel: Channel, station_index: u6) !*Station.Ww {
    const index = try getChannelIndex(channel);
    if (stations[index]) |*s| {
        return &s.ww[station_index];
    } else {
        return error.ChannelStationsUninitialized;
    }
}

pub fn setStationY(channel: Channel, station_index: u6, y_index: u6) !void {
    const path: i32 = try getPath(channel);
    try mdfunc.devSetEx(
        path,
        0,
        0xFF,
        .DevY,
        @as(i32, station_index) * @bitSizeOf(Station.Y) + @as(i32, y_index),
    );
}

pub fn resetStationY(channel: Channel, station_index: u6, y_index: u6) !void {
    const path: i32 = try getPath(channel);
    try mdfunc.devRstEx(
        path,
        0,
        0xFF,
        .DevY,
        @as(i32, station_index) * @bitSizeOf(Station.Y) + @as(i32, y_index),
    );
}

pub fn sendStationY(channel: Channel, station_index: u6) !void {
    const index = try getChannelIndex(channel);
    const path: i32 = try getPath(channel);
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
            return error.UnexpectedYSendSize;
        }
    } else {
        return error.ChannelStationsUninitialized;
    }
}

pub fn sendStationWw(channel: Channel, station_index: u6) !void {
    const index = try getChannelIndex(channel);
    const path: i32 = try getPath(channel);
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
            return error.UnexpectedWwSendSize;
        }
    } else {
        return error.ChannelStationsUninitialized;
    }
}

pub fn sendChannelY(
    channel: Channel,
    start_station_index: u6,
    end_station_index: u6,
) !void {
    const end_station_exclusive: u7 = @as(u7, end_station_index) + 1;
    const num_stations: usize = end_station_exclusive - start_station_index;
    const index = try getChannelIndex(channel);
    const path: i32 = try getPath(channel);
    if (stations[index]) |*stations_list| {
        const bytes_sent: i32 = try mdfunc.sendEx(
            path,
            0,
            0xFF,
            .DevY,
            0,
            std.mem.sliceAsBytes(
                stations_list.y[start_station_index..end_station_exclusive],
            ),
        );
        if (bytes_sent != @sizeOf(Station.Y) * num_stations) {
            return error.UnexpectedYSendSize;
        }
    } else {
        return error.ChannelStationsUninitialized;
    }
}

pub fn sendChannelWw(
    channel: Channel,
    start_station_index: u6,
    end_station_index: u6,
) !void {
    const end_station_exclusive: u7 = @as(u7, end_station_index) + 1;
    const num_stations: usize = end_station_exclusive - start_station_index;
    const index = try getChannelIndex(channel);
    const path: i32 = try getPath(channel);
    if (stations[index]) |*stations_list| {
        const bytes_sent: i32 = try mdfunc.sendEx(
            path,
            0,
            0xFF,
            .DevWw,
            0,
            std.mem.sliceAsBytes(
                stations_list.ww[start_station_index..end_station_exclusive],
            ),
        );
        if (bytes_sent != @sizeOf(Station.Ww) * num_stations) {
            return error.UnexpectedWwSendSize;
        }
    } else {
        return error.ChannelStationsUninitialized;
    }
}

fn getChannelIndex(channel: Channel) !u2 {
    return switch (channel) {
        .cc_link_1slot => 0,
        .cc_link_2slot => 1,
        .cc_link_3slot => 2,
        .cc_link_4slot => 3,
        else => return error.UnsupportedChannel,
    };
}

fn getPath(channel: Channel) !i32 {
    if (paths[try getChannelIndex(channel)]) |p| {
        return p;
    } else {
        return error.ChannelUnopened;
    }
}
