const std = @import("std");
const hash_map = @import("./hash_map.zig");
const binary_tree = @import("./binary_tree.zig");
const list = @import("./list.zig");
const linked_list = @import("./linked_list.zig");

test {
    _ = .{ hash_map, binary_tree, list, linked_list };
    std.testing.refAllDeclsRecursive(@This());
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    {
        var tree = binary_tree.BinaryTree(u64).new(allocator);
        defer tree.deinit();

        inline for (.{ 5, 4, 3, 2, 9 }) |i| {
            try tree.insert(i);
        }

        std.debug.print("{}\n", .{tree});
    }
    _ = gpa.detectLeaks();
}
