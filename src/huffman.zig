const std = @import("std");
const Allocator = std.mem.Allocator;
const Array = @import("./array.zig").Array;
const HashMap = @import("./hash_map.zig").HashMap;
const binarySearch = @import("./search.zig").binarySearch;
const sort = @import("./sort.zig").quickSort;
const insertionSort = @import("./sort.zig").insertionSort;

const Map = HashMap(u8, usize);
const Entry = Map.Entry;

pub const Huffman = struct {
    pub const Node = union(enum) {
        leaf: u8,
        branch: struct {
            left: *Node,
            right: *Node,
        },

        pub fn deinit(node: *Node, allocator: Allocator) void {
            defer allocator.destroy(node);
            switch (node.*) {
                .branch => |branch| {
                    branch.left.deinit(allocator);
                    branch.right.deinit(allocator);
                },
                .leaf => {},
            }
        }

        fn dbg(node: *Node, depth: usize) void {
            for (0..depth) |_| {
                std.debug.print("\t", .{});
            }
            std.debug.print("node:", .{});
            switch (node.*) {
                .branch => |branch| {
                    std.debug.print("\n", .{});
                    branch.left.dbg(depth + 1);
                    branch.right.dbg(depth + 1);
                },
                .leaf => |value| {
                    std.debug.print(" '{s}'\n", .{&[_]u8{value}});
                },
            }
        }
    };

    root: *Node,
};

const WeightedNode = struct {
    frequency: usize,
    node: *Huffman.Node,
};

fn order(a: WeightedNode, b: WeightedNode) std.math.Order {
    return std.math.order(b.frequency, a.frequency);
}

pub fn encode(data: []const u8, allocator: Allocator) !?*Huffman.Node {
    var frequency_map = try Map.init(26, allocator);
    defer frequency_map.deinit();

    for (data) |item| {
        if (frequency_map.getPtr(item)) |frequency| {
            frequency.* += 1;
        } else {
            try frequency_map.insert(item, 1);
        }
    }

    var frequencies = try Array(WeightedNode).withCapacity(frequency_map.entries, allocator);
    defer frequencies.deinit();

    var it = frequency_map.iter();
    while (it.next()) |entry| {
        const node = try allocator.create(Huffman.Node);
        node.* = Huffman.Node{ .leaf = entry.key };
        try frequencies.push(.{ .frequency = entry.value, .node = node });
    }

    sort(frequencies.slice(), order);

    while (true) {
        if (frequencies.pop()) |a| {
            if (frequencies.pop()) |b| {
                const node = try allocator.create(Huffman.Node);
                node.* = Huffman.Node{ .branch = .{
                    .left = a.node,
                    .right = b.node,
                } };

                try frequencies.push(.{ .frequency = a.frequency + b.frequency, .node = node });
                insertionSort(frequencies.slice(), order);
            } else {
                return a.node;
            }
        } else {
            return null;
        }
    }
}

test "huffman encodes" {
    const data = "Hello World";
    var node = (try encode(data, std.testing.allocator)).?;
    defer node.deinit(std.testing.allocator);

    node.dbg(0);
}
