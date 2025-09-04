const std = @import("std");
const registers = @import("../registers.zig");

/// Registers written through CC-Link's "DevWr" device. Used as a "read"
/// register bank.
pub const Wr = packed struct(u256) {
    command_response: CommandResponseCode = .none,
    _16: u48 = 0,
    carrier: packed struct(u192) {
        axis1: Carrier = .{},
        axis2: Carrier = .{},
        axis3: Carrier = .{},

        pub fn axis(self: @This(), a: u2) Carrier {
            return switch (a) {
                0 => self.axis1,
                1 => self.axis2,
                2 => self.axis3,
                3 => {
                    std.log.err(
                        "Invalid axis index 3 for `carrier`",
                        .{},
                    );
                    unreachable;
                },
            };
        }
    } = .{},

    pub const Carrier = packed struct(u64) {
        location: f32 = 0.0,
        id: u10 = 0,
        _42: u6 = 0,
        arrived: bool = false,
        auxiliary: bool = false,
        enabled: bool = false,
        /// Whether carrier is currently in quasi-enabled state. Quasi-enabled
        /// state occurs when carrier is first entering a module, before it
        /// has entered module enough to start servo control.
        quasi: bool = false,
        cas: packed struct {
            /// Whether carrier's CAS (collision avoidance system) is enabled.
            enabled: bool = false,
            /// Whether carrier's CAS (collision avoidance system) is triggered.
            triggered: bool = false,
        } = .{},
        _54: u2 = 0,
        state: State = .None,

        pub const State = enum(u8) {
            None = 0x0,

            WarmupProgressing,
            WarmupCompleted,

            PosMoveProgressing = 0x4,
            PosMoveCompleted,
            SpdMoveProgressing,
            SpdMoveCompleted,
            Auxiliary,
            AuxiliaryCompleted,

            ForwardCalibrationProgressing = 0xA,
            ForwardCalibrationCompleted,
            BackwardCalibrationProgressing,
            BackwardCalibrationCompleted,

            ForwardIsolationProgressing = 0x10,
            ForwardIsolationCompleted,
            BackwardIsolationProgressing,
            BackwardIsolationCompleted,
            ForwardRestartProgressing,
            ForwardRestartCompleted,
            BackwardRestartProgressing,
            BackwardRestartCompleted,

            PullForward = 0x19,
            PullForwardCompleted,
            PullBackward,
            PullBackwardCompleted,
            Push,
            PushCompleted,

            Overcurrent = 0x1F,
        };
    };

    pub const CommandResponseCode = enum(u16) {
        none = 0,
        success = 1,
        unknown_cmd = 2,
        carrier_not_found = 3,
        invalid_parameters = 4,
        invalid_system_state = 5,
        carrier_already_exists = 6,
        invalid_axis = 7,

        pub fn throwError(code: CommandResponseCode) !void {
            return switch (code) {
                .none, .success => {},
                .unknown_cmd => return error.InvalidCommand,
                .carrier_not_found => return error.CarrierNotFound,
                .invalid_parameters => return error.InvalidParameters,
                .invalid_system_state => return error.InvalidSystemState,
                .carrier_already_exists => return error.CarrierAlreadyExists,
                .invalid_axis => return error.InvalidAxis,
            };
        }
    };

    pub fn format(wr: Wr, writer: anytype) !void {
        _ = try registers.nestedWrite("Wr", wr, 0, writer);
    }
};

test "Wr" {
    try std.testing.expectEqual(32, @sizeOf(Wr));
}
