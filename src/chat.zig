const std = @import("std");
const net = std.net;
const fs = std.fs;
const os = std.os;

pub const io_mode = .evented;

pub fn run() anyerror!void {
    var room_alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer room_alloc.deinit();
    const allocator = &room_alloc.allocator;
    // const ptr = try allocator.create(room_alloc);

    var server = net.StreamServer.init(.{});
    defer server.deinit();

    // TODO handle concurrent accesses to this hash map
    var room = Room{ .clients = std.AutoHashMap(*Client, void).init(allocator) };

    try server.listen(net.Address.parseIp("127.0.0.1", 0) catch unreachable);
    std.debug.warn("listening at {}\n", .{server.listen_address});

    while (true) {
        const client = try allocator.create(Client);
        client.* = Client{
            .conn = try server.accept(),
            .handle_frame = async client.handle(&room),
        };
        try room.clients.putNoClobber(client, {});
    }
}
const Client = struct {
    conn: net.StreamServer.Connection,
    handle_frame: @Frame(handle),

    fn handle(self: *Client, room: *Room) !void {
        var con_message = "server: welcome to teh chat server\n";
        try self.conn.stream.writevAll(con_message);
        while (true) {
            var buf: [100]u8 = undefined;
            const amt = try self.conn.stream.read(&buf);
            const msg = buf[0..amt];
            room.broadcast(msg, self);
        }
    }
};
const Room = struct {
    clients: std.AutoHashMap(*Client, void),

    fn broadcast(room: *Room, msg: []const u8, sender: *Client) void {
        var it = room.clients.iterator();
        while (it.next()) |entry| {
            const client = entry.key;
            if (client == sender) continue;
            client.conn.stream.writevAll(msg) catch |e| std.debug.warn("unable to send: {}\n", .{e});
        }
    }
};
