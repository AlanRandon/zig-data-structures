const std = @import("std");
const hash_map = @import("./hash_map.zig");
const binary_tree = @import("./binary_tree.zig");
const array = @import("./array.zig");
const linked_list = @import("./linked_list.zig");
const stack = @import("./stack.zig");
const memoize = @import("./memoize.zig");
const sort = @import("./sort.zig");
const search = @import("./search.zig");
const huffman = @import("./huffman.zig");
const bin_packing = @import("./bin_packing.zig");

test {
    _ = .{
        huffman,
        hash_map,
        binary_tree,
        array,
        linked_list,
        stack,
        memoize,
        sort,
        search,
        bin_packing,
    };
    std.testing.refAllDeclsRecursive(@This());
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    {
        var groups = [_]usize{ 12, 30, 4, 6, 28, 20, 18, 3, 20, 8, 9, 10 };
        const bin_size = 50;

        std.debug.print("lowerBound: {}\n", .{bin_packing.lowerBound(&groups, bin_size)});
        {
            var bins = try bin_packing.firstFit(&groups, bin_size, allocator);
            defer bins.deinit();

            std.debug.print("firstFit: {any}\n", .{bins.slice()});
        }

        {
            var bins = try bin_packing.firstFitDecreasing(&groups, bin_size, allocator);
            defer bins.deinit();

            std.debug.print("firstFitDecreasing: {any}\n", .{bins.slice()});
        }
    }
    _ = gpa.detectLeaks();
}
