const std = @import("std");
const Allocator = std.mem.Allocator;
const Array = @import("./array.zig").Array;
const BitSet = @import("./array.zig").BitSet(u8);
const HashMap = @import("./hash_map.zig").HashMap;
const binarySearch = @import("./search.zig").binarySearch;
const sort = @import("./sort.zig").quickSort;
const insertionSort = @import("./sort.zig").insertionSort;

const Map = HashMap(u8, usize);
const Entry = Map.Entry;

pub const Huffman = struct {
    const BitSetMap = HashMap(u8, BitSet);
    pub const Node = union(enum) {
        leaf: u8,
        branch: struct {
            left: *Node,
            right: *Node,
        },

        fn serialize(node: *const Node, bit_set: *BitSet) !void {
            switch (node.*) {
                .branch => |branch| {
                    try bit_set.push(0);
                    try branch.left.serialize(bit_set);
                    try branch.right.serialize(bit_set);
                },
                .leaf => |value| {
                    try bit_set.push(1);
                    try bit_set.pushInt(u8, value);
                },
            }
        }

        fn deserialize(bit_set: *BitSet.Iter, allocator: Allocator) !*Node {
            const tag = bit_set.next() orelse return error.HuffmanTreeMissingTag;
            const node = try allocator.create(Node);
            errdefer allocator.destroy(node);

            if (tag == 1) {
                node.* = .{ .leaf = bit_set.readInt(u8) orelse return error.HuffmanTreeMissingLeaf };
            } else {
                node.* = .{ .branch = .{
                    .left = try Node.deserialize(bit_set, allocator),
                    .right = try Node.deserialize(bit_set, allocator),
                } };
            }

            return node;
        }

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

        const BuilderTmpNode = struct { previous: ?*const BuilderTmpNode, value: u1 };
        fn addToBitSetMap(node: *const Node, map: *BitSetMap, parent: ?BuilderTmpNode, allocator: Allocator) !void {
            switch (node.*) {
                .leaf => |key| {
                    var set = BitSet.init(allocator);
                    if (parent) |p| {
                        var parent_node: ?*const BuilderTmpNode = &p;
                        while (parent_node) |pn| {
                            try set.push(pn.value);
                            parent_node = pn.previous;
                        }
                        try set.reverse();
                    } else {
                        try set.push(0);
                    }
                    try map.insert(key, set);
                },
                .branch => |tree| {
                    const previous = if (parent) |p| &p else null;
                    try tree.left.addToBitSetMap(map, .{ .previous = previous, .value = 0 }, allocator);
                    try tree.right.addToBitSetMap(map, .{ .previous = previous, .value = 1 }, allocator);
                },
            }
        }
    };

    root: *Node,
    allocator: Allocator,

    const WeightedNode = struct {
        frequency: usize,
        node: *Huffman.Node,
    };

    fn order(a: WeightedNode, b: WeightedNode) std.math.Order {
        return std.math.order(b.frequency, a.frequency);
    }

    pub fn init(data: []const u8, allocator: Allocator) !?Huffman {
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
            errdefer allocator.destroy(node);
            node.* = Huffman.Node{ .leaf = entry.key };
            try frequencies.push(.{ .frequency = entry.value, .node = node });
        }

        sort(frequencies.slice(), order);

        while (true) {
            if (frequencies.pop()) |a| {
                if (frequencies.pop()) |b| {
                    const node = try allocator.create(Huffman.Node);
                    errdefer allocator.destroy(node);
                    node.* = Huffman.Node{ .branch = .{
                        .left = a.node,
                        .right = b.node,
                    } };

                    try frequencies.push(.{ .frequency = a.frequency + b.frequency, .node = node });

                    // TODO: this isn't very fun to be doing each iteration
                    insertionSort(frequencies.slice(), order);
                } else {
                    return Huffman{
                        .root = a.node,
                        .allocator = allocator,
                    };
                }
            } else {
                return null;
            }
        }
    }

    pub fn deinit(huffman: *Huffman) void {
        huffman.root.deinit(huffman.allocator);
    }

    pub fn createBitSetMap(self: *const Huffman, allocator: Allocator) !BitSetMap {
        var map = try BitSetMap.init(10, allocator);
        try self.root.addToBitSetMap(&map, null, allocator);
        return map;
    }

    pub fn encode(data: []const u8, allocator: Allocator) !struct { tree: Huffman, data: BitSet } {
        var tree = try Huffman.init(data, allocator) orelse {
            const node = try allocator.create(Node);
            node.* = .{ .leaf = 0 };
            return .{
                .tree = .{ .root = node, .allocator = allocator },
                .data = BitSet.init(allocator),
            };
        };
        errdefer tree.deinit();

        var bit_set_map = try tree.createBitSetMap(allocator);
        defer bit_set_map.deinit();

        defer {
            var map_iter = bit_set_map.iter();
            while (map_iter.next()) |entry| {
                var bin_set = entry.value;
                bin_set.deinit();
            }
        }

        var result = BitSet.init(allocator);
        errdefer result.deinit();
        for (data) |i| {
            const code = bit_set_map.get(i) orelse std.debug.panic("Unexpected character: {}", .{i});
            var it = code.iter();
            while (it.next()) |bit| {
                try result.push(bit);
            }
        }
        return .{ .data = result, .tree = tree };
    }

    pub fn decode(huffman: *const Huffman, it: *BitSet.Iter, allocator: Allocator) ![]u8 {
        switch (huffman.root.*) {
            .branch => |root| {
                var result = try Array(u8).init(allocator);

                var node = root;
                while (it.next()) |bit| {
                    const n = if (bit == 0) node.left else node.right;
                    switch (n.*) {
                        .branch => |b| {
                            node = b;
                        },
                        .leaf => |value| {
                            try result.push(value);
                            node = root;
                        },
                    }
                } else {}

                return try result.toOwnedSlice();
            },
            .leaf => |value| {
                const result = try allocator.alloc(u8, it.remaining());
                @memset(result, value);
                return result;
            },
        }
    }

    pub fn encodeAndSerialize(data: []const u8, allocator: Allocator) ![]u8 {
        var encoding = try Huffman.encode(data, allocator);
        defer encoding.tree.deinit();
        defer encoding.data.deinit();

        var bit_set = BitSet.init(allocator);
        try encoding.tree.root.serialize(&bit_set);
        try bit_set.pushInt(u32, @intCast(encoding.data.length));

        var it = encoding.data.iter();
        while (it.next()) |i| {
            try bit_set.push(i);
        }

        return bit_set.data;
    }

    pub fn deserializeData(data: []const u8, allocator: Allocator) ![]u8 {
        // TODO: This is dangerous
        var bit_set = BitSet.fromSlice(@constCast(data), allocator);
        var it = bit_set.iter();

        var tree = Huffman{
            .root = try Huffman.Node.deserialize(&it, allocator),
            .allocator = allocator,
        };
        defer tree.deinit();

        const length = it.readInt(u32) orelse return error.HuffmanMissingLength;
        bit_set.length = it.index + length;
        return try tree.decode(&it, allocator);
    }
};

test "huffman serializes" {
    for ([_][]const u8{
        "Hello World!",
        "AAAAAAAA",
        "",
        \\According to all known laws
        \\of aviation,
        \\
        \\there is no way a bee
        \\should be able to fly.
    }) |data| {
        const encoded = try Huffman.encodeAndSerialize(data, std.testing.allocator);
        defer std.testing.allocator.free(encoded);

        const decoded = try Huffman.deserializeData(encoded, std.testing.allocator);
        defer std.testing.allocator.free(decoded);

        try std.testing.expectEqualDeep(data, decoded);
    }
}

test "huffman encodes" {
    for ([_][]const u8{
        "Hello World!",
        "AAAAAAAA",
        "",
        \\According to all known laws
        \\of aviation,
        \\
        \\there is no way a bee
        \\should be able to fly.
    }) |data| {
        var encoding = try Huffman.encode(data, std.testing.allocator);
        defer encoding.tree.deinit();
        defer encoding.data.deinit();

        var it = encoding.data.iter();
        const decoded = try encoding.tree.decode(&it, std.testing.allocator);
        defer std.testing.allocator.free(decoded);

        try std.testing.expectEqualDeep(decoded, data);
    }
}

test "huffman fuzz" {
    const data = std.testing.fuzzInput(.{});
    var encoding = try Huffman.encode(data, std.testing.allocator);
    defer encoding.tree.deinit();
    defer encoding.data.deinit();

    var it = encoding.data.iter();
    const decoded = try encoding.tree.decode(&it, std.testing.allocator);
    defer std.testing.allocator.free(decoded);

    try std.testing.expectEqualDeep(decoded, data);
}

pub fn usage() noreturn {
    _ = std.io.getStdErr().writer().print("USAGE: huffman compress|decompress INPUT OUTPUT\n", .{}) catch unreachable;
    std.process.exit(1);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    {
        var args = std.process.args();
        _ = args.next();

        const command = if (args.next()) |command| command else usage();
        const input = if (args.next()) |path| try std.fs.cwd().openFile(path, .{}) else usage();
        defer input.close();

        const output = if (args.next()) |path| try std.fs.cwd().createFile(path, .{}) else usage();
        defer output.close();

        if (std.mem.eql(u8, command, "compress")) {
            const data = try input.readToEndAlloc(allocator, 1_000_000);
            defer allocator.free(data);

            const encoded = try Huffman.encodeAndSerialize(data, allocator);
            defer allocator.free(encoded);

            try output.writeAll(encoded);

            std.debug.print("{} -> {} ({}%)\n", .{
                data.len,
                encoded.len,
                encoded.len * 100 / data.len,
            });
        } else if (std.mem.eql(u8, command, "decompress")) {
            const data = try input.readToEndAlloc(allocator, 1_000_000);
            defer allocator.free(data);

            const decoded = try Huffman.deserializeData(data, allocator);
            defer allocator.free(decoded);

            try output.writeAll(decoded);
        } else usage();
    }
    _ = gpa.detectLeaks();
}
