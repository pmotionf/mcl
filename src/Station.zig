//! CC-Link Station. One occupied Ver.2 Remote Device station, 4x Expanded
//! Cyclic.
const std = @import("std");

x: X = .{},
y: Y = .{},
ww: Ww = .{},
wr: Wr = .{},

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
    axes_interconnect_enabled: bool = false,
    command_received: bool = false,
    axis_enabled: packed struct(u3) {
        axis1: bool = false,
        axis2: bool = false,
        axis3: bool = false,
    } = .{},
    location_ready: packed struct(u3) {
        axis1: bool = false,
        axis2: bool = false,
        axis3: bool = false,
    } = .{},
    detected_forward: packed struct(u3) {
        axis1: bool = false,
        axis2: bool = false,
        axis3: bool = false,
    } = .{},
    detected_backward: packed struct(u3) {
        axis1: bool = false,
        axis2: bool = false,
        axis3: bool = false,
    } = .{},
    transmission_stopped: packed struct(u2) {
        from_prev: bool = false,
        from_next: bool = false,
    } = .{},
    errors_cleared: bool = false,
    axis1_communication_error: bool = false,
    axis3_communication_error: bool = false,
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
    hall_sensor: packed struct(u6) {
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
    _54: u10 = 0,
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
    per_axis_servo_release: bool = false,
    servo_release: bool = false,
    _7: u1 = 0,
    temporary_pause: bool = false,
    stop_driver_transmission: packed struct(u2) {
        from_prev: bool = false,
        from_next: bool = false,
    } = .{},
    clear_errors: bool = false,
    clear_axis_slider_info: bool = false,
    prev_axis_link: bool = false, // During slider speed movement, move with speed linked to prev axis.
    next_axis_link: bool = false, // During slider speed movement, move with speed linked to next axis.
    _15: u1 = 0,
    reset_pull_slider: packed struct(u3) {
        axis1: bool = false,
        axis2: bool = false,
        axis3: bool = false,
    } = .{},
    _19: u45 = 0,
};

test "Y" {
    try std.testing.expectEqual(8, @sizeOf(Y));
}

/// Registers written through CC-Link's "DevWw" device. Used as a "write"
/// register bank.
pub const Ww = packed struct(u256) {
    command_code: i16 = 0,
    command_slider_number: i16 = 0,
    target_axis_number: i16 = 0,
    location_distance: packed struct(u32) {
        mm: i16 = 0,
        um: i16 = 0,
    } = .{},
    speed_percentage: i16 = 0,
    acceleration_percentage: i16 = 0,
    _112: u144 = 0,

    pub const CommandCode = enum(i16) {
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
        ForwardDirectionSeparation = 24,
        BackwardDirectionSeparation = 25,
        Calibration = 26,
        RecoverSystemSliders = 27,
        RecoverSliderAtAxis = 28,
        PushAxisSliderForward = 30,
        PushAxisSliderBackward = 31,
        PullAxisSliderForward = 32,
        PullAxisSliderBackward = 33,
    };
};

test "Ww" {
    try std.testing.expectEqual(32, @sizeOf(Ww));
}

/// Registers written through CC-Link's "DevWr" device. Used as a "read"
/// register bank.
pub const Wr = packed struct(u256) {
    command_response_code: i16 = 0,
    slider_number: packed struct(u48) {
        axis1: i16 = 0,
        axis2: i16 = 0,
        axis3: i16 = 0,
    } = .{},
    slider_location: packed struct(u96) {
        axis1: packed struct(u32) {
            mm: i16 = 0,
            um: i16 = 0,
        } = .{},
        axis2: packed struct(u32) {
            mm: i16 = 0,
            um: i16 = 0,
        } = .{},
        axis3: packed struct(u32) {
            mm: i16 = 0,
            um: i16 = 0,
        } = .{},
    } = .{},
    slider_state: packed struct(u48) {
        axis1: i16 = 0,
        axis2: i16 = 0,
        axis3: i16 = 0,
    } = .{},
    pitch_count: packed struct(u48) {
        axis1: i16 = 0,
        axis2: i16 = 0,
        axis3: i16 = 0,
    } = .{},

    pub const CommandResponseCode = enum(i16) {
        NoError = 0,
        InvalidCommand = 1,
        SliderIdNotFound = 2,
        HomingFailed = 3,
        InvalidParameter = 4,
        InvalidSystemState = 5,
        SliderAlreadyExists = 6,
        InvalidAxisNumber = 7,
    };

    pub const SliderStateCode = enum(i16) {
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
    try std.testing.expectEqual(32, @sizeOf(Wr));
}
