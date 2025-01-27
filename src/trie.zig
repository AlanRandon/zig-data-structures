const std = @import("std");
const Allocator = std.mem.Allocator;
const Array = @import("./array.zig").Array;

pub fn Trie(comptime K: type, comptime V: type) type {
    return struct {
        root: Node,
        allocator: Allocator,

        const Key = []const K;
        const Self = @This();

        const PrefixedNode = struct {
            prefix: Key,
            node: *Node,
        };

        const Node = struct {
            children: Array(PrefixedNode),
            value: ?V,

            pub fn deinit(node: *Node, allocator: Allocator) void {
                for (node.children.slice()) |child| {
                    child.node.deinit(allocator);
                    allocator.destroy(child.node);
                }

                node.children.deinit();
            }

            pub fn debug(node: *Node, depth: usize) void {
                std.debug.print("{?}\n", .{node.value});

                for (node.children.slice()) |child| {
                    std.debug.print("{s}{s} --> ", .{ ([_]u8{'\t'} ** 1000)[0 .. depth + 1], child.prefix });
                    child.node.debug(depth + 1);
                }
            }
        };

        pub fn init(allocator: Allocator) !Self {
            return .{
                .root = .{ .children = try Array(PrefixedNode).init(allocator), .value = null },
                .allocator = allocator,
            };
        }

        pub fn deinit(trie: *Self) void {
            trie.root.deinit(trie.allocator);
        }

        pub fn isPrefix(key: Key, prefix: Key) bool {
            if (prefix.len > key.len) {
                return false;
            }

            return std.mem.eql(K, prefix, key[0..prefix.len]);
        }

        pub fn longestCommonPrefix(a: Key, b: Key) Key {
            var prefix: Key = a[0..0];
            for (0..a.len) |i| {
                if (i >= b.len or a[i] != b[i]) {
                    return prefix;
                }
                prefix = a[0 .. i + 1];
            }
            return prefix;
        }

        pub fn get(trie: *Self, key: Key) ?V {
            if (key.len == 0) {
                return trie.root.value;
            }

            var node = &trie.root;
            var suffix = key;
            outer: while (true) {
                for (node.children.slice()) |prefix| {
                    if (isPrefix(suffix, prefix.prefix)) {
                        node = prefix.node;
                        suffix = suffix[prefix.prefix.len..];
                        if (suffix.len == 0) {
                            return node.value;
                        }

                        continue :outer;
                    }
                }

                return null;
            }
        }

        pub fn insert(trie: *Self, key: Key, value: V) !void {
            if (key.len == 0) {
                trie.root.value = value;
                return;
            }

            var node = &trie.root;
            var suffix = key;
            outer: while (true) {
                for (node.children.slice()) |*prefix| {
                    const common_prefix = longestCommonPrefix(suffix, prefix.prefix);
                    suffix = suffix[common_prefix.len..];

                    if (common_prefix.len == prefix.prefix.len) {
                        node = prefix.node;
                        if (suffix.len == 0) {
                            node.value = value;
                            return;
                        }
                        continue :outer;
                    }

                    if (common_prefix.len != 0 and common_prefix.len < prefix.prefix.len) {
                        const common_prefix_node = prefix.node;
                        var common_prefix_children = try Array(PrefixedNode).init(trie.allocator);
                        errdefer common_prefix_children.deinit();

                        const old_prefix_node = try trie.allocator.create(Node);
                        errdefer trie.allocator.destroy(common_prefix_node);
                        old_prefix_node.* = .{ .children = common_prefix_node.children, .value = common_prefix_node.value };
                        try common_prefix_children.push(.{ .prefix = prefix.prefix[common_prefix.len..], .node = old_prefix_node });

                        common_prefix_node.children = common_prefix_children;
                        common_prefix_node.value = null;
                        prefix.prefix = common_prefix;
                        node = common_prefix_node;

                        if (suffix.len == 0) {
                            common_prefix_node.value = value;
                            return;
                        } else break;
                    }
                }

                const created_node = try trie.allocator.create(Node);
                errdefer trie.allocator.destroy(created_node);
                var children = try Array(PrefixedNode).init(trie.allocator);
                errdefer children.deinit();
                created_node.* = .{ .children = children, .value = value };
                try node.children.push(.{ .prefix = suffix, .node = created_node });
                return;
            }
        }
    };
}

test Trie {
    var trie = try Trie(u8, usize).init(std.testing.allocator);
    defer trie.deinit();

    try trie.insert("", 0);
    try std.testing.expectEqual(trie.get(""), 0);

    try trie.insert("tested", 1);
    try std.testing.expectEqual(trie.get("tested"), 1);

    try trie.insert("testing", 2);
    try std.testing.expectEqual(trie.get("testing"), 2);

    try trie.insert("test", 3);
    try std.testing.expectEqual(trie.get("test"), 3);

    try trie.insert("hello", 4);
    try std.testing.expectEqual(trie.get("hello"), 4);

    try trie.insert("tea", 5);
    try std.testing.expectEqual(trie.get("tea"), 5);
}
