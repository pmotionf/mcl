//! CC-Link Station. One occupied Ver.2 Remote Device station, 4x Expanded
//! Cyclic.
const std = @import("std");

pub const Index = u6;
pub const Direction = enum(u1) {
    backward = 0,
    forward = 1,
};

/// Inclusive index range of stations.
pub const IndexRange = struct {
    start: u6,
    end: u6,
};

pub const Reference = struct {
    x: *X,
    y: *Y,
    wr: *Wr,
    ww: *Ww,
};

pub const Distance = packed struct(u32) {
    mm: i16 = 0,
    um: i16 = 0,
};

x: X = .{},
y: Y = .{},
wr: Wr = .{},
ww: Ww = .{},

/// Registers written through CC-Link's "DevX" device. Used as a "read"
/// register bank.
pub const X = packed struct(u64) {
    cc_link_enabled: bool = false,
    service_enabled: bool = false,
    ready_for_command: bool = false,
    servo_active: packed struct(u3) {
        axis1: bool = false,
        axis2: bool = false,
        axis3: bool = false,

        pub fn axis(self: @This(), a: u2) bool {
            return switch (a) {
                0 => self.axis1,
                1 => self.axis2,
                2 => self.axis3,
                3 => {
                    std.log.err(
                        "Invalid axis index 3 for `servo_active`",
                        .{},
                    );
                    unreachable;
                },
            };
        }
    } = .{},
    servo_enabled: bool = false,
    emergency_stop_enabled: bool = false,
    paused: bool = false,
    axis_slider_info_cleared: bool = false,
    command_received: bool = false,
    axis_enabled: packed struct(u3) {
        axis1: bool = false,
        axis2: bool = false,
        axis3: bool = false,

        pub fn axis(self: @This(), a: u2) bool {
            return switch (a) {
                0 => self.axis1,
                1 => self.axis2,
                2 => self.axis3,
                3 => {
                    std.log.err(
                        "Invalid axis index 3 for `axis_enabled`",
                        .{},
                    );
                    unreachable;
                },
            };
        }
    } = .{},
    in_position: packed struct(u3) {
        axis1: bool = false,
        axis2: bool = false,
        axis3: bool = false,

        pub fn axis(self: @This(), a: u2) bool {
            return switch (a) {
                0 => self.axis1,
                1 => self.axis2,
                2 => self.axis3,
                3 => {
                    std.log.err("Invalid axis index 3 for `in_position`", .{});
                    unreachable;
                },
            };
        }
    } = .{},
    entered_front: packed struct(u3) {
        axis1: bool = false,
        axis2: bool = false,
        axis3: bool = false,

        pub fn axis(self: @This(), a: u2) bool {
            return switch (a) {
                0 => self.axis1,
                1 => self.axis2,
                2 => self.axis3,
                3 => {
                    std.log.err(
                        "Invalid axis index 3 for `entered_front`",
                        .{},
                    );
                    unreachable;
                },
            };
        }
    } = .{},
    entered_back: packed struct(u3) {
        axis1: bool = false,
        axis2: bool = false,
        axis3: bool = false,

        pub fn axis(self: @This(), a: u2) bool {
            return switch (a) {
                0 => self.axis1,
                1 => self.axis2,
                2 => self.axis3,
                3 => {
                    std.log.err(
                        "Invalid axis index 3 for `entered_back`",
                        .{},
                    );
                    unreachable;
                },
            };
        }
    } = .{},
    transmission_stopped: packed struct(u2) {
        from_prev: bool = false,
        from_next: bool = false,

        pub fn from(self: @This(), dir: Direction) bool {
            return switch (dir) {
                .backward => self.from_prev,
                .forward => self.from_next,
            };
        }
    } = .{},
    errors_cleared: bool = false,
    communication_error: packed struct(u2) {
        from_prev: bool = false,
        from_next: bool = false,

        pub fn from(self: @This(), dir: Direction) bool {
            return switch (dir) {
                .backward => self.from_prev,
                .forward => self.from_next,
            };
        }
    } = .{},
    inverter_overheat_detected: bool = false,
    overcurrent_detected: packed struct(u3) {
        axis1: bool = false,
        axis2: bool = false,
        axis3: bool = false,

        pub fn axis(self: @This(), a: u2) bool {
            return switch (a) {
                0 => self.axis1,
                1 => self.axis2,
                2 => self.axis3,
                3 => {
                    std.log.err(
                        "Invalid axis index 3 for `overcurrent_detected`",
                        .{},
                    );
                    unreachable;
                },
            };
        }
    } = .{},
    control_failure: packed struct(u3) {
        axis1: bool = false,
        axis2: bool = false,
        axis3: bool = false,

        pub fn axis(self: @This(), a: u2) bool {
            return switch (a) {
                0 => self.axis1,
                1 => self.axis2,
                2 => self.axis3,
                3 => {
                    std.log.err(
                        "Invalid axis index 3 for `control_failure`",
                        .{},
                    );
                    unreachable;
                },
            };
        }
    } = .{},
    hall_alarm: packed struct(u6) {
        axis1: packed struct(u2) {
            back: bool = false,
            front: bool = false,
        } = .{},
        axis2: packed struct(u2) {
            back: bool = false,
            front: bool = false,
        } = .{},
        axis3: packed struct(u2) {
            back: bool = false,
            front: bool = false,
        } = .{},

        pub fn axis(self: @This(), a: u2) packed struct(u2) {
            back: bool,
            front: bool,
        } {
            return switch (a) {
                0 => .{
                    .back = self.axis1.back,
                    .front = self.axis1.front,
                },
                1 => .{
                    .back = self.axis2.back,
                    .front = self.axis2.front,
                },
                2 => .{
                    .back = self.axis3.back,
                    .front = self.axis3.front,
                },
                3 => {
                    std.log.err("Invalid axis index 3 for `hall_alarm`", .{});
                    unreachable;
                },
            };
        }
    } = .{},
    self_pause: packed struct(u3) {
        axis1: bool = false,
        axis2: bool = false,
        axis3: bool = false,

        pub fn axis(self: @This(), a: u2) bool {
            return switch (a) {
                0 => self.axis1,
                1 => self.axis2,
                2 => self.axis3,
                3 => {
                    std.log.err("Invalid axis index 3 for `self_pause`", .{});
                    unreachable;
                },
            };
        }
    } = .{},
    pulling_slider: packed struct(u3) {
        axis1: bool = false,
        axis2: bool = false,
        axis3: bool = false,

        pub fn axis(self: @This(), a: u2) bool {
            return switch (a) {
                0 => self.axis1,
                1 => self.axis2,
                2 => self.axis3,
                3 => {
                    std.log.err(
                        "Invalid axis index 3 for `pulling_slider`",
                        .{},
                    );
                    unreachable;
                },
            };
        }
    } = .{},
    control_loop_max_time_exceeded: bool = false,
    hall_alarm_abnormal: packed struct(u6) {
        axis1: packed struct(u2) {
            back: bool = false,
            front: bool = false,
        } = .{},
        axis2: packed struct(u2) {
            back: bool = false,
            front: bool = false,
        } = .{},
        axis3: packed struct(u2) {
            back: bool = false,
            front: bool = false,
        } = .{},

        pub fn axis(self: @This(), a: u2) packed struct(u2) {
            back: bool,
            front: bool,
        } {
            return switch (a) {
                0 => .{
                    .back = self.axis1.back,
                    .front = self.axis1.front,
                },
                1 => .{
                    .back = self.axis2.back,
                    .front = self.axis2.front,
                },
                2 => .{
                    .back = self.axis3.back,
                    .front = self.axis3.front,
                },
                3 => {
                    std.log.err(
                        "Invalid axis index 3 for `hall_alarm_abnormal`",
                        .{},
                    );
                    unreachable;
                },
            };
        }
    } = .{},
    chain_enabled: packed struct(u6) {
        axis1: packed struct(u2) {
            backward: bool = false,
            forward: bool = false,
        } = .{},
        axis2: packed struct(u2) {
            backward: bool = false,
            forward: bool = false,
        } = .{},
        axis3: packed struct(u2) {
            backward: bool = false,
            forward: bool = false,
        } = .{},

        pub fn axis(self: @This(), a: u2) packed struct(u2) {
            backward: bool,
            forward: bool,
        } {
            return switch (a) {
                0 => .{
                    .backward = self.axis1.backward,
                    .forward = self.axis1.forward,
                },
                1 => .{
                    .backward = self.axis2.backward,
                    .forward = self.axis2.forward,
                },
                2 => .{
                    .backward = self.axis3.backward,
                    .forward = self.axis3.forward,
                },
                3 => {
                    std.log.err(
                        "Invalid axis index 3 for `chain_enabled`",
                        .{},
                    );
                    unreachable;
                },
            };
        }
    } = .{},
    _60: u4 = 0,

    pub fn format(
        x: X,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.writeAll("X{\n");
        try writer.print("\tcc_link_enabled: {},\n", .{x.cc_link_enabled});
        try writer.print("\tservice_enabled: {},\n", .{x.service_enabled});
        try writer.print(
            "\tready_for_command: {},\n",
            .{x.ready_for_command},
        );
        try writer.writeAll("\tservo_active: {\n");
        try writer.print("\t\taxis1: {},\n", .{x.servo_active.axis1});
        try writer.print("\t\taxis2: {},\n", .{x.servo_active.axis2});
        try writer.print("\t\taxis3: {},\n", .{x.servo_active.axis3});
        try writer.writeAll("\t},\n");
        try writer.print("\tservo_enabled: {},\n", .{x.servo_enabled});
        try writer.print(
            "\temergency_stop_enabled: {},\n",
            .{x.emergency_stop_enabled},
        );
        try writer.print("\tpaused: {},\n", .{x.paused});
        try writer.print(
            "\taxis_slider_info_cleared: {},\n",
            .{x.axis_slider_info_cleared},
        );
        try writer.print(
            "\tcommand_received: {},\n",
            .{x.command_received},
        );
        try writer.writeAll("\taxis_enabled: {\n");
        try writer.print("\t\taxis1: {},\n", .{x.axis_enabled.axis1});
        try writer.print("\t\taxis2: {},\n", .{x.axis_enabled.axis2});
        try writer.print("\t\taxis3: {},\n", .{x.axis_enabled.axis3});
        try writer.writeAll("\t},\n");
        try writer.writeAll("\tin_position: {\n");
        try writer.print("\t\taxis1: {},\n", .{x.in_position.axis1});
        try writer.print("\t\taxis2: {},\n", .{x.in_position.axis2});
        try writer.print("\t\taxis3: {},\n", .{x.in_position.axis3});
        try writer.writeAll("\t},\n");
        try writer.writeAll("\tentered_front: {\n");
        try writer.print("\t\taxis1: {},\n", .{x.entered_front.axis1});
        try writer.print("\t\taxis2: {},\n", .{x.entered_front.axis2});
        try writer.print("\t\taxis3: {},\n", .{x.entered_front.axis3});
        try writer.writeAll("\t},\n");
        try writer.writeAll("\tentered_back: {\n");
        try writer.print("\t\taxis1: {},\n", .{x.entered_back.axis1});
        try writer.print("\t\taxis2: {},\n", .{x.entered_back.axis2});
        try writer.print("\t\taxis3: {},\n", .{x.entered_back.axis3});
        try writer.writeAll("\t},\n");
        try writer.writeAll("\ttransmission_stopped: {\n");
        try writer.print(
            "\t\tfrom_prev: {},\n",
            .{x.transmission_stopped.from_prev},
        );
        try writer.print(
            "\t\tfrom_next: {},\n",
            .{x.transmission_stopped.from_next},
        );
        try writer.writeAll("\t},\n");
        try writer.print("\terrors_cleared: {},\n", .{x.errors_cleared});
        try writer.writeAll("\tcommunication_error: {\n");
        try writer.print(
            "\t\tfrom_prev: {},\n",
            .{x.communication_error.from_prev},
        );
        try writer.print(
            "\t\tfrom_next: {},\n",
            .{x.communication_error.from_next},
        );
        try writer.writeAll("\t},\n");
        try writer.print(
            "\tinverter_overheat_detected: {},\n",
            .{x.inverter_overheat_detected},
        );
        try writer.writeAll("\tovercurrent_detected: {\n");
        try writer.print(
            "\t\taxis1: {},\n",
            .{x.overcurrent_detected.axis1},
        );
        try writer.print(
            "\t\taxis2: {},\n",
            .{x.overcurrent_detected.axis2},
        );
        try writer.print(
            "\t\taxis3: {},\n",
            .{x.overcurrent_detected.axis3},
        );
        try writer.writeAll("\t},\n");
        try writer.writeAll("\tcontrol_failure: {\n");
        try writer.print("\t\taxis1: {},\n", .{x.control_failure.axis1});
        try writer.print("\t\taxis2: {},\n", .{x.control_failure.axis2});
        try writer.print("\t\taxis3: {},\n", .{x.control_failure.axis3});
        try writer.writeAll("\t},\n");
        try writer.writeAll("\thall_alarm: {\n");
        for (0..3) |_i| {
            const i: u2 = @intCast(_i);
            try writer.print("\t\taxis{}: {{\n", .{i + 1});
            try writer.print(
                "\t\t\tback: {},\n",
                .{x.hall_alarm.axis(i).back},
            );
            try writer.print(
                "\t\t\tfront: {},\n",
                .{x.hall_alarm.axis(i).front},
            );
            try writer.writeAll("\t\t},\n");
        }
        try writer.writeAll("\t},\n");
        try writer.writeAll("\tself_pause: {\n");
        try writer.print("\t\taxis1: {},\n", .{x.self_pause.axis1});
        try writer.print("\t\taxis2: {},\n", .{x.self_pause.axis2});
        try writer.print("\t\taxis3: {},\n", .{x.self_pause.axis3});
        try writer.writeAll("\t},\n");
        try writer.writeAll("\tpulling_slider: {\n");
        try writer.print("\t\taxis1: {},\n", .{x.pulling_slider.axis1});
        try writer.print("\t\taxis2: {},\n", .{x.pulling_slider.axis2});
        try writer.print("\t\taxis3: {},\n", .{x.pulling_slider.axis3});
        try writer.writeAll("\t},\n");
        try writer.print(
            "\tcontrol_loop_max_time_exceeded: {},\n",
            .{x.control_loop_max_time_exceeded},
        );
        try writer.writeAll("\thall_alarm_abnormal: {\n");
        for (0..3) |_i| {
            const i: u2 = @intCast(_i);
            try writer.print("\t\taxis{}: {{\n", .{i + 1});
            try writer.print(
                "\t\t\tback: {},\n",
                .{x.hall_alarm_abnormal.axis(i).back},
            );
            try writer.print(
                "\t\t\tfront: {},\n",
                .{x.hall_alarm_abnormal.axis(i).front},
            );
            try writer.writeAll("\t\t},\n");
        }
        try writer.writeAll("\t},\n");
        try writer.writeAll("}\n");
        try writer.writeAll("\tchain_enabled: {\n");
        for (0..3) |_i| {
            const i: u2 = @intCast(_i);
            try writer.print("\t\taxis{}: {{\n", .{i + 1});
            try writer.print(
                "\t\t\tback: {},\n",
                .{x.chain_enabled.axis(i).backward},
            );
            try writer.print(
                "\t\t\tfront: {},\n",
                .{x.chain_enabled.axis(i).forward},
            );
            try writer.writeAll("\t\t},\n");
        }
        try writer.writeAll("\t},\n");
        try writer.writeAll("}\n");
    }
};

test "X" {
    try std.testing.expectEqual(8, @sizeOf(X));
}

/// Registers written through CC-Link's "DevY" device. Used as a "write"
/// register bank.
pub const Y = packed struct(u64) {
    cc_link_enable: bool = false,
    service_enable: bool = false,
    start_command: bool = false,
    reset_command_received: bool = false,
    _4: u1 = 0,
    axis_servo_release: bool = false,
    servo_release: bool = false,
    emergency_stop: bool = false,
    temporary_pause: bool = false,
    stop_driver_transmission: packed struct(u2) {
        from_prev: bool = false,
        from_next: bool = false,

        pub fn from(self: @This(), dir: Direction) bool {
            return switch (dir) {
                .backward => self.from_prev,
                .forward => self.from_next,
            };
        }

        pub fn setFrom(
            self: *align(8:9:8) @This(),
            dir: Direction,
            val: bool,
        ) void {
            switch (dir) {
                .backward => self.from_prev = val,
                .forward => self.from_next = val,
            }
        }
    } = .{},
    clear_errors: bool = false,
    clear_axis_slider_info: bool = false,
    prev_axis_isolate_link: bool = false,
    next_axis_isolate_link: bool = false,
    _15: u1 = 0,
    reset_pull_slider: packed struct(u3) {
        axis1: bool = false,
        axis2: bool = false,
        axis3: bool = false,

        pub fn axis(self: @This(), local_axis: u2) bool {
            return switch (local_axis) {
                0 => self.axis1,
                1 => self.axis2,
                2 => self.axis3,
                3 => {
                    std.log.err(
                        "Invalid axis index 3 for `reset_pull_slider`",
                        .{},
                    );
                    unreachable;
                },
            };
        }

        pub fn setAxis(
            self: *align(8:16:8) @This(),
            local_axis: u2,
            val: bool,
        ) void {
            switch (local_axis) {
                0 => self.axis1 = val,
                1 => self.axis2 = val,
                2 => self.axis3 = val,
                3 => {
                    std.log.err(
                        "Invalid axis index 3 for `reset_pull_slider`",
                        .{},
                    );
                    unreachable;
                },
            }
        }
    } = .{},
    recovery_use_hall_sensor: packed struct(u2) {
        back: bool = false,
        front: bool = false,

        pub fn side(self: @This(), dir: Direction) bool {
            return switch (dir) {
                .backward => self.back,
                .forward => self.front,
            };
        }

        pub fn setSide(
            self: *align(8:19:8) @This(),
            dir: Direction,
            val: bool,
        ) void {
            switch (dir) {
                .backward => self.back = val,
                .forward => self.front = val,
            }
        }
    } = .{},
    link_chain: packed struct(u6) {
        axis1: packed struct(u2) {
            backward: bool = false,
            forward: bool = false,
        } = .{},
        axis2: packed struct(u2) {
            backward: bool = false,
            forward: bool = false,
        } = .{},
        axis3: packed struct(u2) {
            backward: bool = false,
            forward: bool = false,
        } = .{},

        pub fn axis(self: @This(), a: u2) packed struct(u2) {
            backward: bool,
            forward: bool,
        } {
            return switch (a) {
                0 => .{
                    .backward = self.axis1.backward,
                    .forward = self.axis1.forward,
                },
                1 => .{
                    .backward = self.axis2.backward,
                    .forward = self.axis2.forward,
                },
                2 => .{
                    .backward = self.axis3.backward,
                    .forward = self.axis3.forward,
                },
                3 => {
                    std.log.err("Invalid axis index 3 for `link_chain`", .{});
                    unreachable;
                },
            };
        }

        pub fn setAxis(self: *align(8:21:8) @This(), a: u2, val: struct {
            backward: ?bool = null,
            forward: ?bool = null,
        }) void {
            switch (a) {
                0 => {
                    if (val.backward) |b| {
                        self.axis1.backward = b;
                    }
                    if (val.forward) |f| {
                        self.axis1.forward = f;
                    }
                },
                1 => {
                    if (val.backward) |b| {
                        self.axis2.backward = b;
                    }
                    if (val.forward) |f| {
                        self.axis2.forward = f;
                    }
                },
                2 => {
                    if (val.backward) |b| {
                        self.axis3.backward = b;
                    }
                    if (val.forward) |f| {
                        self.axis3.forward = f;
                    }
                },
                3 => {
                    std.log.err("Invalid axis index 3 for `link_chain`", .{});
                    unreachable;
                },
            }
        }
    } = .{},
    unlink_chain: packed struct(u6) {
        axis1: packed struct(u2) {
            backward: bool = false,
            forward: bool = false,
        } = .{},
        axis2: packed struct(u2) {
            backward: bool = false,
            forward: bool = false,
        } = .{},
        axis3: packed struct(u2) {
            backward: bool = false,
            forward: bool = false,
        } = .{},

        pub fn axis(self: @This(), a: u2) packed struct(u2) {
            backward: bool,
            forward: bool,
        } {
            return switch (a) {
                0 => .{
                    .backward = self.axis1.backward,
                    .forward = self.axis1.forward,
                },
                1 => .{
                    .backward = self.axis2.backward,
                    .forward = self.axis2.forward,
                },
                2 => .{
                    .backward = self.axis3.backward,
                    .forward = self.axis3.forward,
                },
                3 => {
                    std.log.err(
                        "Invalid axis index 3 for `unlink_chain`",
                        .{},
                    );
                    unreachable;
                },
            };
        }

        pub fn setAxis(self: *align(8:27:8) @This(), a: u2, val: struct {
            backward: ?bool = null,
            forward: ?bool = null,
        }) void {
            switch (a) {
                0 => {
                    if (val.backward) |b| {
                        self.axis1.backward = b;
                    }
                    if (val.forward) |f| {
                        self.axis1.forward = f;
                    }
                },
                1 => {
                    if (val.backward) |b| {
                        self.axis2.backward = b;
                    }
                    if (val.forward) |f| {
                        self.axis2.forward = f;
                    }
                },
                2 => {
                    if (val.backward) |b| {
                        self.axis3.backward = b;
                    }
                    if (val.forward) |f| {
                        self.axis3.forward = f;
                    }
                },
                3 => {
                    std.log.err(
                        "Invalid axis index 3 for `unlink_chain`",
                        .{},
                    );
                    unreachable;
                },
            }
        }
    } = .{},
    _33: u31 = 0,

    pub fn format(
        y: Y,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.writeAll("Y{\n");
        try writer.print("\tcc_link_enable: {},\n", .{y.cc_link_enable});
        try writer.print("\tservice_enable: {},\n", .{y.service_enable});
        try writer.print("\tstart_command: {},\n", .{y.start_command});
        try writer.print(
            "\treset_command_received: {},\n",
            .{y.reset_command_received},
        );
        try writer.print(
            "\taxis_servo_release: {},\n",
            .{y.axis_servo_release},
        );
        try writer.print("\tservo_release: {},\n", .{y.servo_release});
        try writer.print("\temergency_stop: {},\n", .{y.emergency_stop});
        try writer.print("\ttemporary_pause: {},\n", .{y.temporary_pause});
        try writer.writeAll("\tstop_driver_transmission: {\n");
        try writer.print(
            "\t\tfrom_prev: {},\n",
            .{y.stop_driver_transmission.from_prev},
        );
        try writer.print(
            "\t\tfrom_next: {},\n",
            .{y.stop_driver_transmission.from_next},
        );
        try writer.writeAll("\t},\n");
        try writer.print("\tclear_errors: {},\n", .{y.clear_errors});
        try writer.print(
            "\tclear_axis_slider_info: {},\n",
            .{y.clear_axis_slider_info},
        );
        try writer.print(
            "\tprev_axis_isolate_link: {},\n",
            .{y.prev_axis_isolate_link},
        );
        try writer.print(
            "\tnext_axis_isolate_link: {},\n",
            .{y.next_axis_isolate_link},
        );
        try writer.writeAll("\treset_pull_slider: {\n");
        try writer.print("\t\taxis1: {},\n", .{y.reset_pull_slider.axis1});
        try writer.print("\t\taxis2: {},\n", .{y.reset_pull_slider.axis2});
        try writer.print("\t\taxis3: {},\n", .{y.reset_pull_slider.axis3});
        try writer.writeAll("\t},\n");
        try writer.writeAll("}\n");
        try writer.writeAll("\trecovery_use_hall_sensor: {\n");
        try writer.print(
            "\t\tback: {},\n",
            .{y.recovery_use_hall_sensor.back},
        );
        try writer.print(
            "\t\tfront: {},\n",
            .{y.recovery_use_hall_sensor.front},
        );
        try writer.writeAll("\t},\n");
        try writer.writeAll("\tlink_chain: {\n");
        for (0..3) |_i| {
            const i: u2 = @intCast(_i);
            try writer.print("\t\taxis{}: {{\n", .{i + 1});
            try writer.print(
                "\t\t\tbackward: {},\n",
                .{y.link_chain.axis(i).backward},
            );
            try writer.print(
                "\t\t\tforward: {},\n",
                .{y.link_chain.axis(i).forward},
            );
            try writer.writeAll("\t\t},\n");
        }
        try writer.writeAll("\t},\n");
        try writer.writeAll("\tunlink_chain: {\n");
        for (0..3) |_i| {
            const i: u2 = @intCast(_i);
            try writer.print("\t\taxis{}: {{\n", .{i + 1});
            try writer.print(
                "\t\t\tbackward: {},\n",
                .{y.unlink_chain.axis(i).backward},
            );
            try writer.print(
                "\t\t\tforward: {},\n",
                .{y.unlink_chain.axis(i).forward},
            );
            try writer.writeAll("\t\t},\n");
        }
        try writer.writeAll("\t},\n");
    }
};

test "Y" {
    try std.testing.expectEqual(8, @sizeOf(Y));
}

/// Registers written through CC-Link's "DevWr" device. Used as a "read"
/// register bank.
pub const Wr = packed struct(u256) {
    command_response: CommandResponseCode = .NoError,
    slider_number: packed struct(u48) {
        axis1: u16 = 0,
        axis2: u16 = 0,
        axis3: u16 = 0,

        pub fn axis(self: @This(), a: u2) u16 {
            return switch (a) {
                0 => self.axis1,
                1 => self.axis2,
                2 => self.axis3,
                3 => {
                    std.log.err(
                        "Invalid axis index 3 for `slider_number`",
                        .{},
                    );
                    unreachable;
                },
            };
        }
    } = .{},
    slider_location: packed struct(u96) {
        axis1: Distance = .{},
        axis2: Distance = .{},
        axis3: Distance = .{},

        pub fn axis(self: @This(), a: u2) Distance {
            return switch (a) {
                0 => self.axis1,
                1 => self.axis2,
                2 => self.axis3,
                3 => {
                    std.log.err(
                        "Invalid axis index 3 for `slider_location`",
                        .{},
                    );
                    unreachable;
                },
            };
        }
    } = .{},
    slider_state: packed struct(u48) {
        axis1: SliderStateCode = .None,
        axis2: SliderStateCode = .None,
        axis3: SliderStateCode = .None,

        pub fn axis(self: @This(), a: u2) SliderStateCode {
            return switch (a) {
                0 => self.axis1,
                1 => self.axis2,
                2 => self.axis3,
                3 => {
                    std.log.err(
                        "Invalid axis index 3 for `slider_state`",
                        .{},
                    );
                    unreachable;
                },
            };
        }
    } = .{},
    pitch_count: packed struct(u48) {
        axis1: i16 = 0,
        axis2: i16 = 0,
        axis3: i16 = 0,

        pub fn axis(self: @This(), a: u2) i16 {
            return switch (a) {
                0 => self.axis1,
                1 => self.axis2,
                2 => self.axis3,
                3 => {
                    std.log.err(
                        "Invalid axis index 3 for `pitch_count`",
                        .{},
                    );
                    unreachable;
                },
            };
        }
    } = .{},

    pub const CommandResponseCode = enum(i16) {
        NoError = 0,
        InvalidCommand = 1,
        SliderNotFound = 2,
        HomingFailed = 3,
        InvalidParameter = 4,
        InvalidSystemState = 5,
        SliderAlreadyExists = 6,
        InvalidAxis = 7,

        pub fn throwError(code: CommandResponseCode) !void {
            return switch (code) {
                .NoError => {},
                .InvalidCommand => return error.InvalidCommand,
                .SliderNotFound => return error.SliderNotFound,
                .HomingFailed => return error.HomingFailed,
                .InvalidParameter => return error.InvalidParameter,
                .InvalidSystemState => return error.InvalidSystemState,
                .SliderAlreadyExists => return error.SliderAlreadyExists,
                .InvalidAxis => return error.InvalidAxis,
            };
        }
    };

    pub const SliderStateCode = enum(i16) {
        None = 0,
        WarmupProgressing = 1,
        WarmupCompleted = 2,
        WarmupFault = 3,
        CurrentBiasProgressing = 4,
        CurrentBiasCompleted = 5,
        HomeForward = 6,
        HomeBackward = 7,
        RampForwardProgressing = 8,
        RampForwardCompleted = 9,
        RampForwardFault = 10,
        RampBackwardProgressing = 11,
        RampBackwardCompleted = 12,
        RampBackwardFault = 13,
        // TODO: Clarify names of below
        FwdEncProgressing = 14,
        FwdEncCompleted = 15,
        FwdEncFault = 16,
        BwdEncProgressing = 17,
        BwdEncCompleted = 18,
        BwdEncFault = 19,
        CurrentStepProgressing = 20,
        CurrentStepCompleted = 21,
        CurrentStepFault = 22,
        SpeedStepProgressing = 23,
        SpeedStepCompleted = 24,
        SpeedStepFault = 25,
        PosStepProgressing = 26,
        PosStepCompleted = 27,
        PosStepFault = 28,
        PosMoveProgressing = 29,
        PosMoveCompleted = 30,
        PosMoveFault = 31,
        ForwardCalibrationProgressing = 32,
        ForwardCalibrationCompleted = 33,
        BackwardIsolationProgressing = 34,
        BackwardIsolationCompleted = 35,
        ForwardRestartProgressing = 36,
        ForwardRestartCompleted = 37,
        BackwardRestartProgressing = 38,
        BackwardRestartCompleted = 39,
        SpdMoveProgressing = 40,
        SpdMoveCompleted = 41,
        SpdMoveFault = 42,
        NextAxisAuxiliary = 43,
        // Note: Next Axis Completed will show even when the next axis is
        // progressing, if the slider is paused for collision avoidance on the
        // next axis.
        NextAxisCompleted = 44,
        PrevAxisAuxiliary = 45,
        // Note: Prev Axis Completed will show even when the prev axis is
        // progressing, if the slider is paused for collision avoidance on the
        // prev axis.
        PrevAxisCompleted = 46,
        ForwardIsolationProgressing = 47,
        ForwardIsolationCompleted = 48,
        Overcurrent = 50,
        CommunicationError = 51,
        PullForward = 52,
        PullForwardCompleted = 53,
        PullForwardFault = 54,
        PullBackward = 55,
        PullBackwardCompleted = 56,
        PullBackwardFault = 57,
        BackwardCalibrationProgressing = 58,
        BackwardCalibrationCompleted = 59,
        BackwardCalibrationFault = 60,
        ForwardCalibrationFault = 61,
    };

    pub fn format(
        wr: Wr,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.writeAll("Wr: {\n");
        try writer.print(
            "\tcommand_response: {},\n",
            .{wr.command_response},
        );
        try writer.writeAll("\tslider_number: {\n");
        try writer.print("\t\taxis1: {},\n", .{wr.slider_number.axis1});
        try writer.print("\t\taxis2: {},\n", .{wr.slider_number.axis2});
        try writer.print("\t\taxis3: {},\n", .{wr.slider_number.axis3});
        try writer.writeAll("\t},\n");
        try writer.writeAll("\tslider_location: {\n");
        try writer.print("\t\taxis1: {},\n", .{wr.slider_location.axis1});
        try writer.print("\t\taxis2: {},\n", .{wr.slider_location.axis2});
        try writer.print("\t\taxis3: {},\n", .{wr.slider_location.axis3});
        try writer.writeAll("\t},\n");
        try writer.writeAll("\tslider_state: {\n");
        try writer.print("\t\taxis1: {},\n", .{wr.slider_state.axis1});
        try writer.print("\t\taxis2: {},\n", .{wr.slider_state.axis2});
        try writer.print("\t\taxis3: {},\n", .{wr.slider_state.axis3});
        try writer.writeAll("\t},\n");
        try writer.writeAll("\tpitch_count: {\n");
        try writer.print("\t\taxis1: {},\n", .{wr.pitch_count.axis1});
        try writer.print("\t\taxis2: {},\n", .{wr.pitch_count.axis2});
        try writer.print("\t\taxis3: {},\n", .{wr.pitch_count.axis3});
        try writer.writeAll("\t},\n");
        try writer.writeAll("}\n");
    }
};

test "Wr" {
    try std.testing.expectEqual(32, @sizeOf(Wr));
}

/// Registers written through CC-Link's "DevWw" device. Used as a "write"
/// register bank.
pub const Ww = packed struct(u256) {
    command_code: CommandCode = .None,
    command_slider_number: u16 = 0,
    target_axis_number: u16 = 0,
    location_distance: Distance = .{},
    speed_percentage: u16 = 0,
    acceleration_percentage: u16 = 0,
    _112: u144 = 0,

    pub const CommandCode = enum(i16) {
        None = 0,
        Home = 17,
        // "By Position" commands calculate slider movement by constant hall
        // sensor position feedback, and is much more precise in destination.
        MoveSliderToAxisByPosition = 18,
        MoveSliderToLocationByPosition = 19,
        MoveSliderDistanceByPosition = 20,
        // "By Speed" commands calculate slider movement by constant hall
        // sensor speed feedback. It should mostly not be used, as the
        // destination position becomes far too imprecise. However, it is
        // meant to maintain a certain speed while the slider is traveling, and
        // to avoid the requirement of having a known system position.
        MoveSliderToAxisBySpeed = 21,
        MoveSliderToLocationBySpeed = 22,
        MoveSliderDistanceBySpeed = 23,
        IsolateForward = 24,
        IsolateBackward = 25,
        Calibration = 26,
        RecoverSystemSliders = 27,
        RecoverSliderAtAxis = 28,
        PushAxisSliderForward = 30,
        PushAxisSliderBackward = 31,
        PullAxisSliderForward = 32,
        PullAxisSliderBackward = 33,
    };

    pub fn format(
        ww: Ww,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.writeAll("Ww: {\n");
        try writer.print("\tcommand_code: {},\n", .{ww.command_code});
        try writer.print(
            "\tcommand_slider_number: {},\n",
            .{ww.command_slider_number},
        );
        try writer.print(
            "\ttarget_axis_number: {},\n",
            .{ww.target_axis_number},
        );
        try writer.print(
            "\tlocation_distance: {},\n",
            .{ww.location_distance},
        );
        try writer.print(
            "\tspeed_percentage: {},\n",
            .{ww.speed_percentage},
        );
        try writer.print(
            "\tacceleration_percentage: {},\n",
            .{ww.acceleration_percentage},
        );
        try writer.writeAll("}\n");
    }
};

test "Ww" {
    try std.testing.expectEqual(32, @sizeOf(Ww));
}
