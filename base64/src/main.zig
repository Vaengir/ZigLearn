const std = @import("std");

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

    fn _char_at(self: Base64, index: usize) u8 {
        return self._table[index];
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
    const stdout = std.io.getStdOut().writer();
    const stderr = std.io.getStdErr().writer();
    try stdout.print("Whatever\n", .{});
    try stderr.print("Whatever\n", .{});
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

test "Encode length 16" {
    try std.testing.expectEqual(16, Base64._calc_encode_length("Halloelele"));
}

test "Decode length min 3" {
    try std.testing.expectEqual(3, Base64._calc_decode_length("SG"));
}

test "Decode length 2" {
    try std.testing.expectEqual(2, Base64._calc_decode_length("SGk="));
}

// test "Decode length 8" {
//     try std.testing.expectEqual(8, Base64._calc_encode_length("Halloi"));
// }

// test "Decode length 16" {
//     try std.testing.expectEqual(16, Base64._calc_encode_length("Halloelele"));
// }
