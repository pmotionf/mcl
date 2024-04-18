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
    } = .{},
    in_position: packed struct(u3) {
        axis1: bool = false,
        axis2: bool = false,
        axis3: bool = false,
    } = .{},
    entered_front: packed struct(u3) {
        axis1: bool = false,
        axis2: bool = false,
        axis3: bool = false,
    } = .{},
    entered_back: packed struct(u3) {
        axis1: bool = false,
        axis2: bool = false,
        axis3: bool = false,
    } = .{},
    transmission_stopped: packed struct(u2) {
        from_prev: bool = false,
        from_next: bool = false,
    } = .{},
    errors_cleared: bool = false,
    communication_error: packed struct(u2) {
        from_prev: bool = false,
        from_next: bool = false,
    } = .{},
    inverter_overheat_detected: bool = false,
    overcurrent_detected: packed struct(u3) {
        axis1: bool = false,
        axis2: bool = false,
        axis3: bool = false,
    } = .{},
    control_failure: packed struct(u3) {
        axis1: bool = false,
        axis2: bool = false,
        axis3: bool = false,
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
    } = .{},
    self_pause: packed struct(u3) {
        axis1: bool = false,
        axis2: bool = false,
        axis3: bool = false,
    } = .{},
    pulling_slider: packed struct(u3) {
        axis1: bool = false,
        axis2: bool = false,
        axis3: bool = false,
    } = .{},
    _47: u1 = 0,
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
    } = .{},
    _60: u4 = 0,

    pub fn servoActive(self: X, axis_index: u2) bool {
        return switch (axis_index) {
            0 => self.servo_active.axis1,
            1 => self.servo_active.axis2,
            2 => self.servo_active.axis3,
            3 => unreachable,
        };
    }

    pub fn axisEnabled(self: X, axis_index: u2) bool {
        return switch (axis_index) {
            0 => self.axis_enabled.axis1,
            1 => self.axis_enabled.axis2,
            2 => self.axis_enabled.axis3,
            3 => unreachable,
        };
    }

    pub fn inPosition(self: X, axis_index: u2) bool {
        return switch (axis_index) {
            0 => self.in_position.axis1,
            1 => self.in_position.axis2,
            2 => self.in_position.axis3,
            3 => unreachable,
        };
    }

    pub fn enteredFront(self: X, axis_index: u2) bool {
        return switch (axis_index) {
            0 => self.entered_front.axis1,
            1 => self.entered_front.axis2,
            2 => self.entered_front.axis3,
            3 => unreachable,
        };
    }

    pub fn enteredBack(self: X, axis_index: u2) bool {
        return switch (axis_index) {
            0 => self.entered_back.axis1,
            1 => self.entered_back.axis2,
            2 => self.entered_back.axis3,
            3 => unreachable,
        };
    }

    pub fn transmissionStopped(self: X, dir: Direction) bool {
        return switch (dir) {
            .backward => self.transmission_stopped.from_prev,
            .forward => self.transmission_stopped.from_next,
        };
    }

    pub fn communicationError(self: X, dir: Direction) bool {
        return switch (dir) {
            .backward => self.communication_error.from_prev,
            .forward => self.communication_error.from_next,
        };
    }

    pub fn overcurrentDetected(self: X, axis_index: u2) bool {
        return switch (axis_index) {
            0 => self.overcurrent_detected.axis1,
            1 => self.overcurrent_detected.axis2,
            2 => self.overcurrent_detected.axis3,
            3 => unreachable,
        };
    }

    pub fn controlFailure(self: X, axis_index: u2) bool {
        return switch (axis_index) {
            0 => self.control_failure.axis1,
            1 => self.control_failure.axis2,
            2 => self.control_failure.axis3,
            3 => unreachable,
        };
    }

    pub fn hallAlarm(self: X, axis_index: u2) struct {
        back: bool,
        front: bool,
    } {
        return switch (axis_index) {
            0 => .{
                .back = self.hall_alarm.axis1.back,
                .front = self.hall_alarm.axis1.front,
            },
            1 => .{
                .back = self.hall_alarm.axis2.back,
                .front = self.hall_alarm.axis2.front,
            },
            2 => .{
                .back = self.hall_alarm.axis3.back,
                .front = self.hall_alarm.axis3.front,
            },
            3 => unreachable,
        };
    }

    pub fn selfPause(self: X, axis_index: u2) bool {
        return switch (axis_index) {
            0 => self.self_pause.axis1,
            1 => self.self_pause.axis2,
            2 => self.self_pause.axis3,
            3 => unreachable,
        };
    }

    pub fn pullingSlider(self: X, axis_index: u2) bool {
        return switch (axis_index) {
            0 => self.pulling_slider.axis1,
            1 => self.pulling_slider.axis2,
            2 => self.pulling_slider.axis3,
            3 => unreachable,
        };
    }

    pub fn hallAlarmAbnormal(self: X, axis_index: u2) struct {
        back: bool,
        front: bool,
    } {
        return switch (axis_index) {
            0 => .{
                .back = self.hall_alarm_abnormal.axis1.back,
                .front = self.hall_alarm_abnormal.axis1.front,
            },
            1 => .{
                .back = self.hall_alarm_abnormal.axis2.back,
                .front = self.hall_alarm_abnormal.axis2.front,
            },
            2 => .{
                .back = self.hall_alarm_abnormal.axis3.back,
                .front = self.hall_alarm_abnormal.axis3.front,
            },
            3 => unreachable,
        };
    }

    pub fn chainEnabled(self: X, axis_index: u2) struct {
        backward: bool,
        forward: bool,
    } {
        return switch (axis_index) {
            0 => .{
                .backward = self.chain_enabled.axis1.backward,
                .forward = self.chain_enabled.axis1.forward,
            },
            1 => .{
                .backward = self.chain_enabled.axis2.backward,
                .forward = self.chain_enabled.axis2.forward,
            },
            2 => .{
                .backward = self.chain_enabled.axis3.backward,
                .forward = self.chain_enabled.axis3.forward,
            },
            else => unreachable,
        };
    }

    pub fn format(
        x: X,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.writeAll("X{\n");
        _ = try writer.print("\tcc_link_enabled: {},\n", .{x.cc_link_enabled});
        _ = try writer.print("\tservice_enabled: {},\n", .{x.service_enabled});
        _ = try writer.print(
            "\tready_for_command: {},\n",
            .{x.ready_for_command},
        );
        _ = try writer.writeAll("\tservo_active: {\n");
        _ = try writer.print("\t\taxis1: {},\n", .{x.servo_active.axis1});
        _ = try writer.print("\t\taxis2: {},\n", .{x.servo_active.axis2});
        _ = try writer.print("\t\taxis3: {},\n", .{x.servo_active.axis3});
        _ = try writer.writeAll("\t},\n");
        _ = try writer.print("\tservo_enabled: {},\n", .{x.servo_enabled});
        _ = try writer.print(
            "\temergency_stop_enabled: {},\n",
            .{x.emergency_stop_enabled},
        );
        _ = try writer.print("\tpaused: {},\n", .{x.paused});
        _ = try writer.print(
            "\taxis_slider_info_cleared: {},\n",
            .{x.axis_slider_info_cleared},
        );
        _ = try writer.print(
            "\tcommand_received: {},\n",
            .{x.command_received},
        );
        _ = try writer.writeAll("\taxis_enabled: {\n");
        _ = try writer.print("\t\taxis1: {},\n", .{x.axis_enabled.axis1});
        _ = try writer.print("\t\taxis2: {},\n", .{x.axis_enabled.axis2});
        _ = try writer.print("\t\taxis3: {},\n", .{x.axis_enabled.axis3});
        _ = try writer.writeAll("\t},\n");
        _ = try writer.writeAll("\tin_position: {\n");
        _ = try writer.print("\t\taxis1: {},\n", .{x.in_position.axis1});
        _ = try writer.print("\t\taxis2: {},\n", .{x.in_position.axis2});
        _ = try writer.print("\t\taxis3: {},\n", .{x.in_position.axis3});
        _ = try writer.writeAll("\t},\n");
        _ = try writer.writeAll("\tentered_front: {\n");
        _ = try writer.print("\t\taxis1: {},\n", .{x.entered_front.axis1});
        _ = try writer.print("\t\taxis2: {},\n", .{x.entered_front.axis2});
        _ = try writer.print("\t\taxis3: {},\n", .{x.entered_front.axis3});
        _ = try writer.writeAll("\t},\n");
        _ = try writer.writeAll("\tentered_back: {\n");
        _ = try writer.print("\t\taxis1: {},\n", .{x.entered_back.axis1});
        _ = try writer.print("\t\taxis2: {},\n", .{x.entered_back.axis2});
        _ = try writer.print("\t\taxis3: {},\n", .{x.entered_back.axis3});
        _ = try writer.writeAll("\t},\n");
        _ = try writer.writeAll("\ttransmission_stopped: {\n");
        _ = try writer.print(
            "\t\tfrom_prev: {},\n",
            .{x.transmission_stopped.from_prev},
        );
        _ = try writer.print(
            "\t\tfrom_next: {},\n",
            .{x.transmission_stopped.from_next},
        );
        _ = try writer.writeAll("\t},\n");
        _ = try writer.print("\terrors_cleared: {},\n", .{x.errors_cleared});
        _ = try writer.writeAll("\tcommunication_error: {\n");
        _ = try writer.print(
            "\t\tfrom_prev: {},\n",
            .{x.communication_error.from_prev},
        );
        _ = try writer.print(
            "\t\tfrom_next: {},\n",
            .{x.communication_error.from_next},
        );
        _ = try writer.writeAll("\t},\n");
        _ = try writer.print(
            "\tinverter_overheat_detected: {},\n",
            .{x.inverter_overheat_detected},
        );
        _ = try writer.writeAll("\tovercurrent_detected: {\n");
        _ = try writer.print(
            "\t\taxis1: {},\n",
            .{x.overcurrent_detected.axis1},
        );
        _ = try writer.print(
            "\t\taxis2: {},\n",
            .{x.overcurrent_detected.axis2},
        );
        _ = try writer.print(
            "\t\taxis3: {},\n",
            .{x.overcurrent_detected.axis3},
        );
        _ = try writer.writeAll("\t},\n");
        _ = try writer.writeAll("\tcontrol_failure: {\n");
        _ = try writer.print("\t\taxis1: {},\n", .{x.control_failure.axis1});
        _ = try writer.print("\t\taxis2: {},\n", .{x.control_failure.axis2});
        _ = try writer.print("\t\taxis3: {},\n", .{x.control_failure.axis3});
        _ = try writer.writeAll("\t},\n");
        _ = try writer.writeAll("\thall_alarm: {\n");
        for (0..3) |_i| {
            const i: u2 = @intCast(_i);
            _ = try writer.print("\t\taxis{}: {{\n", .{i + 1});
            _ = try writer.print("\t\t\tback: {},\n", .{x.hallAlarm(i).back});
            _ = try writer.print(
                "\t\t\tfront: {},\n",
                .{x.hallAlarm(i).front},
            );
            _ = try writer.writeAll("\t\t},\n");
        }
        _ = try writer.writeAll("\t},\n");
        _ = try writer.writeAll("\tself_pause: {\n");
        _ = try writer.print("\t\taxis1: {},\n", .{x.self_pause.axis1});
        _ = try writer.print("\t\taxis2: {},\n", .{x.self_pause.axis2});
        _ = try writer.print("\t\taxis3: {},\n", .{x.self_pause.axis3});
        _ = try writer.writeAll("\t},\n");
        _ = try writer.writeAll("\tpulling_slider: {\n");
        _ = try writer.print("\t\taxis1: {},\n", .{x.pulling_slider.axis1});
        _ = try writer.print("\t\taxis2: {},\n", .{x.pulling_slider.axis2});
        _ = try writer.print("\t\taxis3: {},\n", .{x.pulling_slider.axis3});
        _ = try writer.writeAll("\t},\n");
        _ = try writer.writeAll("\thall_alarm_abnormal: {\n");
        for (0..3) |_i| {
            const i: u2 = @intCast(_i);
            _ = try writer.print("\t\taxis{}: {{\n", .{i + 1});
            _ = try writer.print(
                "\t\t\tback: {},\n",
                .{x.hallAlarmAbnormal(i).back},
            );
            _ = try writer.print(
                "\t\t\tfront: {},\n",
                .{x.hallAlarmAbnormal(i).front},
            );
            _ = try writer.writeAll("\t\t},\n");
        }
        _ = try writer.writeAll("\t},\n");
        try writer.writeAll("}\n");
        _ = try writer.writeAll("\tchain_enabled: {\n");
        for (0..3) |_i| {
            const i: u2 = @intCast(_i);
            _ = try writer.print("\t\taxis{}: {{\n", .{i + 1});
            _ = try writer.print(
                "\t\t\tback: {},\n",
                .{x.chainEnabled(i).backward},
            );
            _ = try writer.print(
                "\t\t\tfront: {},\n",
                .{x.chainEnabled(i).forward},
            );
            _ = try writer.writeAll("\t\t},\n");
        }
        _ = try writer.writeAll("\t},\n");
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
    } = .{},
    recovery_use_hall_sensor: packed struct(u2) {
        back: bool = false,
        front: bool = false,
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
    } = .{},
    _33: u31 = 0,

    pub fn resetPullSlider(self: Y, axis_index: u2) bool {
        switch (axis_index) {
            0 => self.reset_pull_slider.axis1,
            1 => self.reset_pull_slider.axis2,
            2 => self.reset_pull_slider.axis3,
            else => unreachable,
        }
    }

    pub fn setResetPullSlider(self: *Y, axis_index: u2, value: bool) void {
        switch (axis_index) {
            0 => {
                self.*.reset_pull_slider.axis1 = value;
            },
            1 => {
                self.*.reset_pull_slider.axis2 = value;
            },
            2 => {
                self.*.reset_pull_slider.axis3 = value;
            },
            3 => unreachable,
        }
    }

    pub fn linkChain(self: Y, axis_index: u2) struct {
        backward: bool,
        forward: bool,
    } {
        return switch (axis_index) {
            0 => .{
                .backward = self.link_chain.axis1.backward,
                .forward = self.link_chain.axis1.forward,
            },
            1 => .{
                .backward = self.link_chain.axis2.backward,
                .forward = self.link_chain.axis2.forward,
            },
            2 => .{
                .backward = self.link_chain.axis3.backward,
                .forward = self.link_chain.axis3.forward,
            },
            else => unreachable,
        };
    }

    pub fn setLinkChain(
        self: *Y,
        axis_index: u2,
        val: struct {
            forward: ?bool = null,
            backward: ?bool = null,
        },
    ) void {
        switch (axis_index) {
            inline 0...3 => |num| {
                if (val.forward) |f| {
                    (@field(
                        self.*.link_chain,
                        std.fmt.comptimePrint("axis{d}", .{num + 1}),
                    )).forward = f;
                }
                if (val.backward) |b| {
                    (@field(
                        self.*.link_chain,
                        std.fmt.comptimePrint("axis{d}", .{num + 1}),
                    )).backward = b;
                }
            },
            else => unreachable,
        }
    }

    pub fn unlinkChain(self: Y, axis_index: u2) struct {
        backward: bool,
        forward: bool,
    } {
        return switch (axis_index) {
            0 => .{
                .backward = self.unlink_chain.axis1.backward,
                .forward = self.unlink_chain.axis1.forward,
            },
            1 => .{
                .backward = self.unlink_chain.axis2.backward,
                .forward = self.unlink_chain.axis2.forward,
            },
            2 => .{
                .backward = self.unlink_chain.axis3.backward,
                .forward = self.unlink_chain.axis3.forward,
            },
            else => unreachable,
        };
    }

    pub fn setUnlinkChain(
        self: *Y,
        axis_index: u2,
        val: struct {
            forward: ?bool = null,
            backward: ?bool = null,
        },
    ) void {
        switch (axis_index) {
            inline 0...3 => |num| {
                if (val.forward) |f| {
                    (@field(
                        self.*.unlink_chain,
                        std.fmt.comptimePrint("axis{d}", .{num + 1}),
                    )).forward = f;
                }
                if (val.backward) |b| {
                    (@field(
                        self.*.unlink_chain,
                        std.fmt.comptimePrint("axis{d}", .{num + 1}),
                    )).backward = b;
                }
            },
            else => unreachable,
        }
    }

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
                .{y.linkChain(i).backward},
            );
            try writer.print(
                "\t\t\tforward: {},\n",
                .{y.linkChain(i).forward},
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
                .{y.unlinkChain(i).backward},
            );
            try writer.print(
                "\t\t\tforward: {},\n",
                .{y.unlinkChain(i).forward},
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
        axis1: i16 = 0,
        axis2: i16 = 0,
        axis3: i16 = 0,
    } = .{},
    slider_location: packed struct(u96) {
        axis1: Distance = .{},
        axis2: Distance = .{},
        axis3: Distance = .{},
    } = .{},
    slider_state: packed struct(u48) {
        axis1: SliderStateCode = .None,
        axis2: SliderStateCode = .None,
        axis3: SliderStateCode = .None,
    } = .{},
    pitch_count: packed struct(u48) {
        axis1: i16 = 0,
        axis2: i16 = 0,
        axis3: i16 = 0,
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

    pub fn sliderNumber(self: Wr, axis_index: u2) i16 {
        return switch (axis_index) {
            0 => self.slider_number.axis1,
            1 => self.slider_number.axis2,
            2 => self.slider_number.axis3,
            3 => unreachable,
        };
    }

    pub fn sliderLocation(self: Wr, axis_index: u2) Distance {
        return switch (axis_index) {
            0 => self.slider_location.axis1,
            1 => self.slider_location.axis2,
            2 => self.slider_location.axis3,
            3 => unreachable,
        };
    }

    pub fn sliderState(self: Wr, axis_index: u2) SliderStateCode {
        return switch (axis_index) {
            0 => self.slider_state.axis1,
            1 => self.slider_state.axis2,
            2 => self.slider_state.axis3,
            3 => unreachable,
        };
    }

    pub fn pitchCount(self: Wr, axis_index: u2) i16 {
        return switch (axis_index) {
            0 => self.pitch_count.axis1,
            1 => self.pitch_count.axis2,
            2 => self.pitch_count.axis3,
            3 => unreachable,
        };
    }

    pub fn format(
        wr: Wr,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.writeAll("Wr: {\n");
        _ = try writer.print(
            "\tcommand_response: {},\n",
            .{wr.command_response},
        );
        try writer.writeAll("\tslider_number: {\n");
        _ = try writer.print("\t\taxis1: {},\n", .{wr.slider_number.axis1});
        _ = try writer.print("\t\taxis2: {},\n", .{wr.slider_number.axis2});
        _ = try writer.print("\t\taxis3: {},\n", .{wr.slider_number.axis3});
        try writer.writeAll("\t},\n");
        try writer.writeAll("\tslider_location: {\n");
        _ = try writer.print("\t\taxis1: {},\n", .{wr.slider_location.axis1});
        _ = try writer.print("\t\taxis2: {},\n", .{wr.slider_location.axis2});
        _ = try writer.print("\t\taxis3: {},\n", .{wr.slider_location.axis3});
        try writer.writeAll("\t},\n");
        try writer.writeAll("\tslider_state: {\n");
        _ = try writer.print("\t\taxis1: {},\n", .{wr.slider_state.axis1});
        _ = try writer.print("\t\taxis2: {},\n", .{wr.slider_state.axis2});
        _ = try writer.print("\t\taxis3: {},\n", .{wr.slider_state.axis3});
        try writer.writeAll("\t},\n");
        try writer.writeAll("\tpitch_count: {\n");
        _ = try writer.print("\t\taxis1: {},\n", .{wr.pitch_count.axis1});
        _ = try writer.print("\t\taxis2: {},\n", .{wr.pitch_count.axis2});
        _ = try writer.print("\t\taxis3: {},\n", .{wr.pitch_count.axis3});
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
    command_slider_number: i16 = 0,
    target_axis_number: i16 = 0,
    location_distance: Distance = .{},
    speed_percentage: i16 = 0,
    acceleration_percentage: i16 = 0,
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
        _ = try writer.print("\tcommand_code: {},\n", .{ww.command_code});
        _ = try writer.print(
            "\tcommand_slider_number: {},\n",
            .{ww.command_slider_number},
        );
        _ = try writer.print(
            "\ttarget_axis_number: {},\n",
            .{ww.target_axis_number},
        );
        _ = try writer.print(
            "\tlocation_distance: {},\n",
            .{ww.location_distance},
        );
        _ = try writer.print(
            "\tspeed_percentage: {},\n",
            .{ww.speed_percentage},
        );
        _ = try writer.print(
            "\tacceleration_percentage: {},\n",
            .{ww.acceleration_percentage},
        );
        try writer.writeAll("}\n");
    }
};

test "Ww" {
    try std.testing.expectEqual(32, @sizeOf(Ww));
}
