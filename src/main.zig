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
        const file = try std.fs.cwd().openFile("src/huffman.zig", .{});
        defer file.close();

        const data = try file.readToEndAlloc(allocator, 1_000_000);
        defer allocator.free(data);

        var encoding = try huffman.Huffman.encode(data, allocator);
        defer encoding.tree.deinit();
        defer encoding.data.deinit();

        const decoding = try huffman.Huffman.decode(&encoding.tree, &encoding.data, allocator);
        defer allocator.free(decoding);

        std.debug.print("{} -> {} ({}%)\n", .{
            encoding.data.length,
            decoding.len,
            decoding.len * 100 / encoding.data.length,
        });
    }
    _ = gpa.detectLeaks();
}
