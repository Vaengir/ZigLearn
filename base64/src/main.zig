const std = @import("std");
const stdout = std.io.getStdOut().writer();

const Base64 = struct {
    _table: *const [64]u8,

    fn init() Base64 {
        const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        const lower = "abcdefghijklmnopqrstuvwxyz";
        const numbers_symb = "0123456789+/";
        return Base64{
            ._table = upper ++ lower ++ numbers_symb,
        };
    }

    fn encode(self: Base64, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
        if (input.len == 0) {
            return "";
        }

        const n_out = try _calc_encode_length(input);
        var out = try allocator.alloc(u8, n_out);
        var buf = [3]u8{ 0, 0, 0 };
        var count: u8 = 0;
        var iout: u64 = 0;

        for (input, 0..) |_, i| {
            buf[count] = input[i];
            count += 1;
            if (count == 3) {
                out[iout] = self._char_at(buf[0] >> 2);
                out[iout + 1] = self._char_at(((buf[0] & 0b00000011) << 4) + (buf[1] >> 4));
                out[iout + 2] = self._char_at(((buf[1] & 0b00001111) << 2) + (buf[2] >> 6));
                out[iout + 3] = self._char_at(buf[2] & 0b00111111);
                iout += 4;
                count = 0;
            }
        }
        if (count == 1) {
            out[iout] = self._char_at(buf[0] >> 2);
            out[iout + 1] = self._char_at((buf[0] & 0b00000011) << 4);
            out[iout + 2] = '=';
            out[iout + 3] = '=';
        }
        if (count == 2) {
            out[iout] = self._char_at(buf[0] >> 2);
            out[iout + 1] = self._char_at(((buf[0] & 0b00000011) << 4) + (buf[1] >> 4));
            out[iout + 2] = self._char_at((buf[1] & 0b00001111) << 2);
            out[iout + 3] = '=';
            iout += 4;
        }

        return out;
    }

    fn decode(self: Base64, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
        if (input.len == 0) {
            return "";
        }

        const n_output = try _calc_decode_length(input);
        var out = try allocator.alloc(u8, n_output);
        var count: u8 = 0;
        var iout: u64 = 0;
        var buf = [4]u8{ 0, 0, 0, 0 };

        for (0..input.len) |i| {
            buf[count] = self._char_index(input[i]);
            count += 1;
            if (count == 4) {
                out[iout] = (buf[0] << 2) + (buf[1] >> 4);
                if (buf[2] != 64) {
                    out[iout + 1] = (buf[1] << 4) + (buf[2] >> 2);
                }
                if (buf[3] != 64) {
                    out[iout + 2] = (buf[2] << 6) + buf[3];
                }
                iout += 3;
                count = 0;
            }
        }

        return out;
    }

    fn _char_at(self: Base64, index: usize) u8 {
        return self._table[index];
    }

    fn _char_index(self: Base64, char: u8) u8 {
        if (char == '=') {
            return 64;
        }

        var index: u8 = 0;
        for (0..63) |i| {
            if (self._char_at(i) == char) {
                break;
            }
            index += 1;
        }

        return index;
    }

    fn _calc_encode_length(input: []const u8) !usize {
        if (input.len < 3) {
            return 4;
        }
        const n_groups: usize = try std.math.divCeil(usize, input.len, 3);

        return n_groups * 4;
    }

    fn _calc_decode_length(input: []const u8) !usize {
        if (input.len < 3) {
            return 3;
        }
        const n_groups: usize = try std.math.divFloor(usize, input.len, 4);
        var multiple_groups: usize = n_groups * 3;
        var i: usize = input.len - 1;
        while (i > 0) : (i -= 1) {
            if (input[i] == '=') {
                multiple_groups -= 1;
            } else {
                break;
            }
        }

        return multiple_groups;
    }
};

pub fn main() !void {
    var memory_buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&memory_buffer);
    const allocator = fba.allocator();

    const text = "Testing some more stuff";
    const etext = "VGVzdGluZyBzb21lIG1vcmUgc3R1ZmY=";
    const base64 = Base64.init();
    const encoded_text = try base64.encode(allocator, text);
    const decoded_text = try base64.decode(allocator, etext);

    try stdout.print("Encoded text: {s}\n", .{encoded_text});
    try stdout.print("Decoded text: {s}\n", .{decoded_text});
    try stdout.print("Encoded length: {d}\n", .{encoded_text.len});
    try stdout.print("Decoded length: {d}\n", .{decoded_text.len});
}

test "Index 28 return 'c'" {
    const base64 = Base64.init();
    const expected = 'c';
    const result = base64._char_at(28);
    try std.testing.expectEqual(expected, result);
}

test "Encode length min 4" {
    try std.testing.expectEqual(4, Base64._calc_encode_length("Hi"));
}

test "Encode length 8" {
    try std.testing.expectEqual(8, Base64._calc_encode_length("Halloi"));
}

test "Encode length 32" {
    try std.testing.expectEqual(32, Base64._calc_encode_length("Testing some more stuff"));
}

test "Decode length min 3" {
    try std.testing.expectEqual(3, Base64._calc_decode_length("SG"));
}

test "Decode length 2" {
    try std.testing.expectEqual(2, Base64._calc_decode_length("SGk="));
}

test "Decode length 6" {
    try std.testing.expectEqual(6, Base64._calc_decode_length("SGFsbG9p"));
}

test "Decode length 23" {
    try std.testing.expectEqual(23, Base64._calc_decode_length("VGVzdGluZyBzb21lIG1vcmUgc3R1ZmY="));
}

test "Encoded String Hi" {
    var memory_buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&memory_buffer);
    const allocator = fba.allocator();
    const base64 = Base64.init();
    const expected: []const u8 = "SGk=";
    const result: []const u8 = try base64.encode(allocator, "Hi");
    try std.testing.expect(std.mem.eql(u8, expected, result));
}

test "Decoding String SGk=" {
    var memory_buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&memory_buffer);
    const allocator = fba.allocator();
    const base64 = Base64.init();
    const expected: []const u8 = "Hi";
    const result: []const u8 = try base64.decode(allocator, "SGk=");
    try std.testing.expect(std.mem.eql(u8, expected, result));
}

test "Encoded String 'Testing some more stuff'" {
    var memory_buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&memory_buffer);
    const allocator = fba.allocator();
    const base64 = Base64.init();
    const expected: []const u8 = "VGVzdGluZyBzb21lIG1vcmUgc3R1ZmY=";
    const result: []const u8 = try base64.encode(allocator, "Testing some more stuff");
    try std.testing.expect(std.mem.eql(u8, expected, result));
}

test "Decoding String 'VGVzdGluZyBzb21lIG1vcmUgc3R1ZmY='" {
    var memory_buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&memory_buffer);
    const allocator = fba.allocator();
    const base64 = Base64.init();
    const expected: []const u8 = "Testing some more stuff";
    const result: []const u8 = try base64.decode(allocator, "VGVzdGluZyBzb21lIG1vcmUgc3R1ZmY=");
    try std.testing.expect(std.mem.eql(u8, expected, result));
}
