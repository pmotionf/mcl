const std = @import("std");

const v = @import("version");
const mdfunc = @import("mdfunc");

pub const version: std.SemanticVersion =
    std.SemanticVersion.parse(v.mcl_version) catch unreachable;

pub const connection = @import("connection.zig");
