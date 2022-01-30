const std = @import("std");
const crypto = std.crypto;
const testing = std.testing;

const ma = @cImport({
    @cDefine("MINIAUDIO_IMPLEMENTATION", "");
    @cInclude("miniaudio.h");
});


const MiniaudioError = error {
    InitializationError
};

fn dataCallback(pDevice: [*c]ma.ma_device, pOutput: ?*anyopaque, pInput: ?*const anyopaque, frameCount: ma.ma_uint32) callconv(.C) void {

    // _ = ma.MA_ASSERT(pDevice.*.capture.format == pDevice.*.playback.format);
    // _ = ma.MA_ASSERT(pDevice.*.capture.channels == pDevice.*.playback.channels);
    // _ = ma.MA_COPY_MEMORY(pOutput, pInput, frameCount *% ma.ma_get_bytes_per_frame(pDevice.*.capture.format, pDevice.*.capture.channels));

    // try testing.expect(pDevice.*.capture.format == pDevice.*.playback.format) catch { unreachable;};
    // try testing.expect(pDevice.*.capture.channels == pDevice.*.playback.channels) catch {unreachable;};
    
    @memcpy(
            @ptrCast([*]u8, pOutput),
            @ptrCast([*]const u8, pInput),
            frameCount * ma.ma_get_bytes_per_frame(
                pDevice.*.capture.format,
                pDevice.*.capture.channels)
            );
}

pub fn main() anyerror!void {

    var result: ma.ma_result = undefined;
    var deviceConfig: ma.ma_device_config = undefined;
    var device: ma.ma_device = undefined;
    var stdin = std.io.getStdIn().reader();
    var buf: [10]u8 = undefined;
    
    deviceConfig = ma.ma_device_config_init(@bitCast(c_uint, ma.ma_device_type_duplex));
    deviceConfig.capture.pDeviceID = null;
    deviceConfig.capture.format = @bitCast(c_uint, ma.ma_format_s16);
    deviceConfig.capture.channels = 2;
    deviceConfig.capture.shareMode = @bitCast(c_uint, ma.ma_share_mode_shared);
    deviceConfig.playback.pDeviceID = null;
    deviceConfig.playback.format = @bitCast(c_uint, ma.ma_format_s16);
    deviceConfig.playback.channels = 2;
    deviceConfig.dataCallback = dataCallback;
    result = ma.ma_device_init(null, &deviceConfig, &device);
    
     _ = ma.ma_device_start(&device);

    if (try stdin.readUntilDelimiterOrEof(buf[0..], '\n')) |user_input| {
        std.log.info("{d}", .{std.fmt.parseInt(i64, user_input, 10)});
    } else {
        std.log.info("{d}", .{@as(i64, 0)});
    }
    _ = ma.ma_device_uninit(&device);

}


test "basic test" {
    
    const aeads = [_]type{ crypto.aead.chacha_poly.XChaCha20Poly1305 };
    const m = "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it.";
    const ad = "Additional data";

    inline for (aeads) |aead| {
        const key = [_]u8{69} ** aead.key_length;
        const nonce = [_]u8{42} ** aead.nonce_length;
        var c: [m.len]u8 = undefined;
        var tag: [aead.tag_length]u8 = undefined;
        var out: [m.len]u8 = undefined;

        aead.encrypt(c[0..], tag[0..], m, ad, nonce, key);
        try aead.decrypt(out[0..], c[0..], tag, ad[0..], nonce, key);
        try testing.expectEqualSlices(u8, out[0..], m);
        
        // this should break 
        c[0] += 1;
        try testing.expectError(error.AuthenticationFailed, aead.decrypt(out[0..], c[0..], tag, ad[0..], nonce, key));

        std.log.info("in_message: {s}", .{m});
        std.log.info("c_message: {s}", .{c});
        std.log.info("out_message: {s}", .{out});

    }}
