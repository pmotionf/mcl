pub const X = @import("registers/x.zig").X;
pub const Y = @import("registers/y.zig").Y;
pub const Wr = @import("registers/wr.zig").Wr;
pub const Ww = @import("registers/ww.zig").Ww;

pub const Distance = packed struct(u32) {
    mm: i16 = 0,
    um: i16 = 0,
};

pub const Direction = enum(u1) {
    backward = 0,
    forward = 1,
};
