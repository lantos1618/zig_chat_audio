const std = @import("std");
const crypto = std.crypto;
const testing = std.testing;

const ma = @cImport({
    @cDefine("MINIAUDIO_IMPLEMENTATION", "");
    @cInclude("miniaudio/miniaudio.h");
});

const MiniaudioError = error{ DeviceStartError, DeviceInitializationError, EncoderInitializationError, FileInitializationError };

fn dataCallback(pDevice: [*c]ma.ma_device, pOutput: ?*anyopaque, pInput: ?*const anyopaque, frameCount: ma.ma_uint32) callconv(.C) void {
    var pEncoder: [*c]ma.ma_encoder = @ptrCast([*c]ma.ma_encoder, @alignCast(@import("std").meta.alignment(ma.ma_encoder), pDevice.*.pUserData));
    _ = ma.ma_encoder_write_pcm_frames(pEncoder, pInput, @bitCast(ma.ma_uint64, @as(c_ulonglong, frameCount)), null);
    _ = pOutput;
}

pub fn run() anyerror!void {
    var deviceConfig: ma.ma_device_config = undefined;
    var device: ma.ma_device = undefined;
    var stdin = std.io.getStdIn().reader();
    var text_buffer: [10]u8 = undefined;

    var encoderConfig: ma.ma_encoder_config = undefined;
    var encoder: ma.ma_encoder = undefined;

    encoderConfig = ma.ma_encoder_config_init(ma.ma_encoding_format_wav, ma.ma_format_f32, 2, 44100);

    if (ma.ma_encoder_init_file("./file.wav", &encoderConfig, &encoder) != ma.MA_SUCCESS) {
        return MiniaudioError.FileInitializationError;
    }

    deviceConfig = ma.ma_device_config_init(@bitCast(c_uint, ma.ma_device_type_capture));
    deviceConfig.capture.format = encoder.config.format;
    deviceConfig.capture.channels = encoder.config.channels;
    deviceConfig.sampleRate = encoder.config.sampleRate;
    deviceConfig.dataCallback = dataCallback;
    deviceConfig.pUserData = @ptrCast(?*anyopaque, &encoder);

    if (ma.ma_device_init(null, &deviceConfig, &device) != ma.MA_SUCCESS) {
        return MiniaudioError.DeviceInitializationError;
    }

    if (ma.ma_device_start(&device) != ma.MA_SUCCESS) {
        return MiniaudioError.DeviceStartError;
    }

    defer {
        _ = ma.ma_device_uninit(&device);
        _ = ma.ma_encoder_uninit(&encoder);
    }

    if (try stdin.readUntilDelimiterOrEof(text_buffer[0..], '\n')) |user_input| {
        std.log.info("{d}", .{std.fmt.parseInt(i64, user_input, 10)});
    } else {
        std.log.info("{d}", .{@as(i64, 0)});
    }
}
