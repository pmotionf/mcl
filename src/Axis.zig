//! This module provides convenient indexing of system axes, both in terms of
//! line-level indexing and local station-level indexing.
const Axis = @This();

const std = @import("std");

const MclStation = @import("Station.zig");

station: *const MclStation,
index: Index,
id: Id,

pub const Index = struct {
    station: Station,
    line: Line,

    /// Local axis index within station.
    pub const Station = std.math.IntFittingRange(0, 2);
    /// Axis index within line.
    pub const Line = std.math.IntFittingRange(0, 64 * 4 * 3 - 1);
};

pub const Id = struct {
    station: Station,
    line: Line,

    /// Local axis ID within station.
    pub const Station = std.math.IntFittingRange(1, 3);
    /// Axis ID within line.
    pub const Line = std.math.IntFittingRange(1, 64 * 4 * 3);
};

/// Whether current axis is auxiliary to provided axis. In the case of line
/// transition, the pushing axis always has priority to be the main axis due
/// to a potential invalid slider location on the pulling axis.
pub fn isAuxiliaryTo(self: Axis, other: Axis) bool {
    // Axes do not have to be in same line, as one axis can be "auxiliary" to
    // another during line transition.
    const self_slider = self.station.wr.slider.axis(self.index.station);
    const other_slider = other.station.wr.slider.axis(other.index.station);

    if (self_slider.id != other_slider.id) return false;
    if (self_slider.auxiliary) {
        return true;
    } else if (other_slider.auxiliary) {
        return false;
    }

    if (!self_slider.enabled and other_slider.enabled) {
        return true;
    } else if (self_slider.enabled and !other_slider.enabled) {
        return false;
    }

    if (self_slider.state == .None and other_slider.state != .None) {
        return true;
    } else if (self_slider.state != .None and other_slider.state == .None) {
        return false;
    }

    if (self_slider.state == .NextAxisAuxiliary or
        self_slider.state == .PrevAxisAuxiliary or
        self_slider.state == .PullBackward or
        self_slider.state == .PullForward)
    {
        return true;
    }

    return false;
}
