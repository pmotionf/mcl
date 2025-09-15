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
        initialized: bool = false,
        _55: u1 = 0,
        state: State = .None,

        pub const State = enum(u8) {
            None = 0x0,

            WarmupProgressing,
            WarmupCompleted,

            Move = 0x4,
            Auxiliary,

            ForwardCalibrationProgressing = 0xA,
            ForwardCalibrationCompleted,
            BackwardCalibrationProgressing,
            BackwardCalibrationCompleted,

            ForwardIsolationProgressing = 0x10,
            ForwardIsolationCompleted,
            BackwardIsolationProgressing,
            BackwardIsolationCompleted,

            PullForward = 0x19,
            PullBackward,
            Push,
            PushCompleted,

            Overcurrent = 0x1F,

            _,
        };
    };

    pub const CommandResponseCode = enum(u16) {
        none = 0,
        success = 1,
        invalid_cmd,
        invalid_axis_id,
        invalid_carrier_id,
        invalid_carrier_target,
        invalid_carrier_control,
        invalid_carrier_vel,
        invalid_carrier_acc,
        carrier_not_found,
        carrier_already_exists,
        invalid_parameters,
        invalid_system_state,
        _,

        pub fn throwError(code: CommandResponseCode) !void {
            return switch (code) {
                .none, .success => {},
                .invalid_cmd => return error.InvalidCommand,
                .invalid_axis_id => return error.InvalidAxis,
                .invalid_carrier_id => return error.InvalidCarrierId,
                .invalid_carrier_target => return error.InvalidCarrierTarget,
                .invalid_carrier_control => return error.InvalidCarrierControl,
                .invalid_carrier_vel => return error.InvalidCarrierVelocity,
                .invalid_carrier_acc => return error.InvalidCarrierAcceleration,
                .carrier_not_found => return error.CarrierNotFound,
                .carrier_already_exists => return error.CarrierAlreadyExists,
                .invalid_parameters => return error.InvalidParameters,
                .invalid_system_state => return error.InvalidSystemState,
                _ => return error.Unexpected,
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
