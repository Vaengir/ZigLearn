const std = @import("std");
const Method = @import("socket_request").Method;
const Response = @import("socket_response").Response;
const Request = @import("socket_request").Request;
const Socket = @import("socket_config").Socket;

const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    const socket = try Socket.init(.{ 127, 0, 0, 1 }, 3490);
    try stdout.print("Server Addr: {any}\n", .{socket._adress});
    var server = try socket._adress.listen(.{});
    const connection = try server.accept();
    var buffer: [1000]u8 = undefined;
    for (&buffer) |i| {
        buffer[i] = 0;
    }
    try Request.read_request(connection, &buffer);
    const request = Request.parse_request(&buffer);
    if (request.method == Method.GET) {
        try Response.send_200(connection);
    } else {
        try Response.send_404(connection);
    }
}
