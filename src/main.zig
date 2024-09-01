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
    };
    std.testing.refAllDeclsRecursive(@This());
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    {
        var tree = binary_tree.RedBlackTreeMap(
            u64,
            []const u8,
        ).init(allocator);
        defer tree.deinit();

        // inline for (.{ 5, 4, 3, 2, 9 }) |i| {
        //     try tree.insert(i);
        // }

        // std.debug.print("{}\n", .{tree});
    }
    _ = gpa.detectLeaks();
}
