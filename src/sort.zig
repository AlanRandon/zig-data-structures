const std = @import("std");
const Allocator = std.mem.Allocator;
const Order = std.math.Order;

pub fn insertionSort(
    data: anytype,
    order: fn (
        @typeInfo(@TypeOf(data)).pointer.child,
        @typeInfo(@TypeOf(data)).pointer.child,
    ) Order,
) void {
    const item_type = @typeInfo(@TypeOf(data)).pointer.child;
    var sorted_index: isize = 1;
    while (@as(usize, @bitCast(sorted_index)) < data.len) {
        var position: isize = sorted_index;
        while (position > 0 and order(data[@bitCast(position - 1)], data[@bitCast(position)]) == .gt) {
            std.mem.swap(item_type, &data[@bitCast(position - 1)], &data[@bitCast(position)]);
            position -= 1;
        }
        sorted_index += 1;
    }
}

test "insertion sort works" {
    {
        var data = [_]u8{ 3, 1, 6, 4, 5, 2 };

        insertionSort(
            @as([]u8, &data),
            ungeneric_order(u8),
        );
        var expected = [_]u8{ 1, 2, 3, 4, 5, 6 };
        try std.testing.expectEqualDeep(@as([]u8, &expected), @as([]u8, &data));
    }

    {
        var data = [_]u8{ 4, 7, 1, 5, 2 };

        insertionSort(
            @as([]u8, &data),
            ungeneric_order(u8),
        );
        var expected = [_]u8{ 1, 2, 4, 5, 7 };
        try std.testing.expectEqualDeep(@as([]u8, &expected), @as([]u8, &data));
    }
}

/// Sort `data` and copy it to `buffer`
pub fn mergeSort(
    data: anytype,
    buffer: anytype,
    order: fn (
        @typeInfo(@TypeOf(data)).pointer.child,
        @typeInfo(@TypeOf(data)).pointer.child,
    ) Order,
) void {
    const item_type = @typeInfo(@TypeOf(data)).pointer.child;
    const midpoint = data.len / 2;
    if (midpoint == 0) {
        for (data, 0..) |item, index| {
            buffer[index] = item;
        }
        return;
    }

    mergeSort(data[0..midpoint], buffer[0..midpoint], order);
    mergeSort(data[midpoint..data.len], buffer[midpoint..data.len], order);

    merge(item_type, buffer[0..midpoint], buffer[midpoint..data.len], data, order);
    for (data, 0..) |item, index| {
        buffer[index] = item;
    }
}

pub fn merge(
    comptime T: type,
    a: []T,
    b: []T,
    merged: []T,
    order: fn (T, T) Order,
) void {
    var a_index: usize = 0;
    var b_index: usize = 0;
    var index: usize = 0;

    while (a_index < a.len and b_index < b.len) {
        switch (order(a[a_index], b[b_index])) {
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

pub fn ungeneric_order(comptime T: type) fn (T, T) Order {
    return struct {
        fn inner(a: T, b: T) Order {
            return std.math.order(a, b);
        }
    }.inner;
}

test "merge sort works" {
    var data = [_]u8{ 4, 7, 1, 5 };
    var sorted: [4]u8 = undefined;
    mergeSort(
        @as([]u8, &data),
        @as([]u8, &sorted),
        ungeneric_order(u8),
    );
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
        ungeneric_order(u8),
    );
    const expected = [_]u8{ 1, 2, 3, 4, 5, 7 };
    try std.testing.expectEqualDeep(merged, expected);
}

pub fn quickSort(
    data: anytype,
    order: fn (
        @typeInfo(@TypeOf(data)).pointer.child,
        @typeInfo(@TypeOf(data)).pointer.child,
    ) Order,
) void {
    if (data.len < 2) {
        return;
    }

    const item_type = @typeInfo(@TypeOf(data)).pointer.child;
    const p = partition(item_type, data, order);
    quickSort(p[0], order);
    quickSort(p[1], order);
}

pub fn partition(
    comptime T: type,
    data: []T,
    order: fn (T, T) Order,
) struct { []T, []T } {
    std.debug.assert(data.len >= 2);

    const pivot = data[0];

    var less_index: isize = -1;
    var greater_index: usize = data.len;

    while (true) {
        while (true) {
            less_index += 1;
            if (order(data[@bitCast(less_index)], pivot) != .lt) {
                break;
            }
        }

        while (true) {
            greater_index -= 1;
            if (order(data[greater_index], pivot) != .gt) {
                break;
            }
        }

        if (less_index >= greater_index) {
            return .{ data[0..@bitCast(less_index)], data[greater_index + 1 .. data.len] };
        }

        std.mem.swap(T, &data[@bitCast(less_index)], &data[greater_index]);
    }
}

test "quick sort works" {
    {
        var data = [_]u8{ 3, 1, 6, 4, 5, 2 };

        quickSort(
            @as([]u8, &data),
            ungeneric_order(u8),
        );
        var expected = [_]u8{ 1, 2, 3, 4, 5, 6 };
        try std.testing.expectEqualDeep(@as([]u8, &expected), @as([]u8, &data));
    }

    {
        var data = [_]u8{ 4, 7, 1, 5, 2 };

        quickSort(
            @as([]u8, &data),
            ungeneric_order(u8),
        );
        var expected = [_]u8{ 1, 2, 4, 5, 7 };
        try std.testing.expectEqualDeep(@as([]u8, &expected), @as([]u8, &data));
    }
}

pub fn bubbleSort(
    data: anytype,
    order: fn (
        @typeInfo(@TypeOf(data)).pointer.child,
        @typeInfo(@TypeOf(data)).pointer.child,
    ) Order,
) void {
    const item_type = @typeInfo(@TypeOf(data)).pointer.child;

    for (0..data.len - 1) |pass| {
        for (0..data.len - pass - 1) |i| {
            if (order(data[i], data[i + 1]) == .gt) {
                std.mem.swap(item_type, &data[i], &data[i + 1]);
            }
        }
    }
}

test "bubble sort works" {
    var data = [_]u8{ 4, 7, 1, 5, 2 };
    bubbleSort(
        @as([]u8, &data),
        ungeneric_order(u8),
    );
    var expected = [_]u8{ 1, 2, 4, 5, 7 };
    try std.testing.expectEqualDeep(@as([]u8, &expected), @as([]u8, &data));
}
