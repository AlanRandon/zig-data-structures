const std = @import("std");

pub const hash_map = @import("./hash_map.zig");
pub const binary_tree = @import("./binary_tree.zig");
pub const array = @import("./array.zig");
pub const linked_list = @import("./linked_list.zig");
pub const stack = @import("./stack.zig");
pub const memoize = @import("./memoize.zig");
pub const sort = @import("./sort.zig");
pub const search = @import("./search.zig");
pub const huffman = @import("./huffman.zig");
pub const bin_packing = @import("./bin_packing.zig");
pub const queue = @import("./queue.zig");
pub const graph = @import("./graph.zig");
pub const powerset = @import("./powerset.zig");
pub const trie = @import("./trie.zig");

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
        powerset,
        trie,
    };
    std.testing.refAllDeclsRecursive(@This());
}
