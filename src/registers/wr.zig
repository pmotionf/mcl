const std = @import("std");
const registers = @import("../registers.zig");

const Distance = registers.Distance;

/// Registers written through CC-Link's "DevWr" device. Used as a "read"
/// register bank.
pub const Wr = packed struct(u256) {
    command_response: CommandResponseCode = .NoError,
    slider: Slider = .{},

    pub const Slider = packed struct(u240) {
        id: packed struct(u48) {
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
        location: packed struct(u96) {
            axis1: f32 = 0.0,
            axis2: f32 = 0.0,
            axis3: f32 = 0.0,

            pub fn axis(self: @This(), a: u2) f32 {
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
        state: packed struct(u48) {
            axis1: State = .None,
            axis2: State = .None,
            axis3: State = .None,

            pub fn axis(self: @This(), a: u2) State {
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

        pub const State = enum(i16) {
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
    };

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
        try writer.writeAll("\tslider: {\n");
        try writer.writeAll("\t\tid: {\n");
        try writer.print("\t\t\taxis1: {},\n", .{wr.slider.id.axis1});
        try writer.print("\t\t\taxis2: {},\n", .{wr.slider.id.axis2});
        try writer.print("\t\t\taxis3: {},\n", .{wr.slider.id.axis3});
        try writer.writeAll("\t\t},\n");
        try writer.writeAll("\t\tlocation: {\n");
        try writer.print("\t\t\taxis1: {},\n", .{wr.slider.location.axis1});
        try writer.print("\t\t\taxis2: {},\n", .{wr.slider.location.axis2});
        try writer.print("\t\t\taxis3: {},\n", .{wr.slider.location.axis3});
        try writer.writeAll("\t\t},\n");
        try writer.writeAll("\t\tstate: {\n");
        try writer.print("\t\t\taxis1: {},\n", .{wr.slider.state.axis1});
        try writer.print("\t\t\taxis2: {},\n", .{wr.slider.state.axis2});
        try writer.print("\t\t\taxis3: {},\n", .{wr.slider.state.axis3});
        try writer.writeAll("\t\t},\n");
        try writer.writeAll("\t\tpitch_count: {\n");
        try writer.print("\t\t\taxis1: {},\n", .{wr.slider.pitch_count.axis1});
        try writer.print("\t\t\taxis2: {},\n", .{wr.slider.pitch_count.axis2});
        try writer.print("\t\t\taxis3: {},\n", .{wr.slider.pitch_count.axis3});
        try writer.writeAll("\t\t},\n");
        try writer.writeAll("\t},\n");
        try writer.writeAll("}\n");
    }
};

test "Wr" {
    try std.testing.expectEqual(32, @sizeOf(Wr));
}
