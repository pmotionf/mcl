pub const X = @import("registers/x.zig").X;
pub const Y = @import("registers/y.zig").Y;
pub const Wr = @import("registers/wr.zig").Wr;
pub const Ww = @import("registers/ww.zig").Ww;

pub const Distance = packed struct(u32) {
    mm: i16 = 0,
    um: i16 = 0,

    pub fn toFloat(self: @This()) f32 {
        return @as(f32, @floatFromInt(self.mm)) * 0.001 +
            @as(f32, @floatFromInt(self.um)) * 0.000001;
    }

    pub fn fromFloat(f: f32) @This() {
        const mult: f32 = f * 1000.0;
        const mm: f32 = @trunc(mult);
        return .{
            .mm = @intFromFloat(mm),
            .um = @intFromFloat((mult - mm) * 1000.0),
        };
    }
};

pub const Direction = enum(u1) {
    backward = 0,
    forward = 1,

    pub fn flip(self: @This()) @This() {
        return if (self == .backward) .forward else .backward;
    }
};
