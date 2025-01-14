const std = @import("std");
const Allocator = std.mem.Allocator;
const sort = @import("./sort.zig").quickSort;
const order = @import("./sort.zig").ungeneric_order(usize);
const Array = @import("./array.zig").Array;

pub fn firstFit(comptime T: type, items: []const T, bin_size: usize, allocator: Allocator) !Bins(T) {
    var bins = Bins(T){
        .bins = try Array(Bins(T).Bin).init(allocator),
    };
    errdefer bins.deinit();

    outer: for (items) |item| {
        std.debug.assert(size(item) <= bin_size);

        for (bins.bins.slice()) |*bin| {
            if (bin.used_space + size(item) <= bin_size) {
                try bin.items.push(item);
                bin.used_space += size(item);
                continue :outer;
            }
        }

        var bin_items = try Array(T).init(allocator);
        errdefer bin_items.deinit();

        try bin_items.push(item);

        try bins.bins.push(.{
            .items = bin_items,
            .used_space = size(item),
        });
    }

    return bins;
}

test "first fit" {
    var groups = [_]u8{ 3, 1, 6, 4, 5, 2 };
    var bins = try firstFit(u8, &groups, 7, std.testing.allocator);
    defer bins.deinit();
    try std.testing.expectEqual(4, bins.bins.length);
}

pub fn firstFitDecreasing(comptime T: type, items: []T, bin_size: usize, allocator: Allocator) !Bins(T) {
    sort(
        items,
        struct {
            fn order(a: T, b: T) std.math.Order {
                return std.math.order(size(b), size(a));
            }
        }.order,
    );

    return firstFit(T, items, bin_size, allocator);
}

test "first fit decreasing" {
    {
        var groups = [_]u8{ 3, 1, 6, 4, 5, 2 };
        var bins = try firstFitDecreasing(u8, &groups, 7, std.testing.allocator);
        defer bins.deinit();
        try std.testing.expectEqual(3, bins.bins.length);
    }

    {
        var groups = [_]u8{ 100, 80, 60, 65, 110, 25, 50, 60, 90, 140, 75, 120, 75, 100, 70, 200, 120, 40 };
        var bins = try firstFitDecreasing(u8, &groups, 400, std.testing.allocator);
        defer bins.deinit();
        try std.testing.expectEqual(4, bins.bins.length);
    }
}

pub fn lowerBound(groups: anytype, bin_size: usize) usize {
    var sum: usize = 0;
    for (groups) |group| {
        sum += size(group);
    }

    return (sum + bin_size - 1) / bin_size;
}

pub fn size(item: anytype) usize {
    const T = @TypeOf(item);
    return switch (@typeInfo(T)) {
        .int => @intCast(item),
        else => if (std.meta.hasMethod(T, "size")) {
            return item.size();
        } else {
            return item.size;
        },
    };
}

pub fn Bins(comptime T: type) type {
    return struct {
        bins: Array(Bin),

        const Bin = struct {
            items: Array(T),
            used_space: usize,
        };

        const Self = @This();

        pub fn deinit(bins: *Self) void {
            for (bins.bins.slice()) |*bin| {
                bin.items.deinit();
            }
            bins.bins.deinit();
        }
    };
}

pub fn fullFit(comptime T: type, items: []const T, bin_size: usize, allocator: Allocator) !Bins(T) {
    for (0..std.math.pow(usize, 2, items.len)) |mask| {
        var total: usize = 0;

        for (0..items.len) |i| {
            if (mask >> @intCast(i) & 1 == 1) {
                total += size(items[i]);
            }
        }

        if (total == bin_size) {
            var bin_items = try Array(T).withCapacity(@popCount(mask), allocator);
            errdefer bin_items.deinit();

            var other_items = try Array(T).withCapacity(items.len - @popCount(mask), allocator);
            defer other_items.deinit();

            for (0..items.len) |i| {
                if (mask >> @intCast(i) & 1 == 1) {
                    try bin_items.push(items[i]);
                } else {
                    try other_items.push(items[i]);
                }
            }

            var bins = try fullFit(T, other_items.slice(), bin_size, allocator);
            errdefer bins.deinit();

            try bins.bins.push(.{
                .used_space = bin_size,
                .items = bin_items,
            });

            return bins;
        }
    }

    return firstFit(T, items, bin_size, allocator);
}

test "full fit works" {
    var items = [_]u8{ 2, 6, 4, 9, 8, 8, 2, 5, 2 };
    var bins = try fullFit(u8, &items, 10, std.testing.allocator);
    defer bins.deinit();
    try std.testing.expectEqual(5, bins.bins.length);
}
