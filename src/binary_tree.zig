const std = @import("std");
const Allocator = std.mem.Allocator;

const RedBlackTreeColor = enum {
    red,
    black,
};

pub fn lessThan(a: anytype, b: anytype) bool {
    return switch (@typeInfo(@TypeOf(a))) {
        .Pointer => |ptr| std.mem.lessThan(ptr.child, a, b),
        else => a < b,
    };
}

pub fn RedBlackTreeMap(comptime K: type, comptime V: type) type {
    return struct {
        const Node = struct {
            color: RedBlackTreeColor,
            key: K,
            value: V,
            left: ?*Node,
            right: ?*Node,

            fn deinit(self: Node, allocator: Allocator) void {
                if (self.left) |left| {
                    left.deinit(allocator);
                    allocator.destroy(left);
                }

                if (self.right) |right| {
                    right.deinit(allocator);
                    allocator.destroy(right);
                }
            }
        };
        const Self = @This();

        root: ?*Node,
        allocator: Allocator,

        pub fn init(allocator: Allocator) Self {
            return .{
                .root = null,
                .allocator = allocator,
            };
        }

        pub fn insert(self: *Self, key: K, value: V) !void {
            const node = try self.allocator.create(Node);
            node.* = .{
                .key = key,
                .value = value,
                .color = .black,
                .left = null,
                .right = null,
            };

            if (self.root) |root| {
                node.color = .red;
                var parent = root;
                while (true) {
                    if (lessThan(node.key, parent.key)) {
                        parent = parent.left orelse {
                            parent.left = node;
                            break;
                        };
                    } else {
                        parent = parent.right orelse {
                            parent.right = node;
                            break;
                        };
                    }
                }

                self.rebalance();
            } else {
                self.root = node;
            }
        }

        fn rebalance(self: *Self) void {
            _ = self;
            @panic("TODO: rebalance");
        }

        pub fn deinit(self: *Self) void {
            if (self.root) |root| {
                root.deinit(self.allocator);
                self.allocator.destroy(root);
            }
        }

        fn jsonStringifyNode(
            self: Self,
            jws: anytype,
            node: *Node,
        ) !void {
            if (node.left) |left| {
                try self.jsonStringifyNode(jws, left);
            }

            try jws.objectField(node.key);
            try jws.write(node.value);

            if (node.right) |right| {
                try self.jsonStringifyNode(jws, right);
            }
        }

        pub fn jsonStringify(self: Self, jws: anytype) !void {
            try jws.beginObject();
            if (self.root) |root| {
                try self.jsonStringifyNode(jws, root);
            }
            try jws.endObject();
        }
    };
}

test "binary tree works" {
    const allocator = std.testing.allocator;
    var map = RedBlackTreeMap([]const u8, u8).init(allocator);
    defer map.deinit();

    inline for (.{ .{ "one", 1 }, .{ "two", 2 } }) |entry| {
        try map.insert(entry.@"0", entry.@"1");
        // try std.testing.expectEqual(
        //     map.get(entry.@"0").?,
        //     entry.@"1",
        // );
    }

    const json = try std.json.stringifyAlloc(allocator, map, .{});
    try std.testing.expectEqualDeep(json, "{\"one\":1,\"two\":2}");
    allocator.free(json);

    // try std.testing.expectEqual(tree.min(), 2);
    // try std.testing.expectEqual(tree.max(), 9);
}
