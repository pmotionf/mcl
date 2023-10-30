//! Interface that represents the hardware motion system connection. The
//! implementation for this connection can be chosen at initialization.
const Connection = @This();
const std = @import("std");

const common = @import("common.zig");
const Distance = common.Distance;

const Registers = @import("Connection/Registers.zig");

pub const ConnectionKind = enum {
    CcLinkVer2,
};

pub const Config = struct {
    kind: ConnectionKind,
    min_poll_interval: usize = 100_000,
    drivers: []const Driver,
};

pub const SliderId = i16;

/// Array of drivers. Driver related functions are namespaced here, and axes
/// can be accessed through individual drivers as well.
drivers: []Driver = undefined,

/// Array of axes. Ordered sequentially from first to last axis in forward
/// direction, such that axis operations can be conveniently run with only the
/// absolute axis position in the motion system rather than having to know the
/// specific driver configuration.
axes: []*Axis = undefined,

_arena_allocator: std.heap.ArenaAllocator = undefined,
_allocator: std.mem.Allocator = undefined,

_impl: Impl = undefined,

_registers: struct {
    x: []Registers.X = undefined,
    y: []Registers.Y = undefined,
    wr: []Registers.Wr = undefined,
    ww: []Registers.Ww = undefined,
} = undefined,

_min_poll_interval: usize = 10_000, // 10,000 microseconds = 10 milliseconds
_last_poll_time: i64 = 0,

pub fn init(self: *Connection, config: Config) !void {
    self._arena_allocator = std.heap.ArenaAllocator.init(
        std.heap.page_allocator,
    );
    errdefer {
        self._arena_allocator.deinit();
        self._arena_allocator = undefined;
    }
    self._allocator = self._arena_allocator.allocator();
    self._min_poll_interval = config.min_poll_interval;
    self.drivers = try self._allocator.alloc(Driver, config.drivers.len);
    errdefer self._allocator.free(self.drivers);
    var axis_id: Axis.IdSystem = 0;

    // Allocate registers.
    self._registers = .{};
    self._registers.x = try self._allocator.alloc(
        Registers.X,
        config.drivers.len,
    );
    errdefer self._allocator.free(self._registers.x);
    self._registers.y = try self._allocator.alloc(
        Registers.Y,
        config.drivers.len,
    );
    errdefer self._allocator.free(self._registers.y);
    self._registers.wr = try self._allocator.alloc(
        Registers.Wr,
        config.drivers.len,
    );
    errdefer self._allocator.free(self._registers.wr);
    self._registers.ww = try self._allocator.alloc(
        Registers.Ww,
        config.drivers.len,
    );
    errdefer self._allocator.free(self._registers.ww);

    // Initialize drivers array.
    for (config.drivers, 0..) |d, ind| {
        std.debug.assert(d.axis1 != null or
            d.axis2 != null or
            d.axis3 != null);

        self.drivers[ind] = .{
            .self = self,
            .index = ind,
            .id = @intCast(ind + 1),
            .axis1 = null,
            .axis2 = null,
            .axis3 = null,
        };
        if (d.axis1) |_| {
            axis_id += 1;
            self.drivers[ind].axis1 = Axis{
                .driver = &(self.drivers[ind]),
                .id_driver = .first,
                .id_system = axis_id,
            };
        }
        if (d.axis2) |_| {
            axis_id += 1;
            self.drivers[ind].axis2 = Axis{
                .driver = &(self.drivers[ind]),
                .id_driver = .second,
                .id_system = axis_id,
            };
        }
        if (d.axis3) |_| {
            axis_id += 1;
            self.drivers[ind].axis3 = Axis{
                .driver = &(self.drivers[ind]),
                .id_driver = .third,
                .id_system = axis_id,
            };
        }
    }

    // Initialize axes array and point each axis pointer into drivers array.
    self.axes = try self._allocator.alloc(*Axis, @intCast(axis_id));
    errdefer self._allocator.free(self.axes);
    var axis_index: usize = 0;
    for (self.drivers) |*d| {
        if (d.axis1) |_| {
            self.axes[axis_index] = &(d.axis1.?);
            axis_index += 1;
        }
        if (d.axis2) |_| {
            self.axes[axis_index] = &(d.axis2.?);
            axis_index += 1;
        }
        if (d.axis3) |_| {
            self.axes[axis_index] = &(d.axis3.?);
            axis_index += 1;
        }
    }

    switch (config.kind) {
        .CcLinkVer2 => {
            self._impl = .{ .CcLinkVer2 = try CcLinkVer2.init(self) };
        },
    }
}

pub fn deinit(self: *Connection) void {
    self._impl.deinit();
    self._allocator.free(self.axes);
    self._allocator.free(self.drivers);
    self._arena_allocator.deinit();
    self._arena_allocator = undefined;
}

pub fn open(self: *Connection) !void {
    try self._impl.open();
}

pub fn close(self: *Connection) !void {
    try self._impl.close();
}

pub fn link(self: *Connection, comptime set: bool) !void {
    for (self.drivers) |*d| {
        try d.link(set);
    }
}

pub fn driver(self: *Connection, driver_id: Driver.Id) *Driver {
    std.debug.assert(driver_id > 0 and driver_id <= self.drivers.len);
    return self.drivers[@intCast(driver_id - 1)];
}

pub fn axis(self: *Connection, axis_id: Axis.IdSystem) *Axis {
    std.debug.assert(axis_id > 0 and axis_id <= self.axes.len);
    return self.axes[@intCast(axis_id - 1)];
}

pub fn poll(self: *Connection) !bool {
    const now = std.time.microTimestamp();
    if (now - self._last_poll_time < self._min_poll_interval) {
        return false;
    }
    defer self._last_poll_time = std.time.microTimestamp();

    try self._impl.poll();
    return true;
}

pub const Axis = struct {
    pub const IdDriver = enum(u2) {
        first = 1,
        second = 2,
        third = 3,
    };
    pub const IdSystem = i16;

    pub const Status = Registers.Wr.FsmCode;

    pub const Command = struct {
        pub fn recoverSlider(c: *Command, new_slider_id: SliderId) !void {
            const a: *Axis = @fieldParentPtr(Axis, "command", c);
            try a.driver.self._impl.axisRecoverSlider(
                a.driver.id,
                a.id_driver,
                new_slider_id,
            );
        }
    };

    driver: *Driver = undefined,

    /// Index from 1...3 inclusive, representing axis ID within the driver.
    id_driver: IdDriver = undefined,

    /// ID in total system. Must be greater than 0. Counts up linearly from 1
    /// in forward direction.
    id_system: IdSystem = undefined,

    command: Command = .{},

    pub fn detectedBackHallSensor(a: *const Axis) bool {
        switch (a.id_driver) {
            .first => {
                return a.driver.self._registers.x[a.driver.index]
                    .axis1_backward_hall_sensor_detected;
            },
            .second => {
                return a.driver.self._registers.x[a.driver.index]
                    .axis2_backward_hall_sensor_detected;
            },
            .third => {
                return a.driver.self._registers.x[a.driver.index]
                    .axis3_backward_hall_sensor_detected;
            },
        }
    }

    pub fn detectedFrontHallSensor(a: *const Axis) bool {
        switch (a.id_driver) {
            .first => {
                return a.driver.self._registers.x[a.driver.index]
                    .axis1_forward_hall_sensor_detected;
            },
            .second => {
                return a.driver.self._registers.x[a.driver.index]
                    .axis2_forward_hall_sensor_detected;
            },
            .third => {
                return a.driver.self._registers.x[a.driver.index]
                    .axis3_forward_hall_sensor_detected;
            },
        }
    }

    pub fn sliderStatus(a: *const Axis) ?Status {
        const wr_register = a.driver.self._registers.wr[a.driver.index];
        var fsm_value: i16 = 0;
        switch (a.id_driver) {
            .first => fsm_value = wr_register.axis1_slider_FSM,
            .second => fsm_value = wr_register.axis2_slider_FSM,
            .third => fsm_value = wr_register.axis3_slider_FSM,
        }

        switch (fsm_value) {
            // Slider position-based movement is currently in-progress.
            29 => return .PosMoveProgressing,
            // Slider position-based movement is completed.
            30 => return .PosMoveCompleted,
            31 => return .PosMoveFault,
            32 => return .CalibrationProgressing,
            33 => return .CalibrationCompleted,
            // Slider speed-based movement is currently in-progress.
            40 => return .SpdMoveProgressing,
            // Slider speed-based movement is completed.
            41 => return .SpdMoveCompleted,
            42 => return .SpdMoveFault,
            // This axis is auxiliary to the next axis.
            43 => return .NextAxisAuxiliary,
            // The next axis has completed slider movement.
            44 => return .NextAxisCompleted,
            // This axis is auxiliary to the previous axis.
            45 => return .PrevAxisAuxiliary,
            // The previous axis has completed slider movement.
            46 => return .PrevAxisCompleted,
            // Overcurrent was detected in this axis.
            50 => return .Overcurrent,
            51 => return .CommunicationError,
            else => return null,
        }
    }

    pub fn isAuxiliaryToNext(a: *const Axis) bool {
        if (a.sliderStatus()) |status| {
            if (status == .NextAxisAuxiliary or status == .NextAxisCompleted)
                return true;
        }
        return false;
    }

    pub fn isAuxiliaryToPrev(a: *const Axis) bool {
        if (a.sliderStatus()) |status| {
            if (status == .PrevAxisAuxiliary or status == .PrevAxisCompleted)
                return true;
        }
        return false;
    }

    pub fn slider(a: *const Axis) ?SliderId {
        switch (a.id_driver) {
            .first => {
                const slider_num =
                    a.driver.self._registers.wr[a.driver.index]
                    .axis1_slider_number;
                if (slider_num != 0) return slider_num;
                return null;
            },
            .second => {
                const slider_num =
                    a.driver.self._registers.wr[a.driver.index]
                    .axis2_slider_number;
                if (slider_num != 0) return slider_num;
                return null;
            },
            .third => {
                const slider_num =
                    a.driver.self._registers.wr[a.driver.index]
                    .axis3_slider_number;
                if (slider_num != 0) return slider_num;
                return null;
            },
        }
    }

    pub fn sliderLocation(a: *const Axis) ?Distance {
        const wr_register = a.driver.self._registers.wr[a.driver.index];
        if (a.slider() == null) return null;
        switch (a.id_driver) {
            .first => return .{
                .mm = wr_register.axis1_slider_location_mm,
                .um = wr_register.axis1_slider_location_um,
            },
            .second => return .{
                .mm = wr_register.axis2_slider_location_mm,
                .um = wr_register.axis2_slider_location_um,
            },
            .third => return .{
                .mm = wr_register.axis3_slider_location_mm,
                .um = wr_register.axis3_slider_location_um,
            },
        }
    }

    pub fn isServoActive(a: *const Axis) bool {
        const x_register = a.driver.self._registers.x[a.driver.index];
        switch (a.id_driver) {
            .first => return x_register.axis1_servo_active,
            .second => return x_register.axis2_servo_active,
            .third => return x_register.axis3_servo_active,
        }
    }

    pub fn releaseServo(a: *Axis, comptime set: bool) !void {
        try a.driver.self._impl.axisReleaseServo(
            set,
            a.driver.id,
            a.id_driver,
        );
    }
};

pub const Driver = struct {
    pub const Id = i16;

    /// Empty struct purely for namespacing command related functions.
    pub const Command = struct {
        pub fn ready(c: *const Command) bool {
            const d: *const Driver = @fieldParentPtr(Driver, "command", c);
            return d.self._registers.x[d.index].ready_for_command;
        }

        pub fn start(c: *Command, comptime set: bool) !void {
            const d: *Driver = @fieldParentPtr(Driver, "command", c);
            try d.self._impl.commandStart(set, d.id);
        }

        pub fn received(c: *const Command) bool {
            const d: *const Driver = @fieldParentPtr(Driver, "command", c);
            return d.self._registers.x[d.index].command_received;
        }

        pub fn clearReceived(c: *Command, comptime set: bool) !void {
            const d: *Driver = @fieldParentPtr(Driver, "command", c);
            try d.self._impl.commandClearReceived(set, d.id);
        }

        pub fn home(c: *Command) !void {
            const d: *Driver = @fieldParentPtr(Driver, "command", c);
            // TODO: Make this check for axis "Slider ID Sensor" configuration.
            // Also test and make sure this works on a per-driver basis.
            try d.self._impl.commandHome(d.id);
        }

        pub fn posMoveAxis(
            c: *Command,
            slider_id: SliderId,
            axis_id: Axis.IdSystem,
            speed_percentage: i16,
            acceleration_percentage: i16,
        ) !void {
            const d: *Driver = @fieldParentPtr(Driver, "command", c);
            try d.self._impl.commandPosMoveAxis(
                d.id,
                slider_id,
                axis_id,
                speed_percentage,
                acceleration_percentage,
            );
        }

        pub fn posMoveLocation(
            c: *Command,
            slider_id: SliderId,
            location: Distance,
            speed_percentage: i16,
            acceleration_percentage: i16,
        ) !void {
            const d: *Driver = @fieldParentPtr(Driver, "command", c);
            try d.self._impl.commandPosMoveLocation(
                d.id,
                slider_id,
                location,
                speed_percentage,
                acceleration_percentage,
            );
        }

        pub fn posMoveDistance(
            c: *Command,
            slider_id: SliderId,
            distance: Distance,
            speed_percentage: i16,
            acceleration_percentage: i16,
        ) !void {
            const d: *Driver = @fieldParentPtr(Driver, "command", c);
            try d.self._impl.commandPosMoveDistance(
                d.id,
                slider_id,
                distance,
                speed_percentage,
                acceleration_percentage,
            );
        }
    };

    self: *Connection = undefined,

    /// Index from 0, representing index in driver array.
    index: usize = undefined,

    /// ID in total system. Must be greater than 0. Counts up linearly from 1
    /// in forward direction.
    id: Id = undefined,

    axis1: ?Axis,
    axis2: ?Axis,
    axis3: ?Axis,

    /// Empty struct instance to access namespaced functions.
    command: Command = .{},

    pub fn axis(d: *Driver, id: Axis.IdDriver) ?*Axis {
        switch (id) {
            .first => if (d.axis1) |_| {
                return &(d.axis1.?);
            } else return null,
            .second => if (d.axis2) |_| {
                return &(d.axis2.?);
            } else return null,
            .third => if (d.axis3) |_| {
                return &(d.axis3.?);
            } else return null,
        }
    }

    pub fn isLinked(d: *const Driver) bool {
        return d.self._registers.x[d.index].cc_link_enabled;
    }

    pub fn link(d: *Driver, comptime set: bool) !void {
        try d.self._impl.driverLink(set, d.id);
    }

    pub fn stopAuxiliaryTrafficFromNext(d: *Driver, comptime set: bool) !void {
        try d.self._impl.driverStopAuxTrafficFromNext(set, d.id);
    }

    pub fn stopAuxiliaryTrafficFromPrev(d: *Driver, comptime set: bool) !void {
        try d.self._impl.driverStopAuxTrafficFromPrev(set, d.id);
    }
};

const Impl = union(enum) {
    invalid: void,
    CcLinkVer2: CcLinkVer2,

    fn deinit(self: *Impl) void {
        switch (self.*) {
            .invalid => unreachable,
            inline else => |*impl| impl.deinit(),
        }
    }

    // Connection functions.
    fn open(self: *Impl) !void {
        switch (self.*) {
            .invalid => unreachable,
            inline else => |*impl| try impl.open(),
        }
    }
    fn close(self: *Impl) !void {
        switch (self.*) {
            .invalid => unreachable,
            inline else => |*impl| try impl.close(),
        }
    }
    fn poll(self: *Impl) !void {
        switch (self.*) {
            .invalid => unreachable,
            inline else => |*impl| try impl.poll(),
        }
    }
    fn link(self: *Impl) !void {
        switch (self.*) {
            .invalid => unreachable,
            inline else => |*impl| try impl.link(),
        }
    }
    fn unlink(self: *Impl) !void {
        switch (self.*) {
            .invalid => unreachable,
            inline else => |*impl| try impl.unlink(),
        }
    }

    // Driver functions.
    fn driverLink(self: *Impl, comptime set: bool, id: Driver.Id) !void {
        switch (self.*) {
            .invalid => unreachable,
            inline else => |*impl| try impl.driverLink(set, id),
        }
    }
    fn driverStopAuxTrafficFromNext(
        self: *Impl,
        comptime set: bool,
        id: Driver.Id,
    ) !void {
        switch (self.*) {
            .invalid => unreachable,
            inline else => |*impl| try impl.driverStopAuxTrafficFromNext(
                set,
                id,
            ),
        }
    }
    fn driverStopAuxTrafficFromPrev(
        self: *Impl,
        comptime set: bool,
        id: Driver.Id,
    ) !void {
        switch (self.*) {
            .invalid => unreachable,
            inline else => |*impl| try impl.driverStopAuxTrafficFromPrev(
                set,
                id,
            ),
        }
    }

    // Command functions.
    fn commandStart(self: *Impl, comptime set: bool, id: Driver.Id) !void {
        switch (self.*) {
            .invalid => unreachable,
            inline else => |*impl| try impl.commandStart(set, id),
        }
    }
    fn commandClearReceived(
        self: *Impl,
        comptime set: bool,
        id: Driver.Id,
    ) !void {
        switch (self.*) {
            .invalid => unreachable,
            inline else => |*impl| try impl.commandClearReceived(set, id),
        }
    }
    fn commandHome(self: *Impl, id: Driver.Id) !void {
        switch (self.*) {
            .invalid => unreachable,
            inline else => |*impl| try impl.commandHome(id),
        }
    }
    fn commandPosMoveAxis(
        self: *Impl,
        did: Driver.Id,
        sid: SliderId,
        aid: Axis.IdSystem,
        speed: i16,
        acceleration: i16,
    ) !void {
        switch (self.*) {
            .invalid => unreachable,
            inline else => |*impl| try impl.commandPosMoveAxis(
                did,
                sid,
                aid,
                speed,
                acceleration,
            ),
        }
    }
    fn commandPosMoveLocation(
        self: *Impl,
        did: Driver.Id,
        sid: SliderId,
        loc: Distance,
        speed: i16,
        acceleration: i16,
    ) !void {
        switch (self.*) {
            .invalid => unreachable,
            inline else => |*impl| try impl.commandPosMoveLocation(
                did,
                sid,
                loc,
                speed,
                acceleration,
            ),
        }
    }
    fn commandPosMoveDistance(
        self: *Impl,
        did: Driver.Id,
        sid: SliderId,
        dist: Distance,
        speed: i16,
        acceleration: i16,
    ) !void {
        switch (self.*) {
            .invalid => unreachable,
            inline else => |*impl| try impl.commandPosMoveDistance(
                did,
                sid,
                dist,
                speed,
                acceleration,
            ),
        }
    }

    // Axis functions.
    fn axisReleaseServo(
        self: *Impl,
        comptime set: bool,
        did: Driver.Id,
        aid: Axis.IdDriver,
    ) !void {
        switch (self.*) {
            .invalid => unreachable,
            inline else => |*impl| try impl.axisReleaseServo(set, did, aid),
        }
    }

    fn axisRecoverSlider(
        self: *Impl,
        did: Driver.Id,
        aid: Axis.IdDriver,
        new_slider_id: SliderId,
    ) !void {
        switch (self.*) {
            .invalid => unreachable,
            inline else => |*impl| try impl.axisRecoverSlider(
                did,
                aid,
                new_slider_id,
            ),
        }
    }
};
const CcLinkVer2 = @import("Connection/CC-Link_Ver.2.zig");
