const std = @import("std");
const crypto = std.crypto;
const testing = std.testing;

const ma = @cImport({
    @cDefine("MINIAUDIO_IMPLEMENTATION", "");
    @cInclude("miniaudio/miniaudio.h");
});

const MiniaudioError = error{ DeviceStartError, DeviceInitializationError, EncoderInitializationError, FileInitializationError };

fn dataCallback(pDevice: [*c]ma.ma_device, pOutput: ?*anyopaque, pInput: ?*const anyopaque, frameCount: ma.ma_uint32) callconv(.C) void {
    _ = pDevice;
    _ = frameCount;
    // _ = ma.MA_ASSERT(pDevice.*.capture.format == pDevice.*.playback.format);
    // _ = ma.MA_ASSERT(pDevice.*.capture.channels == pDevice.*.playback.channels);
    // _ = ma.MA_COPY_MEMORY(pOutput, pInput, frameCount *% ma.ma_get_bytes_per_frame(pDevice.*.capture.format, pDevice.*.capture.channels));

    // try testing.expect(pDevice.*.capture.format == pDevice.*.playback.format) catch { unreachable;};
    // try testing.expect(pDevice.*.capture.channels == pDevice.*.playback.channels) catch {unreachable;};

    // @memcpy(@ptrCast([*]u8, pOutput), @ptrCast([*]const u8, pInput), frameCount * ma.ma_get_bytes_per_frame(pDevice.*.capture.format, pDevice.*.capture.channels));
    const dest: []u8 = @ptrCast(pOutput);
    const source: []u8 = @ptrCast(pInput);
    @memcpy(dest, source);
}

pub fn run() anyerror!void {
    var deviceConfig: ma.ma_device_config = undefined;
    var device: ma.ma_device = undefined;
    var stdin = std.io.getStdIn().reader();
    var text_buffer: [10]u8 = undefined;
    const duplex_type: c_uint = @bitCast(ma.ma_device_type_duplex);
    const capture_format: c_uint = @bitCast(ma.ma_format_s16);

    const shareMode: c_uint = @bitCast(ma.ma_share_mode_shared);
    const playback_format: c_uint = @bitCast(ma.ma_format_s16);

    deviceConfig = ma.ma_device_config_init(duplex_type);
    deviceConfig.capture.pDeviceID = null;
    deviceConfig.capture.format = capture_format;
    deviceConfig.capture.channels = 2;
    deviceConfig.capture.shareMode = shareMode;
    deviceConfig.playback.pDeviceID = null;
    deviceConfig.playback.format = playback_format;
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
