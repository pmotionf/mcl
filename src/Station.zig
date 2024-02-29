//! CC-Link Station. One occupied Ver.2 Remote Device station, 4x Expanded
//! Cyclic.
const std = @import("std");

pub const Distance = packed struct(u32) {
    mm: i16 = 0,
    um: i16 = 0,
};

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

    pub fn locationReady(self: X, axis_index: u2) bool {
        return switch (axis_index) {
            0 => self.location_ready.axis1,
            1 => self.location_ready.axis2,
            2 => self.location_ready.axis3,
            3 => unreachable,
        };
    }

    pub fn detectedForward(self: X, axis_index: u2) bool {
        return switch (axis_index) {
            0 => self.detected_forward.axis1,
            1 => self.detected_forward.axis2,
            2 => self.detected_forward.axis3,
            3 => unreachable,
        };
    }

    pub fn detectedBackward(self: X, axis_index: u2) bool {
        return switch (axis_index) {
            0 => self.detected_backward.axis1,
            1 => self.detected_backward.axis2,
            2 => self.detected_backward.axis3,
            3 => unreachable,
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

    pub fn hallSensor(self: X, axis_index: u2) struct {
        back: bool,
        front: bool,
    } {
        return switch (axis_index) {
            0 => .{
                .back = self.hall_sensor.axis1.back,
                .front = self.hall_sensor.axis1.front,
            },
            1 => .{
                .back = self.hall_sensor.axis2.back,
                .front = self.hall_sensor.axis2.front,
            },
            2 => .{
                .back = self.hall_sensor.axis3.back,
                .front = self.hall_sensor.axis3.front,
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

    pub fn resetPullSlider(self: *Y, axis_index: u2, value: bool) void {
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
        SliderIdNotFound = 2,
        HomingFailed = 3,
        InvalidParameter = 4,
        InvalidSystemState = 5,
        SliderAlreadyExists = 6,
        InvalidAxisNumber = 7,
    };

    pub const SliderStateCode = enum(i16) {
        None = 0,
        PosMoveProgressing = 29,
        PosMoveCompleted = 30,
        PosMoveFault = 31,
        ForwardCalibrationProgressing = 32,
        ForwardCalibrationCompleted = 33,
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
        PullForward = 52,
        PullForwardCompleted = 53,
        PullForwardFault = 54,
        PullBackward = 55,
        PullBackwardCompleted = 56,
        PullBackwardFault = 57,
        BackwardCalibrationProgressing = 58,
        BackwardCalibrationCompleted = 59,
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
