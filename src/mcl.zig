const std = @import("std");
const common = @import("common.zig");
const _version = @import("version");
const Connection = @import("Connection.zig");

pub const ConnectionKind = Connection.ConnectionKind;
pub const Distance = common.Distance;
pub const SliderId = Connection.SliderId;
pub const AxisId = Connection.Axis.IdSystem;
pub const DriverId = Connection.Driver.Id;

pub const AxisConfig = struct {
    position: Distance,
};

pub const DriverConfig = struct {
    axis1: ?AxisConfig,
    axis2: ?AxisConfig,
    axis3: ?AxisConfig,
};

pub const Config = struct {
    connection_kind: ConnectionKind = .CcLinkVer2,
    /// Minimum polling interval in microseconds.
    connection_min_polling_interval: usize = 100_000,
    drivers: []const DriverConfig,
};

var arena: std.heap.ArenaAllocator = undefined;
var allocator: std.mem.Allocator = undefined;
var connection: Connection = .{};
var system_config: Config = .{
    .connection_kind = undefined,
    .connection_min_polling_interval = undefined,
    .drivers = undefined,
};

pub fn version() std.SemanticVersion {
    // TODO: Integrate with `build.zig.zon` version.
    return std.SemanticVersion.parse(_version.mcl_version) catch {
        unreachable;
    };
}

pub fn init(config: Config) !void {
    // Create temporary connection configuration drivers.
    arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    errdefer arena.deinit();
    allocator = arena.allocator();
    var connection_config_drivers: []Connection.Driver = try allocator.alloc(
        Connection.Driver,
        config.drivers.len,
    );
    errdefer allocator.free(connection_config_drivers);
    var axis_id_system: Connection.Axis.IdSystem = 1;
    for (config.drivers, 0..) |driver, i| {
        if (driver.axis1) |a| {
            _ = a;
            connection_config_drivers[i].axis1 = .{
                .id_driver = .first,
                .id_system = axis_id_system,
            };
            axis_id_system += 1;
        }
        if (driver.axis2) |a| {
            _ = a;
            connection_config_drivers[i].axis2 = .{
                .id_driver = .second,
                .id_system = axis_id_system,
            };
            axis_id_system += 1;
        }
        if (driver.axis3) |a| {
            _ = a;
            connection_config_drivers[i].axis3 = .{
                .id_driver = .third,
                .id_system = axis_id_system,
            };
            axis_id_system += 1;
        }
    }
    try connection.init(.{
        .kind = config.connection_kind,
        .min_poll_interval = config.connection_min_polling_interval,
        .drivers = connection_config_drivers,
    });
    errdefer connection.deinit();
    allocator.free(connection_config_drivers);
    arena.deinit();

    // Initialization of MCL.
    arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    errdefer arena.deinit();
    allocator = arena.allocator();

    system_config.connection_kind = config.connection_kind;
    system_config.connection_min_polling_interval =
        config.connection_min_polling_interval;
    system_config.drivers = try allocator.dupe(DriverConfig, config.drivers);
}

pub fn deinit() void {
    disconnect() catch {};
    connection.deinit();
    allocator.free(system_config.drivers);
    allocator = undefined;
    arena.deinit();
    arena = undefined;
}

pub fn connect() !void {
    try connection.open();
    errdefer connection.close() catch {};
    try connection.link(true);
    _ = try connection.poll();
}

pub fn disconnect() !void {
    try connection.link(false);
    try connection.close();
}

pub fn poll() !void {
    while (!(try connection.poll())) {}
}

pub fn axisSlider(axis: AxisId) ?SliderId {
    return connection.axis(axis).slider();
}

pub fn axisRecoverSlider(axis: AxisId, new_slider_id: SliderId) !void {
    if (connection.axis(axis).detectedBackHallSensor() or
        connection.axis(axis).detectedFrontHallSensor())
    {
        try waitCommandReady(connection.axis(axis).driver);
        try connection.axis(axis).command.recoverSlider(new_slider_id);
        try doCommand(connection.axis(axis).driver);
    } else return error.NotReadyToRecover;
}

pub fn axisServoRelease(axis: AxisId) !void {
    try connection.axis(axis).releaseServo(true);
    // TODO: Replace with handshake
    std.log.debug("Waiting for servo release...", .{});
    while (!axisServoReleased(axis)) {
        try poll();
    }
    try connection.axis(axis).releaseServo(false);
}

pub fn axisServoReleased(axis: AxisId) bool {
    return !connection.axis(axis).isServoActive();
}

fn waitCommandReady(driver: *Connection.Driver) !void {
    std.log.debug("Waiting for driver to be ready...", .{});
    while (!driver.command.ready() or driver.command.received()) {
        try poll();
    }
}

fn doCommand(driver: *Connection.Driver) !void {
    try driver.command.start(true);
    std.log.debug("Waiting for driver to receive command...", .{});
    while (!driver.command.received()) {
        try poll();
    }
    try driver.command.start(false);
    try driver.command.clearReceived(true);
    std.log.debug("Waiting for command received to be cleared...", .{});
    while (driver.command.received()) {
        try poll();
    }
    try driver.command.clearReceived(false);
    std.log.debug("Waiting to reset clear command received...", .{});
    const y_reg = &driver.self._registers.y[driver.index];
    while (y_reg.reset_command_received) {
        try poll();
    }
    // Resetting driver transmission stop bit should be done as soon as the
    // prev/next driver bit indicates that traffic transmission is paused.
    const x_reg = &driver.self._registers.x[driver.index];
    if (y_reg.stop_driver_transmission.from_prev) {
        std.log.debug(
            "Waiting for previous driver transmission to be stopped...",
            .{},
        );
        while (!x_reg.transmission_stopped.from_prev) {
            try poll();
        }
        try driver.stopAuxiliaryTrafficFromPrev(false);
        std.log.debug(
            "Waiting for previous driver transmission stop to be cleared...",
            .{},
        );
        while (y_reg.stop_driver_transmission.from_prev) {
            try poll();
        }
    }
    if (y_reg.stop_driver_transmission.from_next) {
        std.log.debug(
            "Waiting for next driver transmission to be stopped...",
            .{},
        );
        while (!x_reg.transmission_stopped.from_next) {
            try poll();
        }
        try driver.stopAuxiliaryTrafficFromNext(false);
        std.log.debug(
            "Waiting for next driver transmission stop to be cleared...",
            .{},
        );
        while (y_reg.stop_driver_transmission.from_next) {
            try poll();
        }
    }
}

pub fn home() !void {
    if (connection.axis(1).detectedBackHallSensor() and
        connection.axis(1).detectedFrontHallSensor() and
        connection.axis(1).slider() == null)
    {
        var driver: *Connection.Driver = connection.axis(1).driver;
        try waitCommandReady(driver);
        try driver.command.home();
        try doCommand(driver);
    } else return error.NotReadyToHome;
}

pub fn sliderPosMoveAxis(
    slider_id: SliderId,
    axis_id: AxisId,
    speed_percentage: i16,
    acceleration_percentage: i16,
) !void {
    std.debug.assert(speed_percentage <= 100 and speed_percentage > 0);
    std.debug.assert(acceleration_percentage <= 100 and
        acceleration_percentage > 0);
    std.debug.assert(slider_id > 0);
    std.debug.assert(axis_id > 0 and axis_id <= connection.axes.len);

    var driver: *Connection.Driver = undefined;
    for (connection.axes, 1..) |axis, next_axis_ind| {
        if (axis.slider()) |sid| {
            if (sid == slider_id) {
                // Resolve which driver to use if slider is between two
                // different drivers.
                if (next_axis_ind < connection.axes.len and
                    connection.axes[next_axis_ind].driver != axis.driver and
                    connection.axes[next_axis_ind].slider() == sid)
                {
                    var next_axis: *Connection.Axis =
                        connection.axes[next_axis_ind];
                    // Destination axis is at or beyond next driver, thus
                    // movement direction is forward.
                    if (axis_id > next_axis_ind) {
                        driver = next_axis.driver;

                        if (axis.isAuxiliaryToNext()) {
                            try driver.stopAuxiliaryTrafficFromPrev(true);
                        } else if (next_axis.isAuxiliaryToPrev()) {
                            try axis.driver.stopAuxiliaryTrafficFromNext(true);
                        }

                        break;
                    }
                    // Destination axis is at or before current driver, thus
                    // movement direction is backward.
                    else {
                        driver = axis.driver;

                        if (axis.isAuxiliaryToNext() or
                            axis.sliderStatus() == null)
                        {
                            try next_axis.driver.stopAuxiliaryTrafficFromPrev(
                                true,
                            );
                        } else if (next_axis.isAuxiliaryToPrev() or
                            next_axis.sliderStatus() == null)
                        {
                            try driver.stopAuxiliaryTrafficFromNext(true);
                        }

                        break;
                    }
                } else {
                    driver = axis.driver;
                    break;
                }
            }
        }
    } else return error.SliderNotFound;
    try poll();
    try waitCommandReady(driver);
    try driver.command.posMoveAxis(
        slider_id,
        axis_id,
        speed_percentage,
        acceleration_percentage,
    );
    try doCommand(driver);
}

pub fn sliderPosMoveLocation(
    slider_id: SliderId,
    location: Distance,
    speed_percentage: i16,
    acceleration_percentage: i16,
) !void {
    std.debug.assert(speed_percentage <= 100 and speed_percentage > 0);
    std.debug.assert(acceleration_percentage <= 100 and
        acceleration_percentage > 0);
    std.debug.assert(slider_id > 0);
    std.debug.assert(location.mm >= 0 and location.um >= 0 and
        location.um < 1000);

    var driver: *Connection.Driver = undefined;
    for (connection.axes, 1..) |axis, next_axis_ind| {
        if (axis.slider()) |sid| {
            if (sid == slider_id) {
                // Resolve which driver to use if slider is between two
                // different drivers.
                if (next_axis_ind < connection.axes.len and
                    connection.axes[next_axis_ind].driver != axis.driver and
                    connection.axes[next_axis_ind].slider() == sid)
                {
                    var next_axis: *Connection.Axis =
                        connection.axes[next_axis_ind];
                    // Target location is greater than current location, thus
                    // movement direction is forward.
                    if ((next_axis.sliderLocation() != null and
                        next_axis.sliderLocation().?.less(location)) or
                        (axis.sliderLocation() != null and
                        axis.sliderLocation().?.less(location)))
                    {
                        driver = next_axis.driver;

                        // TODO: Figure out if the reason for this is to ensure
                        // that the upcoming movement command isn't interrupted
                        // by traffic from auxiliary controller.
                        if (axis.isAuxiliaryToNext()) {
                            try driver.stopAuxiliaryTrafficFromPrev(true);
                        } else if (next_axis.isAuxiliaryToPrev()) {
                            try axis.driver.stopAuxiliaryTrafficFromNext(true);
                        }

                        break;
                    }
                    // Target location is less than current location, thus
                    // movement direction is backward.
                    else {
                        driver = axis.driver;

                        if (axis.isAuxiliaryToNext() or
                            axis.sliderStatus() == null)
                        {
                            try next_axis.driver.stopAuxiliaryTrafficFromPrev(
                                true,
                            );
                        } else if (next_axis.isAuxiliaryToPrev() or
                            next_axis.sliderStatus() == null)
                        {
                            try driver.stopAuxiliaryTrafficFromNext(true);
                        }

                        break;
                    }
                } else {
                    driver = axis.driver;
                    break;
                }
            }
        }
    } else return error.SliderNotFound;
    try poll();
    try waitCommandReady(driver);
    try driver.command.posMoveLocation(
        slider_id,
        location,
        speed_percentage,
        acceleration_percentage,
    );
    try doCommand(driver);
}

pub fn sliderPosMoveDistance(
    slider_id: SliderId,
    distance: Distance,
    speed_percentage: i16,
    acceleration_percentage: i16,
) !void {
    std.debug.assert(speed_percentage <= 100 and speed_percentage > 0);
    std.debug.assert(acceleration_percentage <= 100 and
        acceleration_percentage > 0);
    std.debug.assert(slider_id > 0);
    std.debug.assert(distance.um < 1000 and distance.um > -1000);

    if (distance.isZero()) return error.InvalidSliderMove;

    var driver: *Connection.Driver = undefined;
    for (connection.axes, 1..) |axis, next_axis_ind| {
        if (axis.slider()) |sid| {
            if (sid == slider_id) {
                // Resolve which driver to use if slider is between two
                // different drivers.
                if (next_axis_ind < connection.axes.len and
                    connection.axes[next_axis_ind].driver != axis.driver and
                    connection.axes[next_axis_ind].slider() == sid)
                {
                    var next_axis: *Connection.Axis =
                        connection.axes[next_axis_ind];
                    // Distance is positive, thus movement direction is
                    // forward.
                    if (distance.greater(Distance.Zero)) {
                        driver = next_axis.driver;

                        // TODO: Figure out if the reason for this is to ensure
                        // that the upcoming movement command isn't interrupted
                        // by traffic from auxiliary controller.
                        if (axis.isAuxiliaryToNext()) {
                            try driver.stopAuxiliaryTrafficFromPrev(true);
                        } else if (next_axis.isAuxiliaryToPrev()) {
                            try axis.driver.stopAuxiliaryTrafficFromNext(true);
                        }

                        break;
                    }
                    // Distance is negative, thus movement direction is
                    // backward.
                    else {
                        driver = axis.driver;

                        if (axis.isAuxiliaryToNext() or
                            axis.sliderStatus() == null)
                        {
                            try next_axis.driver.stopAuxiliaryTrafficFromPrev(
                                true,
                            );
                        } else if (next_axis.isAuxiliaryToPrev() or
                            next_axis.sliderStatus() == null)
                        {
                            try driver.stopAuxiliaryTrafficFromNext(true);
                        }

                        break;
                    }
                } else {
                    driver = axis.driver;
                    break;
                }
            }
        }
    } else return error.SliderNotFound;
    try poll();
    try waitCommandReady(driver);
    try driver.command.posMoveDistance(
        slider_id,
        distance,
        speed_percentage,
        acceleration_percentage,
    );
    try doCommand(driver);
}

pub fn sliderPosMoveCompleted(slider_id: SliderId) !bool {
    var slider_found: bool = false;
    for (connection.axes) |axis| {
        if (axis.slider()) |sid| {
            if (sid == slider_id) {
                slider_found = true;
                if (axis.sliderStatus()) |status| {
                    if (status == .PosMoveCompleted) {
                        return true;
                    }
                }
            }
        }
    }
    if (!slider_found) return error.SliderNotFound;
    return false;
}

pub fn sliderLocation(slider_id: SliderId) !Distance {
    for (connection.axes) |axis| {
        if (axis.slider()) |sid| {
            if (sid == slider_id) {
                return axis.sliderLocation().?;
            }
        }
    } else return error.SliderNotFound;
}
