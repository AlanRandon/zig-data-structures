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
const queue = @import("./queue.zig");
const graph = @import("./graph.zig");

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
        queue,
        graph,
    };
    std.testing.refAllDeclsRecursive(@This());
}
