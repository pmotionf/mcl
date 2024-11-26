const std = @import("std");
const registers = @import("../registers.zig");

/// Registers written through CC-Link's "DevWw" device. Used as a "write"
/// register bank.
pub const Ww = packed struct(u256) {
    command_code: CommandCode = .None,
    command_slider_number: u16 = 0,
    location_distance: f32 = 0.0,
    target_axis_number: u16 = 0,
    speed_percentage: u16 = 0,
    acceleration_percentage: u16 = 0,
    _112: u144 = 0,

    pub const CommandCode = enum(i16) {
        None = 0x0,
        SetLineZero = 0x1,
        Warmup = 0x2,
        // "By Position" commands calculate slider movement by constant hall
        // sensor position feedback, and is much more precise in destination.
        MoveSliderToAxisByPosition = 0x12,
        MoveSliderToLocationByPosition = 0x13,
        MoveSliderDistanceByPosition = 0x14,
        // "By Speed" commands calculate slider movement by constant hall
        // sensor speed feedback. It should mostly not be used, as the
        // destination position becomes far too imprecise. However, it is
        // meant to maintain a certain speed while the slider is traveling, and
        // to avoid the requirement of having a known system position.
        MoveSliderToAxisBySpeed = 0x15,
        MoveSliderToLocationBySpeed = 0x16,
        MoveSliderDistanceBySpeed = 0x17,
        IsolateForward = 0x18,
        IsolateBackward = 0x19,
        Calibration = 0x1A,
        RecoverSystemSliders = 0x1B,
        RecoverSliderAtAxis = 0x1C,
        SetSliderIdAtAxis = 0x1D,
        PushAxisSliderForward = 0x1E,
        PushAxisSliderBackward = 0x1F,
        PullAxisSliderForward = 0x20,
        PullAxisSliderBackward = 0x21,
    };

    pub fn format(
        ww: Ww,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = try registers.nestedWrite("Ww", ww, 0, writer);
    }
};

test "Ww" {
    try std.testing.expectEqual(32, @sizeOf(Ww));
}
