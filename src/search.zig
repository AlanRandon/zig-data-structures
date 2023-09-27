const std = @import("std");
const Order = std.math.Order;

pub fn binarySearch(comptime T: type, data: []const T, searcher: anytype) ?T {
    if (data.len == 0) {
        return null;
    }

    const midpoint = data.len / 2;
    switch (searcher.order(data[midpoint])) {
        .gt => {
            const left = data[0..midpoint];
            return @call(
                .always_tail,
                binarySearch,
                .{ T, left, searcher },
            );
        },
        .lt => {
            const right = data[(midpoint + 1)..data.len];
            return @call(
                .always_tail,
                binarySearch,
                .{ T, right, searcher },
            );
        },
        .eq => return data[midpoint],
    }
}

test "binary search works" {
    const Pair = struct { u8, u8 };
    const data = [_]Pair{
        .{ 1, 'a' },
        .{ 2, 'b' },
        .{ 3, 'c' },
        .{ 5, 'd' },
        .{ 6, 'e' },
        .{ 7, 'f' },
    };

    {
        const item = binarySearch(Pair, @as([]const Pair, &data), struct {
            fn order(item: Pair) Order {
                return std.math.order(item.@"0", 2);
            }
        }) orelse @panic("item not found");
        try std.testing.expectEqual(item.@"1", 'b');
    }

    {
        const item = binarySearch(Pair, @as([]const Pair, &data), struct {
            fn order(item: Pair) Order {
                return std.math.order(item.@"0", 4);
            }
        });
        try std.testing.expectEqual(@as(?Pair, null), item);
    }
}
