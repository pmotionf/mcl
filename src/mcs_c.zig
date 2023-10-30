const std = @import("std");
const mcs = @import("mcs");

const McsConnectionKind = enum(c_ushort) {
    CcLinkVer2 = 0,
};
const McsDriverConfig = extern struct {
    using_axis1: c_int = 1,
    axis1_position: McsDistance = .{ .mm = 0, .um = 0 },
    using_axis2: c_int = 1,
    axis2_position: McsDistance = .{ .mm = 0, .um = 0 },
    using_axis3: c_int = 1,
    axis3_position: McsDistance = .{ .mm = 0, .um = 0 },
};
const McsConfig = extern struct {
    connection_kind: McsConnectionKind = .CcLinkVer2,
    connection_min_polling_interval: c_ulong = 100_000,
    num_drivers: c_ulong,
    drivers: [*]const McsDriverConfig,
};
const McsDistance = extern struct {
    mm: c_short,
    um: c_short,
};
const McsSliderId = c_short;
const McsAxisId = c_short;
const McsDriverId = c_short;

export fn mcsInit(config: *const McsConfig) callconv(.C) c_int {
    var mcs_drivers: []mcs.DriverConfig = std.heap.c_allocator.alloc(
        mcs.DriverConfig,
        config.num_drivers,
    ) catch |e| {
        return @intFromError(e);
    };
    defer std.heap.c_allocator.free(mcs_drivers);

    for (0..config.num_drivers) |i| {
        mcs_drivers[i] = .{ .axis1 = null, .axis2 = null, .axis3 = null };
        if (config.drivers[i].using_axis1 == 1) {
            mcs_drivers[i].axis1 = .{
                .position = mcs.Distance.Zero,
            };
            mcs_drivers[i].axis1.?.position.mm =
                config.drivers[i].axis1_position.mm;
            mcs_drivers[i].axis1.?.position.um =
                config.drivers[i].axis1_position.um;
        }
        if (config.drivers[i].using_axis2 == 1) {
            mcs_drivers[i].axis2 = .{
                .position = mcs.Distance.Zero,
            };
            mcs_drivers[i].axis2.?.position.mm =
                config.drivers[i].axis2_position.mm;
            mcs_drivers[i].axis2.?.position.um =
                config.drivers[i].axis2_position.um;
        }
        if (config.drivers[i].using_axis3 == 1) {
            mcs_drivers[i].axis3 = .{
                .position = mcs.Distance.Zero,
            };
            mcs_drivers[i].axis3.?.position.mm =
                config.drivers[i].axis3_position.mm;
            mcs_drivers[i].axis3.?.position.um =
                config.drivers[i].axis3_position.um;
        }
    }
    var mcs_config: mcs.Config = .{
        .drivers = mcs_drivers,
    };
    switch (config.connection_kind) {
        .CcLinkVer2 => mcs_config.connection_kind = .CcLinkVer2,
    }
    mcs_config.connection_min_polling_interval =
        config.connection_min_polling_interval;
    mcs.init(mcs_config) catch |e| {
        return @intFromError(e);
    };

    return 0;
}

export fn mcsDeinit() callconv(.C) void {
    mcs.deinit();
}

export fn mcsConnect() callconv(.C) c_int {
    mcs.connect() catch |e| {
        return @intFromError(e);
    };
    return 0;
}

export fn mcsDisconnect() callconv(.C) c_int {
    mcs.disconnect() catch |e| {
        return @intFromError(e);
    };
    return 0;
}

export fn mcsVersionMajor() callconv(.C) c_uint {
    return @intCast(mcs.version().major);
}

export fn mcsVersionMinor() callconv(.C) c_uint {
    return @intCast(mcs.version().minor);
}

export fn mcsVersionPatch() callconv(.C) c_uint {
    return @intCast(mcs.version().patch);
}

export fn mcsPoll() callconv(.C) c_int {
    mcs.poll() catch |e| {
        return @intFromError(e);
    };
    return 0;
}

export fn mcsAxisSlider(
    axis_id: McsAxisId,
    out_slider_id: *McsSliderId,
) callconv(.C) void {
    if (mcs.axisSlider(axis_id)) |slider_id| {
        out_slider_id.* = slider_id;
    } else {
        out_slider_id.* = 0;
    }
}

export fn mcsAxisRecoverSlider(
    axis: McsAxisId,
    new_slider_id: McsSliderId,
) callconv(.C) c_int {
    mcs.axisRecoverSlider(axis, new_slider_id) catch |e| {
        return @intFromError(e);
    };
    return 0;
}

export fn mcsAxisServoRelease(axis_id: McsAxisId) callconv(.C) c_int {
    mcs.axisServoRelease(axis_id) catch |e| {
        return @intFromError(e);
    };
    return 0;
}

export fn mcsAxisServoReleased(
    axis_id: McsAxisId,
    out_released: *c_int,
) callconv(.C) void {
    if (mcs.axisServoReleased(axis_id)) {
        out_released.* = 1;
    } else {
        out_released.* = 0;
    }
}

export fn mcsHome() callconv(.C) c_int {
    mcs.home() catch |e| {
        return @intFromError(e);
    };
    return 0;
}

export fn mcsSliderPosMoveAxis(
    slider_id: McsSliderId,
    axis_id: McsAxisId,
    speed_percentage: c_short,
    acceleration_percentage: c_short,
) callconv(.C) c_int {
    mcs.sliderPosMoveAxis(
        slider_id,
        axis_id,
        speed_percentage,
        acceleration_percentage,
    ) catch |e| {
        return @intFromError(e);
    };
    return 0;
}

export fn mcsSliderPosMoveLocation(
    slider_id: McsSliderId,
    location: McsDistance,
    speed_percentage: c_short,
    acceleration_percentage: c_short,
) callconv(.C) c_int {
    mcs.sliderPosMoveLocation(
        slider_id,
        .{
            .mm = location.mm,
            .um = location.um,
        },
        speed_percentage,
        acceleration_percentage,
    ) catch |e| {
        return @intFromError(e);
    };
    return 0;
}

export fn mcsSliderPosMoveDistance(
    slider_id: McsSliderId,
    distance: McsDistance,
    speed_percentage: c_short,
    acceleration_percentage: c_short,
) callconv(.C) c_int {
    mcs.sliderPosMoveDistance(
        slider_id,
        .{
            .mm = distance.mm,
            .um = distance.um,
        },
        speed_percentage,
        acceleration_percentage,
    ) catch |e| {
        return @intFromError(e);
    };
    return 0;
}

export fn mcsSliderPosMoveCompleted(
    slider_id: McsSliderId,
    out_completed: *c_int,
) callconv(.C) c_int {
    if (mcs.sliderPosMoveCompleted(slider_id) catch |e| {
        return @intFromError(e);
    }) {
        out_completed.* = 1;
    } else out_completed.* = 0;
    return 0;
}

export fn mcsSliderLocation(
    slider_id: McsSliderId,
    out_location: *McsDistance,
) callconv(.C) c_int {
    const location = mcs.sliderLocation(slider_id) catch |e| {
        return @intFromError(e);
    };
    out_location.*.mm = location.mm;
    out_location.*.um = location.um;
    return 0;
}

export fn mcsErrorString(code: c_int) callconv(.C) [*:0]const u8 {
    if (code == 0) return "";
    const code_cast: u16 = @intCast(code);
    return @errorName(@errorFromInt(code_cast));
}
