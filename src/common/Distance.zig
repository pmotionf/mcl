//! Represents metric distance broken down into multiple precision components.
const Distance = @This();

pub const Zero: Distance = .{ .mm = 0, .um = 0 };
pub const Max: Distance = .{
    .mm = 32767,
    .um = 32767,
};
pub const Min: Distance = .{
    .mm = -32768,
    .um = -32768,
};

pub const um_per_mm: i16 = 1000;

/// Millimeter component of distance.
mm: i16 = 0, // TODO: Should use i32

/// Micrometer component of distance.
um: i16 = 0, // TODO: Should use i32

pub fn isZero(self: Distance) bool {
    return self.mm == 0 and self.um == 0;
}

fn correctSigns(self: Distance) Distance {
    var result = self;

    if (result.mm < 0 and result.um > 0) {
        result.um -= 1000;
        result.mm += 1;
    } else if (result.mm > 0 and result.um < 0) {
        result.um += 1000;
        result.mm -= 1;
    }

    return result;
}

pub fn less(a: Distance, b: Distance) bool {
    if (a.mm < b.mm) return true;
    if (a.mm == b.mm and a.um < b.um) return true;
    return false;
}

pub fn eql(a: Distance, b: Distance) bool {
    return a.mm == b.mm and a.um == b.um;
}

pub fn greater(a: Distance, b: Distance) bool {
    if (a.mm > b.mm) return true;
    if (a.mm == b.mm and a.um > b.um) return true;
    return false;
}

pub fn neg(self: Distance) Distance {
    return .{ .mm = -self.mm, .um = -self.um };
}

pub fn add(a: Distance, b: Distance) Distance {
    var um = a.um + b.um;
    var mm = a.mm + b.mm;
    mm += @divTrunc(um, 1000);
    um = @mod(um, 1000);

    return (Distance{ .mm = mm, .um = um }).correctSigns();
}

pub fn sub(a: Distance, b: Distance) Distance {
    var um = a.um - b.um;
    var mm = a.mm - b.mm;
    mm += @divTrunc(um, 1000);
    um = @mod(um, 1000);

    return (Distance{ .mm = mm, .um = um }).correctSigns();
}

pub fn abs(self: Distance) Distance {
    if (self.mm < 0) return self.neg().correctSigns();
    return self;
}

pub fn divIntTrunc(a: Distance, b: anytype) Distance {
    comptime {
        if (@typeInfo(@TypeOf(b)) != .Int) {
            @compileError("divIntTrunc must have an integer divisor");
        }
    }

    return .{ .mm = @divTrunc(a.mm, b), .um = @divTrunc(a.um, b) };
}
