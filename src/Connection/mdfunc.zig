const std = @import("std");
const builtin = @import("builtin");

const mdfunc_c = @cImport(
    @cInclude("Mdfunc.h"),
);

pub const Short = i16;
pub const Long = i32;

pub fn mdOpen(chan: Channel, mode: Short) !Long {
    var path: Long = undefined;
    const res = mdfunc_c.mdOpen(@intFromEnum(chan), mode, &path);
    if (res != 0) try codeToError(res);
    return path;
}

pub fn mdClose(path: Long) !void {
    const res = mdfunc_c.mdClose(path);
    if (res != 0) try codeToError(res);
}

pub fn mdSend(
    path: Long,
    stno: Short,
    devtyp: Short,
    devno: Short,
    size: *Short,
    comptime T: type,
    data: []const T,
) !void {
    const res = mdfunc_c.mdSend(
        path,
        stno,
        devtyp,
        devno,
        size,
        @constCast(data.ptr),
    );
    if (res != 0) try codeToError(res);
}

pub fn mdReceive(
    path: Long,
    stno: Short,
    devtyp: Device,
    devno: Short,
    size: *Short,
    comptime T: type,
    data: []T,
) !void {
    var local_size: Short = size;
    const res = mdfunc_c.mdReceive(
        path,
        stno,
        @intFromEnum(devtyp),
        devno,
        &local_size,
        data.ptr,
    );
    if (res != 0) try codeToError(res);
}

pub fn mdDevSet(
    path: Long,
    stno: Short,
    devtyp: Device,
    devno: Short,
) !void {
    const res = mdfunc_c.mdDevSet(path, stno, @intFromEnum(devtyp), devno);
    if (res != 0) try codeToError(res);
}

pub fn mdDevRst(
    path: Long,
    stno: Short,
    devtyp: Device,
    devno: Short,
) !void {
    const res = mdfunc_c.mdDevRst(path, stno, @intFromEnum(devtyp), devno);
    if (res != 0) try codeToError(res);
}

pub fn mdRandW(
    path: Long,
    stno: Short,
    comptime X: type,
    dev: []X,
    comptime Y: type,
    buf: []Y,
    bufsize: Short,
) !void {
    const res = mdfunc_c.mdRandW(path, stno, dev, buf, bufsize);
    if (res != 0) try codeToError(res);
}

pub fn mdRandR(
    path: Long,
    stno: Short,
    comptime X: type,
    dev: []X,
    comptime Y: type,
    buf: []Y,
    bufsize: Short,
) !void {
    const res = mdfunc_c.mdRandR(path, stno, dev, buf, bufsize);
    if (res != 0) try codeToError(res);
}

pub fn mdControl(
    path: Long,
    stno: Short,
    buf: Short,
) !void {
    const res = mdfunc_c.mdControl(path, stno, buf);
    if (res != 0) try codeToError(res);
}

pub fn mdTypeRead(
    path: Long,
    stno: Short,
    buf: *Short,
) !void {
    const res = mdfunc_c.mdTypeRead(path, stno, buf);
    if (res != 0) try codeToError(res);
}

pub fn mdBdLedRead(
    path: Long,
    comptime T: type,
    buf: []T,
) !void {
    const res = mdfunc_c.mdBdLedRead(path, buf.ptr);
    if (res != 0) try codeToError(res);
}

pub fn mdBdModRead(
    path: Long,
    mode: *Short,
) !void {
    const res = mdfunc_c.mdBdModRead(path, mode);
    if (res != 0) try codeToError(res);
}

pub fn mdBdModSet(
    path: Long,
    mode: Short,
) !void {
    const res = mdfunc_c.mdBdModSet(path, mode);
    if (res != 0) try codeToError(res);
}

pub fn mdBdRst(path: Long) !void {
    const res = mdfunc_c.mdBdRst(path);
    if (res != 0) try codeToError(res);
}

pub fn mdBdSwRead(path: Long, buf: []Short) !void {
    const res = mdfunc_c.mdBdSwRead(path, buf.ptr);
    if (res != 0) try codeToError(res);
}

pub fn mdBdVerRead(path: Long, buf: []Short) !void {
    const res = mdfunc_c.mdBdVerRead(path, buf.ptr);
    if (res != 0) try codeToError(res);
}

pub fn mdInit(path: Long) !void {
    const res = mdfunc_c.mdInit(path);
    if (res != 0) try codeToError(res);
}

pub fn mdWaitBdEvent(
    path: Long,
    comptime T: type,
    eventno: []T,
    timeout: Long,
    signaledno: *Short,
    details: [4]Short,
) !void {
    const res = mdfunc_c.mdWaitBdEvent(
        path,
        eventno.ptr,
        timeout,
        signaledno,
        details,
    );
    if (res != 0) try codeToError(res);
}

pub fn mdSendEx(
    path: Long,
    netno: Long,
    stno: Long,
    devtyp: Device,
    devno: Long,
    size: *Long,
    comptime T: type,
    data: []const T,
) !void {
    const res = mdfunc_c.mdSendEx(
        path,
        netno,
        stno,
        @intCast(@intFromEnum(devtyp)),
        devno,
        size,
        @constCast(data.ptr),
    );
    if (res != 0) try codeToError(res);
}

pub fn mdReceiveEx(
    path: Long,
    netno: Long,
    stno: Long,
    devtyp: Device,
    devno: Long,
    size: *Long,
    comptime T: type,
    data: []T,
) !void {
    const res = mdfunc_c.mdReceiveEx(
        path,
        netno,
        stno,
        @intCast(@intFromEnum(devtyp)),
        devno,
        size,
        data.ptr,
    );
    if (res != 0) try codeToError(res);
}

pub fn mdDevSetEx(
    path: Long,
    netno: Long,
    stno: Long,
    devtyp: Device,
    devno: Long,
) !void {
    const res = mdfunc_c.mdDevSetEx(
        path,
        netno,
        stno,
        @intCast(@intFromEnum(devtyp)),
        devno,
    );
    if (res != 0) try codeToError(res);
}

pub fn mdDevRstEx(
    path: Long,
    netno: Long,
    stno: Long,
    devtyp: Device,
    devno: Long,
) !void {
    const res = mdfunc_c.mdDevRstEx(
        path,
        netno,
        stno,
        @intCast(@intFromEnum(devtyp)),
        devno,
    );
    if (res != 0) try codeToError(res);
}

pub fn mdRandWEx(
    path: Long,
    netno: Long,
    stno: Long,
    dev: []Long,
    comptime T: type,
    buf: []T,
    bufsize: Long,
) !void {
    const res = mdfunc_c.mdRandWEx(
        path,
        netno,
        stno,
        dev.ptr,
        buf.ptr,
        bufsize,
    );
    if (res != 0) try codeToError(res);
}

pub fn mdRandREx(
    path: Long,
    netno: Long,
    stno: Long,
    dev: []Long,
    comptime T: type,
    buf: []T,
    bufsize: Long,
) !void {
    const res = mdfunc_c.mdRandREx(
        path,
        netno,
        stno,
        dev.ptr,
        buf.ptr,
        bufsize,
    );
    if (res != 0) try codeToError(res);
}

pub fn mdRemBufWriteEx(
    path: Long,
    netno: Long,
    stno: Long,
    offset: Long,
    size: *Long,
    comptime T: type,
    data: []T,
) !void {
    const res = mdfunc_c.mdRemBufWriteEx(
        path,
        netno,
        stno,
        offset,
        size,
        data.ptr,
    );
    if (res != 0) try codeToError(res);
}

pub fn mdRemBufReadEx(
    path: Long,
    netno: Long,
    stno: Long,
    offset: Long,
    size: *Long,
    comptime T: type,
    data: []T,
) !void {
    const res = mdfunc_c.mdRemBufReadEx(
        path,
        netno,
        stno,
        offset,
        size,
        data.ptr,
    );
    if (res != 0) try codeToError(res);
}

pub const CcLinkV2 = struct {
    pub const Station = struct {
        /// Returns if provided station number is own station.
        pub fn isOwn(station_num: u8) bool {
            return station_num == 255;
        }

        /// Returns if provided station number is other station.
        pub fn isOther(station_num: u8) bool {
            return station_num >= 0 and station_num < 64;
        }

        /// Returns if provided station number is a logical number set by the
        /// MELSEC Device Monitor Utility.
        pub fn isLogicalSetByUtility(station_num: u8) bool {
            return station_num >= 65 and station_num < 240;
        }
    };

    pub const StationEx = struct {
        /// Returns if provided station number is own station.
        pub fn isOwn(network_num: u8, station_num: u8) bool {
            return network_num == 0 and station_num == 255;
        }

        /// Returns if provided station number is other station.
        pub fn isOther(network_num: u8, station_num: u8) bool {
            return network_num == 0 and station_num >= 0 and station_num < 64;
        }

        /// Returns if provided station number is a logical number set by the
        /// MELSEC Device Monitor Utility.
        pub fn isLogicalSetByUtility(network_num: u8, station_num: u8) bool {
            return network_num == 0 and station_num >= 65 and station_num < 240;
        }
    };
};

pub const Channel = enum(Short) {
    MelsecNetH_1Slot = 51,
    MelsecNetH_2Slot = 52,
    MelsecNetH_3Slot = 53,
    MelsecNetH_4Slot = 54,
    CcLink_1Slot = 81,
    CcLink_2Slot = 82,
    CcLink_3Slot = 83,
    CcLink_4Slot = 84,
    CcLinkIeControllerNetwork_151 = 151,
    CcLinkIeControllerNetwork_152 = 152,
    CcLinkIeControllerNetwork_153 = 153,
    CcLinkIeControllerNetwork_154 = 154,
    CcLinkIeFieldNetwork_181 = 181,
    CcLinkIeFieldNetwork_182 = 182,
    CcLinkIeFieldNetwork_183 = 183,
    CcLinkIeFieldNetwork_184 = 184,
};

pub const Device = def: {
    var result = std.builtin.Type.Enum{
        .tag_type = Short,
        .fields = &.{
            .{ .name = "DevX", .value = 1 },
            .{ .name = "DevY", .value = 2 },
            .{ .name = "DevL", .value = 3 },
            .{ .name = "DevM", .value = 4 },
            .{ .name = "DevSM", .value = 5 },
            .{ .name = "DevF", .value = 6 },
            .{ .name = "DevTT", .value = 7 },
            .{ .name = "DevTC", .value = 8 },
            .{ .name = "DevCT", .value = 9 },
            .{ .name = "DevCC", .value = 10 },
            .{ .name = "DevTN", .value = 11 },
            .{ .name = "DevCN", .value = 12 },
            .{ .name = "DevD", .value = 13 },
            .{ .name = "DevSD", .value = 14 },
            .{ .name = "DevTM", .value = 15 },
            .{ .name = "DevTS", .value = 16 },
            .{ .name = "DevTS2", .value = 16002 },
            .{ .name = "DevTS3", .value = 16003 },
            .{ .name = "DevCM", .value = 17 },
            .{ .name = "DevCS", .value = 18 },
            .{ .name = "DevCS2", .value = 18002 },
            .{ .name = "DevCS3", .value = 18003 },
            .{ .name = "DevA", .value = 19 },
            .{ .name = "DevZ", .value = 20 },
            .{ .name = "DevV", .value = 21 },
            .{ .name = "DevR", .value = 22 },
            .{ .name = "DevZR", .value = 220 },
            .{ .name = "DevB", .value = 23 },
            .{ .name = "DevW", .value = 24 },
            .{ .name = "DevQSB", .value = 25 },
            .{ .name = "DevSTT", .value = 26 },
            .{ .name = "DevSTC", .value = 27 },
            .{ .name = "DevQSW", .value = 28 },
            .{ .name = "DevQV", .value = 30 },
            .{ .name = "DevMRB", .value = 33 },
            .{ .name = "DevSTN", .value = 35 },
            .{ .name = "DevWw", .value = 36 },
            .{ .name = "DevWr", .value = 37 },
            .{ .name = "DevLZ", .value = 38 },
            .{ .name = "DevRD", .value = 39 },
            .{ .name = "DevLTT", .value = 41 },
            .{ .name = "DevLTC", .value = 42 },
            .{ .name = "DevLTN", .value = 43 },
            .{ .name = "DevLCT", .value = 44 },
            .{ .name = "DevLCC", .value = 45 },
            .{ .name = "DevLCN", .value = 46 },
            .{ .name = "DevLSTT", .value = 47 },
            .{ .name = "DevLSTC", .value = 48 },
            .{ .name = "DevLSTN", .value = 49 },
            .{ .name = "DevSPB", .value = 50 },
            .{ .name = "DevMAIL", .value = 101 },
            .{ .name = "DevMAILNC", .value = 102 },
            .{ .name = "DevRBM", .value = -32768 },
            .{ .name = "DevRAB", .value = -32736 },
            .{ .name = "DevRX", .value = -32735 },
            .{ .name = "DevRY", .value = -32734 },
            .{ .name = "DevRW", .value = -32732 },
            .{ .name = "DevSB", .value = -32669 },
            .{ .name = "DevSW", .value = -32668 },
        },
        .decls = &.{},
        .is_exhaustive = false,
    };
    for (0..257) |i| {
        result.fields = result.fields ++ [_]std.builtin.Type.EnumField{
            .{
                .name = "DevER" ++ std.fmt.comptimePrint("{d}", .{i}),
                .value = 22000 + i,
            },
        };
    }
    for (1..256) |i| {
        result.fields = result.fields ++ [_]std.builtin.Type.EnumField{
            .{
                .name = "DevLX" ++ std.fmt.comptimePrint("{d}", .{i}),
                .value = 1000 + i,
            },
        };
    }
    for (1..256) |i| {
        result.fields = result.fields ++ [_]std.builtin.Type.EnumField{
            .{
                .name = "DevLY" ++ std.fmt.comptimePrint("{d}", .{i}),
                .value = 2000 + i,
            },
        };
    }
    for (1..256) |i| {
        result.fields = result.fields ++ [_]std.builtin.Type.EnumField{
            .{
                .name = "DevLB" ++ std.fmt.comptimePrint("{d}", .{i}),
                .value = 23000 + i,
            },
        };
    }
    for (1..256) |i| {
        result.fields = result.fields ++ [_]std.builtin.Type.EnumField{
            .{
                .name = "DevLW" ++ std.fmt.comptimePrint("{d}", .{i}),
                .value = 24000 + i,
            },
        };
    }
    for (1..256) |i| {
        result.fields = result.fields ++ [_]std.builtin.Type.EnumField{
            .{
                .name = "DevLSB" ++ std.fmt.comptimePrint("{d}", .{i}),
                .value = 25000 + i,
            },
        };
    }
    for (1..256) |i| {
        result.fields = result.fields ++ [_]std.builtin.Type.EnumField{
            .{
                .name = "DevLSW" ++ std.fmt.comptimePrint("{d}", .{i}),
                .value = 28000 + i,
            },
        };
    }
    for (0..256) |i| {
        result.fields = result.fields ++ [_]std.builtin.Type.EnumField{
            .{
                .name = "DevSPG" ++ std.fmt.comptimePrint("{d}", .{i}),
                .value = 29000 + i,
            },
        };
    }
    break :def @Type(.{ .Enum = result });
};

pub const MdFuncError = error{
    DriverNotStarted,
    TimeOut,
    ChannelOpened,
    Path,
    UnsupportedFunctionExecution,
    StationNumber,
    NoReceptionData,
    MemoryReservation,
    SendRecvChannelNumber,
    BoardHwResourceBusy,
    RoutingParameter,
    BoardDriverIfSend,
    BoardDriverIfReceive,
    Parameter,
    MelsecInternal,
    AccessTargetCpu,
    InvalidDevice,
    DeviceNumber,
    RequestData,
    LinkRelated,
    RequestInvalid,
    InvalidPath,
    StartDeviceNumber,
    DeviceType,
    Size,
    NumberOfBlocks,
    ChannelNumber,
    BlockNumber,
    WriteProtect,
    NetworkNumberAndStationNumber,
    AllStationAndGroupNumberSpecification,
    RemoteCommandCode,
    SendRecvChannelNumberOutOfRange,
    DllLoad,
    ResourceTimeOut,
    IncorrectAccessTarget,
    RegistryAccess,
    CommunicationInitializationSetting,
    Close,
    RomOperation,
    NumberOfEvents,
    EventNumber,
    EventNumberDuplicateRegistration,
    TimeoutTime,
    EventWaitTimeOut,
    EventInitialization,
    NoEventSetting,
    UnsupportedFunctionExecutionPackageDriver,
    EventDuplicationOccurrence,
    RemoteDeviceStationAccess,
    MelsecnetHAndMelsecnet10NetworkSystem,
    TransientDataTargetStationNumber,
    CcLinkIeControllerNetworkSystem,
    TransientDataTargetStationNumber2,
    CcLinkIeFieldNetworkSystem,
    TransientDataImproper,
    NetworkNumber,
    StationNumber2,
    TransientDataSendResponseWaitTimeOut,
    EthernetNetworkSystem,
    CcLinkSystem,
    ModuleModeSetting,
    TransientUnsupported,
    ProcessingCode,
    Reset,
    RoutingFunctionUnsupportedStation,
    EventWaitTimeOut2,
    UnsupportedBlockDataAssurancePerStation,
    LinkRefresh,
    IncorrectModeSetting,
    SystemSleep,
    Mode,
    HardwareSelfDiagnosis,
    DataLinkDisconnectedDeviceAccess,
    AbnormalDataReception,
    DriverWdt,
    ChannelBusy,
    HardwareSelfDiagnosis2,
};

pub fn codeToError(code: Long) !void {
    switch (code) {
        1 => return error.DriverNotStarted,
        2 => return error.TimeOut,
        66 => return error.ChannelOpened,
        68 => return error.Path,
        69 => return error.UnsupportedFunctionExecution,
        70 => return error.StationNumber,
        71 => return error.NoReceptionData,
        77 => return error.MemoryReservation,
        85 => return error.SendRecvChannelNumber,
        100 => return error.BoardHwResourceBusy,
        101 => return error.RoutingParameter,
        102 => return error.BoardDriverIfSend,
        103 => return error.BoardDriverIfReceive,
        133 => return error.Parameter,
        4096...16383 => return error.MelsecInternal,
        16384...16431 => return error.AccessTargetCpu,
        16432 => return error.InvalidDevice,
        16433 => return error.DeviceNumber,
        16434...16511 => return error.AccessTargetCpu,
        16512 => return error.RequestData,
        16513...18943 => return error.AccessTargetCpu,
        18944...18945 => return error.LinkRelated,
        18946...19201 => return error.AccessTargetCpu,
        19202 => return error.RequestInvalid,
        19303...20479 => return error.AccessTargetCpu,
        -1 => return error.InvalidPath,
        -2 => return error.StartDeviceNumber,
        -3 => return error.DeviceType,
        -5 => return error.Size,
        -6 => return error.NumberOfBlocks,
        -8 => return error.ChannelNumber,
        -12 => return error.BlockNumber,
        -13 => return error.WriteProtect,
        -16 => return error.NetworkNumberAndStationNumber,
        -17 => return error.AllStationAndGroupNumberSpecification,
        -18 => return error.RemoteCommandCode,
        -19 => return error.SendRecvChannelNumber,
        -31 => return error.DllLoad,
        -32 => return error.ResourceTimeOut,
        -33 => return error.IncorrectAccessTarget,
        -36...-34 => return error.RegistryAccess,
        -37 => return error.CommunicationInitializationSetting,
        -42 => return error.Close,
        -43 => return error.RomOperation,
        -61 => return error.NumberOfEvents,
        -62 => return error.EventNumber,
        -63 => return error.EventNumberDuplicateRegistration,
        -64 => return error.TimeoutTime,
        -65 => return error.EventWaitTimeOut,
        -66 => return error.EventInitialization,
        -67 => return error.NoEventSetting,
        -69 => return error.UnsupportedFunctionExecutionPackageDriver,
        -70 => return error.EventDuplicationOccurrence,
        -71 => return error.RemoteDeviceStationAccess,
        -2173...-257 => return error.MelsecnetHAndMelsecnet10NetworkSystem,
        -2174 => return error.TransientDataTargetStationNumber,
        -4096...-2175 => return error.MelsecnetHAndMelsecnet10NetworkSystem,
        -7655...-4097 => return error.CcLinkIeControllerNetworkSystem,
        -7656 => return error.TransientDataTargetStationNumber2,
        -7671...-7657 => return error.CcLinkIeControllerNetworkSystem,
        -7672 => return error.TransientDataTargetStationNumber2,
        -8192...-7673 => return error.CcLinkIeControllerNetworkSystem,
        -11682...-8193 => return error.CcLinkIeFieldNetworkSystem,
        -11683 => return error.TransientDataImproper,
        -11716...-11684 => return error.CcLinkIeFieldNetworkSystem,
        -11717 => return error.NetworkNumber,
        -11745...-11718 => return error.CcLinkIeFieldNetworkSystem,
        -11746 => return error.StationNumber2,
        -12127...-11747 => return error.CcLinkIeFieldNetworkSystem,
        -12128 => return error.TransientDataSendResponseWaitTimeOut,
        -12288...-12129 => return error.CcLinkIeFieldNetworkSystem,
        -16384...-12289 => return error.EthernetNetworkSystem,
        -18559...-16385 => return error.CcLinkSystem,
        -18560 => return error.ModuleModeSetting,
        -18571...-18561 => return error.CcLinkSystem,
        -18572 => return error.TransientUnsupported,
        -20480...-18573 => return error.CcLinkSystem,
        -25056 => return error.ProcessingCode,
        -26334 => return error.Reset,
        -26336 => return error.RoutingFunctionUnsupportedStation,
        -27902 => return error.EventWaitTimeOut,
        -28138 => return error.UnsupportedBlockDataAssurancePerStation,
        -28139 => return error.LinkRefresh,
        -28140 => return error.IncorrectModeSetting,
        -28141 => return error.SystemSleep,
        -28142 => return error.Mode,
        -28144...-28143 => return error.HardwareSelfDiagnosis,
        -28150 => return error.DataLinkDisconnectedDeviceAccess,
        -28151 => return error.AbnormalDataReception,
        -28158 => return error.DriverWdt,
        -28622 => return error.ChannelBusy,
        -28634 => return error.HardwareSelfDiagnosis2,
        -28636 => return error.HardwareSelfDiagnosis2,
        else => return error.Unknown,
    }
}
