const std = @import("std");
const Allocator = std.mem.Allocator;

/// Sort `data` and copy it to `buffer`
fn mergeSort(data: anytype, buffer: anytype) void {
    const item_type = @typeInfo(@TypeOf(data)).Pointer.child;
    const midpoint = data.len / 2;
    if (midpoint == 0) {
        for (data, 0..) |item, index| {
            buffer[index] = item;
        }
        return;
    }

    mergeSort(data[0..midpoint], buffer[0..midpoint]);
    mergeSort(data[midpoint..data.len], buffer[midpoint..data.len]);

    merge(item_type, buffer[0..midpoint], buffer[midpoint..data.len], data);
    for (data, 0..) |item, index| {
        buffer[index] = item;
    }
}

pub fn merge(comptime T: type, a: []T, b: []T, merged: []T) void {
    var a_index: usize = 0;
    var b_index: usize = 0;
    var index: usize = 0;

    while (a_index < a.len and b_index < b.len) {
        switch (std.math.order(a[a_index], b[b_index])) {
            .lt, .eq => {
                merged[index] = a[a_index];
                a_index += 1;
            },
            .gt => {
                merged[index] = b[b_index];
                b_index += 1;
            },
        }
        index += 1;
    }

    while (a_index < a.len) {
        merged[index] = a[a_index];
        index += 1;
        a_index += 1;
    }

    while (b_index < b.len) {
        merged[index] = b[b_index];
        index += 1;
        b_index += 1;
    }
}

test "merge sort works" {
    var data = [_]u8{ 4, 7, 1, 5 };
    var sorted: [4]u8 = undefined;
    mergeSort(@as([]u8, &data), @as([]u8, &sorted));
    var expected = [_]u8{ 1, 4, 5, 7 };
    try std.testing.expectEqualDeep(@as([]u8, &expected), @as([]u8, &sorted));
}

test "merge works" {
    var a = [_]u8{ 1, 3, 4 };
    var b = [_]u8{ 2, 5, 7 };
    var merged: [6]u8 = undefined;
    merge(
        u8,
        @as([]u8, &a),
        @as([]u8, &b),
        @as([]u8, &merged),
    );
    var expected = [_]u8{ 1, 2, 3, 4, 5, 7 };
    try std.testing.expectEqualDeep(merged, expected);
}
