const std = @import("std");
const registers = @import("../registers.zig");

const Direction = registers.Direction;

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
        to_prev: bool = false,
        to_next: bool = false,

        pub fn to(self: @This(), dir: Direction) bool {
            return switch (dir) {
                .backward => self.to_prev,
                .forward => self.to_next,
            };
        }
    } = .{},
    errors_cleared: bool = false,
    communication_error: packed struct(u2) {
        to_prev: bool = false,
        to_next: bool = false,

        pub fn to(self: @This(), dir: Direction) bool {
            return switch (dir) {
                .backward => self.to_prev,
                .forward => self.to_next,
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
            "\t\tto_prev: {},\n",
            .{x.transmission_stopped.to_prev},
        );
        try writer.print(
            "\t\tto_next: {},\n",
            .{x.transmission_stopped.to_next},
        );
        try writer.writeAll("\t},\n");
        try writer.print("\terrors_cleared: {},\n", .{x.errors_cleared});
        try writer.writeAll("\tcommunication_error: {\n");
        try writer.print(
            "\t\tto_prev: {},\n",
            .{x.communication_error.to_prev},
        );
        try writer.print(
            "\t\tto_next: {},\n",
            .{x.communication_error.to_next},
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
