const std = @import("std");
const mcl = @import("mcl");

const MclConnectionKind = enum(c_ushort) {
    CcLinkVer2 = 0,
};
const MclDriverConfig = extern struct {
    using_axis1: c_int = 1,
    axis1_position: MclDistance = .{ .mm = 0, .um = 0 },
    using_axis2: c_int = 1,
    axis2_position: MclDistance = .{ .mm = 0, .um = 0 },
    using_axis3: c_int = 1,
    axis3_position: MclDistance = .{ .mm = 0, .um = 0 },
};
const MclConfig = extern struct {
    connection_kind: MclConnectionKind = .CcLinkVer2,
    connection_min_polling_interval: c_ulong = 100_000,
    num_drivers: c_ulong,
    drivers: [*]const MclDriverConfig,
};
const MclDistance = extern struct {
    mm: c_short,
    um: c_short,
};
const MclSliderId = c_short;
const MclAxisId = c_short;
const MclDriverId = c_short;

export fn mclInit(config: *const MclConfig) callconv(.C) c_int {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator: std.mem.Allocator = arena.allocator();

    var mcl_drivers: []mcl.DriverConfig = allocator.alloc(
        mcl.DriverConfig,
        config.num_drivers,
    ) catch |e| {
        return @intFromError(e);
    };

    for (0..config.num_drivers) |i| {
        mcl_drivers[i] = .{ .axis1 = null, .axis2 = null, .axis3 = null };
        if (config.drivers[i].using_axis1 == 1) {
            mcl_drivers[i].axis1 = .{
                .position = mcl.Distance.Zero,
            };
            mcl_drivers[i].axis1.?.position.mm =
                config.drivers[i].axis1_position.mm;
            mcl_drivers[i].axis1.?.position.um =
                config.drivers[i].axis1_position.um;
        }
        if (config.drivers[i].using_axis2 == 1) {
            mcl_drivers[i].axis2 = .{
                .position = mcl.Distance.Zero,
            };
            mcl_drivers[i].axis2.?.position.mm =
                config.drivers[i].axis2_position.mm;
            mcl_drivers[i].axis2.?.position.um =
                config.drivers[i].axis2_position.um;
        }
        if (config.drivers[i].using_axis3 == 1) {
            mcl_drivers[i].axis3 = .{
                .position = mcl.Distance.Zero,
            };
            mcl_drivers[i].axis3.?.position.mm =
                config.drivers[i].axis3_position.mm;
            mcl_drivers[i].axis3.?.position.um =
                config.drivers[i].axis3_position.um;
        }
    }
    var mcl_config: mcl.Config = .{
        .drivers = mcl_drivers,
    };
    switch (config.connection_kind) {
        .CcLinkVer2 => mcl_config.connection_kind = .CcLinkVer2,
    }
    mcl_config.connection_min_polling_interval =
        config.connection_min_polling_interval;
    mcl.init(mcl_config) catch |e| {
        return @intFromError(e);
    };

    return 0;
}

export fn mclDeinit() callconv(.C) void {
    mcl.deinit();
}

export fn mclConnect() callconv(.C) c_int {
    mcl.connect() catch |e| {
        return @intFromError(e);
    };
    return 0;
}

export fn mclDisconnect() callconv(.C) c_int {
    mcl.disconnect() catch |e| {
        return @intFromError(e);
    };
    return 0;
}

export fn mclVersionMajor() callconv(.C) c_uint {
    return @intCast(mcl.version().major);
}

export fn mclVersionMinor() callconv(.C) c_uint {
    return @intCast(mcl.version().minor);
}

export fn mclVersionPatch() callconv(.C) c_uint {
    return @intCast(mcl.version().patch);
}

export fn mclPoll() callconv(.C) c_int {
    mcl.poll() catch |e| {
        return @intFromError(e);
    };
    return 0;
}

export fn mclAxisSlider(
    axis_id: MclAxisId,
    out_slider_id: *MclSliderId,
) callconv(.C) void {
    if (mcl.axisSlider(axis_id)) |slider_id| {
        out_slider_id.* = slider_id;
    } else {
        out_slider_id.* = 0;
    }
}

export fn mclAxisRecoverSlider(
    axis: MclAxisId,
    new_slider_id: MclSliderId,
) callconv(.C) c_int {
    mcl.axisRecoverSlider(axis, new_slider_id) catch |e| {
        return @intFromError(e);
    };
    return 0;
}

export fn mclAxisServoRelease(axis_id: MclAxisId) callconv(.C) c_int {
    mcl.axisServoRelease(axis_id) catch |e| {
        return @intFromError(e);
    };
    return 0;
}

export fn mclAxisServoReleased(
    axis_id: MclAxisId,
    out_released: *c_int,
) callconv(.C) void {
    if (mcl.axisServoReleased(axis_id)) {
        out_released.* = 1;
    } else {
        out_released.* = 0;
    }
}

export fn mclHome() callconv(.C) c_int {
    mcl.home() catch |e| {
        return @intFromError(e);
    };
    return 0;
}

export fn mclSliderPosMoveAxis(
    slider_id: MclSliderId,
    axis_id: MclAxisId,
    speed_percentage: c_short,
    acceleration_percentage: c_short,
) callconv(.C) c_int {
    mcl.sliderPosMoveAxis(
        slider_id,
        axis_id,
        speed_percentage,
        acceleration_percentage,
    ) catch |e| {
        return @intFromError(e);
    };
    return 0;
}

export fn mclSliderPosMoveLocation(
    slider_id: MclSliderId,
    location: MclDistance,
    speed_percentage: c_short,
    acceleration_percentage: c_short,
) callconv(.C) c_int {
    mcl.sliderPosMoveLocation(
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

export fn mclSliderPosMoveDistance(
    slider_id: MclSliderId,
    distance: MclDistance,
    speed_percentage: c_short,
    acceleration_percentage: c_short,
) callconv(.C) c_int {
    mcl.sliderPosMoveDistance(
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

export fn mclSliderPosMoveCompleted(
    slider_id: MclSliderId,
    out_completed: *c_int,
) callconv(.C) c_int {
    if (mcl.sliderPosMoveCompleted(slider_id) catch |e| {
        return @intFromError(e);
    }) {
        out_completed.* = 1;
    } else out_completed.* = 0;
    return 0;
}

export fn mclSliderLocation(
    slider_id: MclSliderId,
    out_location: *MclDistance,
) callconv(.C) c_int {
    const location = mcl.sliderLocation(slider_id) catch |e| {
        return @intFromError(e);
    };
    out_location.*.mm = location.mm;
    out_location.*.um = location.um;
    return 0;
}

export fn mclErrorString(code: c_int) callconv(.C) [*:0]const u8 {
    if (code == 0) return "";
    const code_cast: u16 = @intCast(code);
    return @errorName(@errorFromInt(code_cast));
}
