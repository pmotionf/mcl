//! This module implements a hardware motion system connection through the
//! CC-Link Ver.2 board.
const Self = @This();

const std = @import("std");
const mdfunc = @import("mdfunc");
const common = @import("../common.zig");

const Connection = @import("../Connection.zig");
const Distance = common.Distance;
const Registers = @import("Registers.zig");

parent: *Connection,

path: i32 = undefined,

pub fn init(parent: *Connection) !Self {
    const result: Self = .{
        .parent = parent,
    };
    return result;
}

pub fn deinit(self: *Self) void {
    self.path = undefined;
}

pub fn open(self: *Self) !void {
    self.path = try mdfunc.open(.cc_link_1slot);
}

pub fn close(self: *Self) !void {
    try mdfunc.close(self.path);
}

pub fn poll(self: *Self) !void {
    // Read X Registers
    const x_registers_size: i32 = @intCast(
        self.parent.drivers.len * Registers.X.byte_size,
    );
    const x_bytes_read: i32 = try mdfunc.receiveEx(
        self.path,
        0, // Network no. must be 0 in CC-Link V.2 boards
        0xFF, // 255 - Own station
        .DevX,
        0x0,
        std.mem.sliceAsBytes(self.parent._registers.x),
    );
    std.debug.assert(x_bytes_read == x_registers_size);

    // Read Y Registers
    const y_registers_size: i32 = @intCast(
        self.parent.drivers.len * Registers.Y.byte_size,
    );
    const y_bytes_read: i32 = try mdfunc.receiveEx(
        self.path,
        0,
        0xFF,
        .DevY,
        0x0,
        std.mem.sliceAsBytes(self.parent._registers.y),
    );
    std.debug.assert(y_bytes_read == y_registers_size);

    // Read Wr Registers
    const wr_registers_size: i32 = @intCast(
        self.parent.drivers.len * Registers.Wr.byte_size,
    );
    const wr_bytes_read: i32 = try mdfunc.receiveEx(
        self.path,
        0,
        0xFF,
        .DevWr,
        0x0,
        std.mem.sliceAsBytes(self.parent._registers.wr),
    );
    std.debug.assert(wr_bytes_read == wr_registers_size);

    // Read Ww Registers
    const ww_registers_size: i32 = @intCast(
        self.parent.drivers.len * Registers.Ww.byte_size,
    );
    const ww_bytes_read: i32 = try mdfunc.receiveEx(
        self.path,
        0,
        0xFF,
        .DevWw,
        0x0,
        std.mem.sliceAsBytes(self.parent._registers.ww),
    );
    std.debug.assert(ww_bytes_read == ww_registers_size);
}

pub fn driverLink(
    self: *Self,
    comptime set: bool,
    driver_id: Connection.Driver.Id,
) !void {
    var devno: i32 = @intCast(Registers.Y.bit_size);
    devno *= @intCast(driver_id - 1);
    if (set) {
        try mdfunc.devSetEx(self.path, 0, 0xFF, .DevY, devno);
    } else {
        try mdfunc.devRstEx(self.path, 0, 0xFF, .DevY, devno);
    }
}

pub fn commandStart(
    self: *Self,
    comptime set: bool,
    driver_id: Connection.Driver.Id,
) !void {
    std.debug.assert(driver_id > 0);
    var devno: i32 = @intCast(Registers.Y.bit_size);
    devno *= driver_id - 1;
    if (set) {
        try mdfunc.devSetEx(self.path, 0, 0xFF, .DevY, devno + 2);
    } else {
        try mdfunc.devRstEx(self.path, 0, 0xFF, .DevY, devno + 2);
    }
}

pub fn commandClearReceived(
    self: *Self,
    comptime set: bool,
    driver_id: Connection.Driver.Id,
) !void {
    std.debug.assert(driver_id > 0);
    var devno: i32 = @intCast(Registers.Y.bit_size);
    devno *= driver_id - 1;
    if (set) {
        try mdfunc.devSetEx(self.path, 0, 0xFF, .DevY, devno + 3);
    } else {
        try mdfunc.devRstEx(self.path, 0, 0xFF, .DevY, devno + 3);
    }
}

pub fn commandHome(
    self: *Self,
    driver_id: Connection.Driver.Id,
) !void {
    std.debug.assert(driver_id > 0);
    const new_ww: Registers.Ww = .{
        .command_code = @intFromEnum(Registers.Ww.CommandCode.Home),
    };
    try self.sendWw(driver_id, new_ww);
}

pub fn axisRecoverSlider(
    self: *Self,
    driver_id: Connection.Driver.Id,
    axis_id: Connection.Axis.IdDriver,
    new_slider_id: Connection.SliderId,
) !void {
    const new_ww: Registers.Ww = .{
        .command_code = @intFromEnum(
            Registers.Ww.CommandCode.PerSliderTemporaryRecovery,
        ),
        .command_slider_number = new_slider_id,
        .target_axis_number = @intFromEnum(axis_id),
    };
    try self.sendWw(driver_id, new_ww);
}

pub fn axisReleaseServo(
    self: *Self,
    comptime set: bool,
    driver_id: Connection.Driver.Id,
    axis_id_driver: Connection.Axis.IdDriver,
) !void {
    var devno: i32 = @intCast(Registers.Y.bit_size);
    devno *= driver_id - 1;
    if (set) {
        const new_ww: Registers.Ww = .{
            .target_axis_number = @intFromEnum(axis_id_driver),
        };
        try self.sendWw(driver_id, new_ww);
        try mdfunc.devSetEx(self.path, 0, 0xFF, .DevY, devno + 5);
    } else {
        try mdfunc.devRstEx(self.path, 0, 0xFF, .DevY, devno + 5);
    }
}

pub fn commandPosMoveAxis(
    self: *Self,
    driver_id: Connection.Driver.Id,
    slider_id: Connection.SliderId,
    target_axis_id: Connection.Axis.IdSystem,
    speed_percentage: i16,
    acceleration_percentage: i16,
) !void {
    const new_ww: Registers.Ww = .{
        .command_code = @intFromEnum(
            Registers.Ww.CommandCode.MoveSliderToAxisByPosition,
        ),
        .command_slider_number = slider_id,
        .target_axis_number = target_axis_id,
        .speed_percentage = speed_percentage,
        .acceleration_percentage = acceleration_percentage,
    };
    try self.sendWw(driver_id, new_ww);
}

pub fn commandPosMoveLocation(
    self: *Self,
    driver_id: Connection.Driver.Id,
    slider_id: Connection.SliderId,
    target_location: Distance,
    speed_percentage: i16,
    acceleration_percentage: i16,
) !void {
    const new_ww: Registers.Ww = .{
        .command_code = @intFromEnum(
            Registers.Ww.CommandCode.MoveSliderToLocationByPosition,
        ),
        .command_slider_number = slider_id,
        .location_distance_mm = target_location.mm,
        .location_distance_um = target_location.um,
        .speed_percentage = speed_percentage,
        .acceleration_percentage = acceleration_percentage,
    };
    try self.sendWw(driver_id, new_ww);
}
pub fn commandPosMoveDistance(
    self: *Self,
    driver_id: Connection.Driver.Id,
    slider_id: Connection.SliderId,
    distance: Distance,
    speed_percentage: i16,
    acceleration_percentage: i16,
) !void {
    const new_ww: Registers.Ww = .{
        .command_code = @intFromEnum(
            Registers.Ww.CommandCode.MoveSliderDistanceByPosition,
        ),
        .command_slider_number = slider_id,
        .location_distance_mm = distance.mm,
        .location_distance_um = distance.um,
        .speed_percentage = speed_percentage,
        .acceleration_percentage = acceleration_percentage,
    };
    try self.sendWw(driver_id, new_ww);
}

pub fn driverStopAuxTrafficFromNext(
    self: *Self,
    comptime set: bool,
    driver_id: Connection.Driver.Id,
) !void {
    var devno: i32 = @intCast(Registers.Y.bit_size);
    devno *= driver_id - 1;
    if (set) {
        try mdfunc.devSetEx(self.path, 0, 0xFF, .DevY, devno + 10);
    } else {
        try mdfunc.devRstEx(self.path, 0, 0xFF, .DevY, devno + 10);
    }
}

pub fn driverStopAuxTrafficFromPrev(
    self: *Self,
    comptime set: bool,
    driver_id: Connection.Driver.Id,
) !void {
    var devno: i32 = @intCast(Registers.Y.bit_size);
    devno *= driver_id - 1;
    if (set) {
        try mdfunc.devSetEx(self.path, 0, 0xFF, .DevY, devno + 9);
    } else {
        try mdfunc.devRstEx(self.path, 0, 0xFF, .DevY, devno + 9);
    }
}

fn sendWw(
    self: *Self,
    driver_id: Connection.Driver.Id,
    ww: Registers.Ww,
) !void {
    var devno: i32 = @intCast(Registers.Ww.short_size);
    devno *= driver_id - 1;
    const bytes_sent: i32 = try mdfunc.sendEx(
        self.path,
        0,
        0xFF,
        .DevWw,
        devno,
        std.mem.asBytes(&ww),
    );
    std.debug.assert(bytes_sent == Registers.Ww.byte_size);
}
