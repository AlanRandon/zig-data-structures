const std = @import("std");

fn Iter(comptime T: type) type {
    return struct {
        index: usize,
        data: []const T,
        buf: []T,

        const Self = @This();

        fn next(it: *Self) ?[]const T {
            if (it.index >= std.math.pow(usize, 2, it.data.len)) {
                return null;
            }

            var size: usize = 0;

            for (0..it.data.len) |i| {
                if (it.index >> @intCast(i) & 1 == 1) {
                    it.buf[size] = it.data[i];
                    size += 1;
                }
            }

            it.index += 1;
            return it.buf[0..size];
        }
    };
}

pub fn powerset(comptime T: type, data: []const T, buf: []T) Iter(T) {
    return .{
        .index = 0,
        .data = data,
        .buf = buf,
    };
}

test "powerset works" {
    const data: []const u8 = &.{ 1, 2, 3 };
    var buf: [3]u8 = undefined;

    var it = powerset(u8, data, &buf);

    try std.testing.expectEqualDeep(@as([]const u8, &.{}), it.next());
    try std.testing.expectEqualDeep(@as([]const u8, &.{1}), it.next());
    try std.testing.expectEqualDeep(@as([]const u8, &.{2}), it.next());
    try std.testing.expectEqualDeep(@as([]const u8, &.{ 1, 2 }), it.next());
    try std.testing.expectEqualDeep(@as([]const u8, &.{3}), it.next());
    try std.testing.expectEqualDeep(@as([]const u8, &.{ 1, 3 }), it.next());
    try std.testing.expectEqualDeep(@as([]const u8, &.{ 2, 3 }), it.next());
    try std.testing.expectEqualDeep(@as([]const u8, &.{ 1, 2, 3 }), it.next());
    try std.testing.expectEqualDeep(null, it.next());
}
