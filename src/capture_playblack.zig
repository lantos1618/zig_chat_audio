const std = @import("std");
const crypto = std.crypto;
const testing = std.testing;

const ma = @cImport({
    @cDefine("MINIAUDIO_IMPLEMENTATION", "");
    @cInclude("miniaudio/miniaudio.h");
});

const MiniaudioError = error{ DeviceStartError, DeviceInitializationError, EncoderInitializationError, FileInitializationError };

fn dataCallback(pDevice: [*c]ma.ma_device, pOutput: ?*anyopaque, pInput: ?*const anyopaque, frameCount: ma.ma_uint32) callconv(.C) void {

    // _ = ma.MA_ASSERT(pDevice.*.capture.format == pDevice.*.playback.format);
    // _ = ma.MA_ASSERT(pDevice.*.capture.channels == pDevice.*.playback.channels);
    // _ = ma.MA_COPY_MEMORY(pOutput, pInput, frameCount *% ma.ma_get_bytes_per_frame(pDevice.*.capture.format, pDevice.*.capture.channels));

    // try testing.expect(pDevice.*.capture.format == pDevice.*.playback.format) catch { unreachable;};
    // try testing.expect(pDevice.*.capture.channels == pDevice.*.playback.channels) catch {unreachable;};

    @memcpy(@ptrCast([*]u8, pOutput), @ptrCast([*]const u8, pInput), frameCount * ma.ma_get_bytes_per_frame(pDevice.*.capture.format, pDevice.*.capture.channels));
}

pub fn run() anyerror!void {
    var deviceConfig: ma.ma_device_config = undefined;
    var device: ma.ma_device = undefined;
    var stdin = std.io.getStdIn().reader();
    var text_buffer: [10]u8 = undefined;

    deviceConfig = ma.ma_device_config_init(@bitCast(c_uint, ma.ma_device_type_duplex));
    deviceConfig.capture.pDeviceID = null;
    deviceConfig.capture.format = @bitCast(c_uint, ma.ma_format_s16);
    deviceConfig.capture.channels = 2;
    deviceConfig.capture.shareMode = @bitCast(c_uint, ma.ma_share_mode_shared);
    deviceConfig.playback.pDeviceID = null;
    deviceConfig.playback.format = @bitCast(c_uint, ma.ma_format_s16);
    deviceConfig.playback.channels = 2;
    deviceConfig.dataCallback = dataCallback;

    if (ma.ma_device_init(null, &deviceConfig, &device) != ma.MA_SUCCESS) {
        return MiniaudioError.DeviceInitializationError;
    }

    if (ma.ma_device_start(&device) != ma.MA_SUCCESS) {
        return MiniaudioError.DeviceStartError;
    }

    defer {
        _ = ma.ma_device_uninit(&device);
    }

    if (try stdin.readUntilDelimiterOrEof(text_buffer[0..], '\n')) |user_input| {
        std.log.info("{d}", .{std.fmt.parseInt(i64, user_input, 10)});
    } else {
        std.log.info("{d}", .{@as(i64, 0)});
    }
}