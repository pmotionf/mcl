const std = @import("std");
const registers = @import("../registers.zig");

/// Registers written through CC-Link's "DevWr" device. Used as a "read"
/// register bank.
pub const Wr = packed struct(u256) {
    command_response: CommandResponseCode = .NoError,
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
    slider: packed struct(u192) {
        axis1: Slider = .{},
        axis2: Slider = .{},
        axis3: Slider = .{},

        pub fn axis(self: @This(), a: u2) Slider {
            return switch (a) {
                0 => self.axis1,
                1 => self.axis2,
                2 => self.axis3,
                3 => {
                    std.log.err(
                        "Invalid axis index 3 for `slider`",
                        .{},
                    );
                    unreachable;
                },
            };
        }
    } = .{},

    pub const Slider = packed struct(u64) {
        location: f32 = 0.0,
        id: u16 = 0,
        auxiliary: bool = false,
        enabled: bool = false,
        /// Whether slider is currently in quasi-enabled state. Quasi-enabled
        /// state occurs when slider is first entering a module, before it has
        /// entered module enough to start servo control.
        quasi: bool = false,
        /// Whether slider is currently in zombie state. Zombie state occurs
        /// when slider is leaving a module, after it has left the module
        /// enough that servo control is no longer possible.
        zombie: bool = false,
        _52: u4 = 0,
        state: State = .None,

        pub const State = enum(u8) {
            None = 0,
            WarmupProgressing = 1,
            WarmupCompleted = 2,
            WarmupFault = 3,
            CurrentBiasProgressing = 4,
            CurrentBiasCompleted = 5,
            PosMoveProgressing = 29,
            PosMoveCompleted = 30,
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
        _ = try registers.nestedWrite("Wr", wr, 0, writer);
    }
};

test "Wr" {
    try std.testing.expectEqual(32, @sizeOf(Wr));
}
