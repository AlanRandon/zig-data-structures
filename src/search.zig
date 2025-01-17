const std = @import("std");
const Order = std.math.Order;
const sort = @import("./sort.zig").quickSort;

// TODO:
// pub fn Eytzinger(comptime T: type, Context: type) type {
//     return struct {
//         data: []T,
//         context: @TypeOf(context),
//     }{
//         .data = data,
//         .context = context,
//     };
// }

pub fn binarySearch(
    comptime T: type,
    data: []T,
    comptime Context: type,
    opts: anytype,
) ?*T {
    const context: Context = comptime if (std.meta.fields(Context).len == 0) .{} else opts.context;

    if (data.len == 0) {
        return null;
    }

    const midpoint = data.len / 2;
    switch (context.search(data[midpoint])) {
        .gt => {
            const left = data[0..midpoint];
            return @call(
                // .always_tail,
                .auto,
                binarySearch,
                .{ T, left, Context, opts },
            );
        },
        .lt => {
            const right = data[(midpoint + 1)..data.len];
            return @call(
                // .always_tail,
                .auto,
                binarySearch,
                .{ T, right, Context, opts },
            );
        },
        .eq => return &data[midpoint],
    }
}

test "binarySearch" {
    const Pair = struct { u8, u8 };

    var data = [_]Pair{
        .{ 1, 'a' },
        .{ 2, 'b' },
        .{ 3, 'c' },
        .{ 5, 'd' },
        .{ 6, 'e' },
        .{ 7, 'f' },
    };

    const Context = struct {
        value: u8,

        fn search(context: *const @This(), item: Pair) Order {
            return std.math.order(item.@"0", context.value);
        }
    };

    {
        const item = binarySearch(Pair, &data, Context, .{ .context = Context{ .value = 2 } }) orelse @panic("item not found");
        try std.testing.expectEqual(item.@"1", 'b');
    }

    {
        const item = binarySearch(Pair, &data, Context, .{ .context = Context{ .value = 4 } });
        try std.testing.expectEqual(@as(?*Pair, null), item);
    }
}
