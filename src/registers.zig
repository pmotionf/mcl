pub const X = @import("registers/x.zig").X;
pub const Y = @import("registers/y.zig").Y;
pub const Wr = @import("registers/wr.zig").Wr;
pub const Ww = @import("registers/ww.zig").Ww;

pub const Direction = enum(u1) {
    backward = 0,
    forward = 1,

    pub fn flip(self: @This()) @This() {
        return if (self == .backward) .forward else .backward;
    }
};
