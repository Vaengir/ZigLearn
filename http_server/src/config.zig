const builtin = @import("builtin");
const net = std.net;
const std = @import("std");

pub const Socket = struct {
    _adress: net.Address,
    _stream: net.Stream,

    pub fn init(ip_addr: [4]u8, port: u16) !Socket {
        const addr = net.Address.initIp4(ip_addr, port);
        const socket = try std.posix.socket(addr.any.family, std.posix.SOCK.STREAM, std.posix.IPPROTO.TCP);
        const stream = net.Stream{ .handle = socket };

        return Socket{ ._adress = addr, ._stream = stream };
    }
};
