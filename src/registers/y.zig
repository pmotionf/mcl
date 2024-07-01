const std = @import("std");
const registers = @import("../registers.zig");

const Direction = registers.Direction;

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
        to_prev: bool = false,
        to_next: bool = false,

        pub fn to(self: @This(), dir: Direction) bool {
            return switch (dir) {
                .backward => self.to_prev,
                .forward => self.to_next,
            };
        }

        pub fn setTo(
            self: *align(8:9:8) @This(),
            dir: Direction,
            val: bool,
        ) void {
            switch (dir) {
                .backward => self.to_prev = val,
                .forward => self.to_next = val,
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
            "\t\tto_prev: {},\n",
            .{y.stop_driver_transmission.to_prev},
        );
        try writer.print(
            "\t\tto_next: {},\n",
            .{y.stop_driver_transmission.to_next},
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
