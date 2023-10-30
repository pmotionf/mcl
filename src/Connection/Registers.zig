//! CC-Link registers

// Station Type: Ver.2 Remote Device Station
// baud rate: 156kbps
// Expanded Cyclic: 4x
// Occupied Station: 1

const std = @import("std");

x: X = .{},
y: Y = .{},
ww: Ww = .{},
wr: Wr = .{},

/// Registers written through CC-Link's "DevX" device. Used as a "read"
/// register bank.
pub const X = packed struct {
    /// X registers' total size in bits.
    pub const bit_size: usize = 64;

    /// X registers' total size in bytes.
    pub const byte_size: usize = 8;

    /// X registers' total size in shorts.
    pub const short_size: usize = 4;

    cc_link_enabled: bool = false,
    service_enabled: bool = false,
    ready_for_command: bool = false,
    axis1_servo_active: bool = false, // Related to Y registers 05, 06.
    axis2_servo_active: bool = false,
    axis3_servo_active: bool = false,
    servo_enabled: bool = false,
    emergency_stop_enabled: bool = false,
    paused: bool = false,
    axes_interconnect_enabled: bool = false,
    command_received: bool = false,
    axis1_enabled: bool = false,
    axis2_enabled: bool = false,
    axis3_enabled: bool = false,
    axis1_location_ready: bool = false,
    axis2_location_ready: bool = false,
    axis3_location_ready: bool = false,
    axis1_detected_forward: bool = false,
    axis2_detected_forward: bool = false,
    axis3_detected_forward: bool = false,
    axis1_detected_backward: bool = false,
    axis2_detected_backward: bool = false,
    axis3_detected_backward: bool = false,
    prev_driver_transmission_stopped: bool = false,
    next_driver_transmission_stopped: bool = false,
    errors_cleared: bool = false,
    axis1_communication_error: bool = false,
    axis3_communication_error: bool = false,
    inverter_overheat_detected: bool = false,
    axis1_overcurrent_detected: bool = false,
    axis2_overcurrent_detected: bool = false,
    axis3_overcurrent_detected: bool = false,
    axis1_control_failure: bool = false,
    axis2_control_failure: bool = false,
    axis3_control_failure: bool = false,
    axis1_backward_hall_sensor_detected: bool = false,
    axis1_forward_hall_sensor_detected: bool = false,
    axis2_backward_hall_sensor_detected: bool = false,
    axis2_forward_hall_sensor_detected: bool = false,
    axis3_backward_hall_sensor_detected: bool = false,
    axis3_forward_hall_sensor_detected: bool = false,
    axis1_self_pause: bool = false,
    axis2_self_pause: bool = false,
    axis3_self_pause: bool = false,
    _padding1: u8 = 0,
    _padding2: u4 = 0,
    _padding3: u1 = 0,
    _padding4: u1 = 0,
    _padding5: u1 = 0,
    _padding6: u1 = 0,
    _padding7: u1 = 0,
    _padding8: u1 = 0,
    _padding9: u1 = 0,
};

test "X" {
    try std.testing.expectEqual(X.byte_size, @sizeOf(X));
}

/// Registers written through CC-Link's "DevY" device. Used as a "write"
/// register bank.
pub const Y = packed struct {
    /// Y registers' total size in bits.
    pub const bit_size: usize = 64;

    /// Y registers' total size in bytes.
    pub const byte_size: usize = 8;

    /// Y registers' total size in shorts.
    pub const short_size: usize = 4;

    cc_link_enable: bool = false,
    service_enable: bool = false,
    start_command: bool = false,
    reset_command_received: bool = false,
    cancel_all_slider_commands: bool = false,
    per_axis_servo_release: bool = false,
    servo_release: bool = false,
    emergency_stop: bool = false,
    temporary_pause: bool = false,
    stop_prev_to_current_driver_transmission: bool = false,
    stop_next_to_current_driver_transmission: bool = false,
    clear_errors: bool = false,
    axis_and_slider_information_reorganize: bool = false,
    _empty1: bool = false,
    _empty2: bool = false,
    forward_speed_movement: bool = false, // Speed set in WW02. Stopped when 0.
    backward_speed_movement: bool = false, // Speed set in WW02. Stopped when 0.
    prev_axis_link: bool = false, // During slider speed movement, move with speed linked to prev axis.
    next_axis_link: bool = false, // During slider speed movement, move with speed linked to next axis.
    _padding1: u32 = 0,
    _padding2: u8 = 0,
    _padding3: u1 = 0,
    _padding4: u1 = 0,
    _padding5: u1 = 0,
    _padding6: u1 = 0,
    _padding7: u1 = 0,
};

test "Y" {
    try std.testing.expectEqual(Y.byte_size, @sizeOf(Y));
}

/// Registers written through CC-Link's "DevWw" device. Used as a "write"
/// register bank.
pub const Ww = packed struct {
    /// Ww registers' total size in bits.
    pub const bit_size: usize = 256;

    /// Ww registers' total size in bytes.
    pub const byte_size: usize = 32;

    /// Ww registers' total size in shorts.
    pub const short_size: usize = 16;

    command_code: i16 = 0,
    command_slider_number: i16 = 0,
    target_axis_number: i16 = 0,
    location_distance_mm: i16 = 0,
    location_distance_um: i16 = 0,
    speed_percentage: i16 = 0,
    acceleration_percentage: i16 = 0,
    _padding1: u64 = 0,
    _padding2: u64 = 0,
    _padding3: u16 = 0,

    pub const CommandCode = enum(i16) {
        Home = 17,
        // "By Position" commands calculate slider movement by constant hall
        // sensor position feedback, and is much more precise in destination
        // but struggles to maintain a constant speed while traveling due to
        // motor cogging.
        MoveSliderToAxisByPosition = 18,
        MoveSliderToLocationByPosition = 19,
        MoveSliderDistanceByPosition = 20,
        // "By Speed" commands calculate slider movement by constant hall
        // sensor speed feedback. It should mostly not be used, as the
        // destination position becomes far too imprecise. However, it is
        // meant to maintain a certain speed while the slider is traveling.
        MoveSliderToAxisBySpeed = 21,
        MoveSliderToLocationBySpeed = 22,
        MoveSliderDistanceBySpeed = 23,
        ForwardDirectionSeparation = 24,
        BackwardDirectionSeparation = 25,
        Calibration = 26,
        Recovery = 27,
        PerSliderTemporaryRecovery = 28,
    };
};

test "Ww" {
    try std.testing.expectEqual(Ww.byte_size, @sizeOf(Ww));
}

/// Registers written through CC-Link's "DevWr" device. Used as a "read"
/// register bank.
pub const Wr = packed struct {
    /// Wr registers' total size in bits.
    pub const bit_size: usize = 256;

    /// Wr registers' total size in bytes.
    pub const byte_size: usize = 32;

    /// Wr registers' total size in shorts.
    pub const short_size: usize = 16;

    command_response_code: i16 = 0,
    axis1_slider_number: i16 = 0, // 0 means no slider
    axis2_slider_number: i16 = 0, // 0 means no slider
    axis3_slider_number: i16 = 0,
    axis1_slider_location_mm: i16 = 0,
    axis1_slider_location_um: i16 = 0,
    axis2_slider_location_mm: i16 = 0,
    axis2_slider_location_um: i16 = 0,
    axis3_slider_location_mm: i16 = 0,
    axis3_slider_location_um: i16 = 0,
    axis1_slider_FSM: i16 = 0, // 0 means no slider
    axis2_slider_FSM: i16 = 0,
    axis3_slider_FSM: i16 = 0,
    axis1_pitch_count: i16 = 0,
    axis2_pitch_count: i16 = 0,
    axis3_pitch_count: i16 = 0,

    pub const CommandResponseCode = enum(i16) {
        NoError = 0,
        InvalidCommand = 1,
        SliderIdNotFound = 2,
        HomingFailed = 3,
        InvalidParameterOrState = 4,
    };

    pub const FsmCode = enum(i16) {
        PosMoveProgressing = 29,
        PosMoveCompleted = 30,
        PosMoveFault = 31,
        CalibrationProgressing = 32,
        CalibrationCompleted = 33,
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
        Overcurrent = 50,
        CommunicationError = 51,
    };
};

test "Wr" {
    try std.testing.expectEqual(Wr.byte_size, @sizeOf(Wr));
}
