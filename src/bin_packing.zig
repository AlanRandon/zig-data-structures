const std = @import("std");
const Allocator = std.mem.Allocator;
const sort = @import("./sort.zig").quickSort;
const order = @import("./sort.zig").ungeneric_order(usize);
const Array = @import("./array.zig").Array(usize);

pub fn firstFit(groups: []const usize, bin_size: usize, allocator: Allocator) !Array {
    var bins = try Array.init(allocator);

    grp: for (groups) |group| {
        std.debug.assert(group <= bin_size);

        for (bins.slice()) |*bin| {
            if (bin.* + group <= bin_size) {
                bin.* += group;
                continue :grp;
            }
        }

        try bins.push(group);
    }

    return bins;
}

test "first fit" {
    var groups = [_]usize{ 3, 1, 6, 4, 5, 2 };
    var bins = try firstFit(&groups, 7, std.testing.allocator);
    defer bins.deinit();
    try std.testing.expectEqual(4, bins.length);
}

pub fn firstFitDecreasing(groups: []usize, bin_size: usize, allocator: Allocator) !Array {
    sort(
        groups,
        struct {
            fn order(a: usize, b: usize) std.math.Order {
                return std.math.order(b, a);
            }
        }.order,
    );

    var bins = try Array.init(allocator);

    grp: for (groups) |group| {
        std.debug.assert(group <= bin_size);

        for (bins.slice()) |*bin| {
            if (bin.* + group <= bin_size) {
                bin.* += group;
                continue :grp;
            }
        }

        try bins.push(group);
    }

    return bins;
}

test "first fit decreasing" {
    {
        var groups = [_]usize{ 3, 1, 6, 4, 5, 2 };
        var bins = try firstFitDecreasing(&groups, 7, std.testing.allocator);
        defer bins.deinit();
        try std.testing.expectEqual(3, bins.length);
    }

    {
        var groups = [_]usize{ 100, 80, 60, 65, 110, 25, 50, 60, 90, 140, 75, 120, 75, 100, 70, 200, 120, 40 };
        var bins = try firstFitDecreasing(&groups, 400, std.testing.allocator);
        defer bins.deinit();
        try std.testing.expectEqual(4, bins.length);
    }
}

pub fn lowerBound(groups: []usize, bin_size: usize) usize {
    var sum: usize = 0;
    for (groups) |group| {
        sum += group;
    }

    return (sum + bin_size - 1) / bin_size;
}
