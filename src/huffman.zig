const std = @import("std");
const Allocator = std.mem.Allocator;
const Array = @import("./array.zig").Array;
const binarySearch = @import("./search.zig").binarySearch;
const sort = @import("./sort.zig").mergeSort;

pub const Huffman = struct {
    pub const Node = union(enum) {
        leaf: u8,
        branch: struct {
            left: *Node,
            right: *Node,
        },
    };

    root: Node,
};

const Pair = struct { key: u8, frequency: usize };

pub fn encode(data: []const u8, allocator: Allocator) !void {
    var frequency = try Array(Pair).init(allocator);

    for (data) |value| {
        std.debug.print("{any}\n", .{frequency.slice()});
        if (binarySearch(
            Pair,
            frequency.data,
            struct {
                value: u8,

                pub fn order(self: *const @This(), pair: Pair) std.math.Order {
                    return std.math.order(self.value, pair.key);
                }
            }{ .value = value },
        )) |f| {
            f.frequency += 1;
        } else {
            try frequency.push(.{ .key = value, .frequency = 1 });
            const f = try allocator.alloc(Pair, frequency.data.len);
            sort(frequency.slice(), f, struct {
                fn order(a: Pair, b: Pair) std.math.Order {
                    return std.math.order(a.key, b.key);
                }
            }.order);
            allocator.free(frequency.data);
            frequency.data = f;
        }
    }

    @panic("TODO");
}

// test "huffman encodes" {
//     const data = "Hello World";
//     try encode(data, std.testing.allocator);
// }
