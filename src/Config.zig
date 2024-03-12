const std = @import("std");
const connection = @import("connection.zig");

pub const Station = struct {
    index: Index,
    axes: Axes = .{ false, false, false },

    pub const Index = packed struct(u8) {
        index: connection.Station.Index,
        channel: connection.Channel,

        pub const Range = struct {
            range: connection.Station.IndexRange,
            channel: connection.Channel,
        };
    };

    pub const Axes = [3]bool;
};
