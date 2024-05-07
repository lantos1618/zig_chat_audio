const std = @import("std");
const crypto = std.crypto;
const testing = std.testing;
const cp = @import("capture_playblack.zig");
const cf = @import("capture_file.zig");
// const chat = @import("chat.zig");

const ma = @cImport({
    @cDefine("MINIAUDIO_IMPLEMENTATION", "");
    @cInclude("miniaudio/miniaudio.h");
});

pub fn main() anyerror!void {
    //     try cp.run();
    //     try cf.run();
    // try chat.run();

    // var room_alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // defer room_alloc.deinit();
    // // const allocator = &room_alloc.allocator;F
    // // const ptr = try allocator.create(room_alloc);

    // const Person = struct {
    //     name: []const u8,
    //     age: i32
    // };

    // // var map = std.AutoHashMap([]const u8, Person).init(room_alloc.allocator());
    // var map = std.StringArrayHashMap(Person).init(room_alloc.allocator());

    // defer map.deinit();

    // try map.put("test", .{.name="test", .age= 21});

    // std.log.info("{d}", .{map});

    const aeads = [_]type{crypto.aead.chacha_poly.XChaCha20Poly1305};
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
    }
}

test "basic test" {
    const aeads = [_]type{crypto.aead.chacha_poly.XChaCha20Poly1305};
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
    }
}
