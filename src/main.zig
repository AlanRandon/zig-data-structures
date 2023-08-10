const std = @import("std");
const HashMap = @import("./hash_map.zig").HashMap;
const BinaryTree = @import("./binary_tree.zig").BinaryTree;
const List = @import("./list.zig").List;
const Thread = std.Thread;

test {
    std.testing.refAllDecls(@This());
    inline for (.{ @import("./list.zig"), @import("./hash_map.zig"), @import("./binary_tree.zig") }) |module| {
        std.testing.refAllDecls(module);
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    {
        var tree = BinaryTree(u64).new(allocator);
        defer tree.deinit();

        inline for (.{ 5, 4, 3, 2, 9 }) |i| {
            try tree.insert(i);
        }

        std.debug.print("{}\n", .{tree});
    }
    _ = gpa.detectLeaks();
}
