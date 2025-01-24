const std = @import("std");
const Stack = @import("./stack.zig").Stack;
const Allocator = std.mem.Allocator;

const Color = enum { red, black };
const Direction = enum { left, right };

pub fn RedBlackTree(comptime T: type, comptime orderFn: fn (T, T) std.math.Order) type {
    return struct {
        root: ?*Node,
        allocator: Allocator,

        const Self = @This();

        const Node = struct {
            data: T,
            parent: ?*Node,
            left: ?*Node,
            right: ?*Node,
            color: Color,

            fn min(node: *const Node) *const Node {
                var current_node = node;
                while (true) {
                    current_node = current_node.left orelse return current_node;
                }
            }

            fn minMut(node: *Node) *Node {
                var current_node = node;
                while (true) {
                    current_node = current_node.left orelse return current_node;
                }
            }

            fn max(node: *const Node) *const Node {
                var current_node = node;
                while (true) {
                    current_node = current_node.right orelse return current_node;
                }
            }

            pub fn deinit(node: *Node, allocator: Allocator) void {
                if (node.left) |left| {
                    left.deinit(allocator);
                    allocator.destroy(left);
                }

                if (node.right) |right| {
                    right.deinit(allocator);
                    allocator.destroy(right);
                }
            }

            pub fn debug(node: *const Node, depth: usize) void {
                if (node.left) |left| left.debug(depth + 1);
                std.debug.print("{s}{} ({}) <-- {?}\n", .{
                    ([_]u8{'\t'} ** 1000)[0..depth],
                    node.data,
                    node.color,
                    if (node.parent) |p| p.data else null,
                });
                if (node.right) |right| right.debug(depth + 1);
            }

            pub fn assertNoViolations(node: *const Node) usize {
                const left_black_nodes = if (node.left) |left| left.assertNoViolations() else 0;
                const right_black_nodes = if (node.right) |right| right.assertNoViolations() else 0;
                std.debug.assert(left_black_nodes == right_black_nodes);

                if (node.left) |left| std.debug.assert(left.parent == node);
                if (node.right) |right| std.debug.assert(right.parent == node);

                switch (node.color) {
                    .red => {
                        if (node.left) |left| {
                            std.debug.assert(left.color == .black);
                        }

                        if (node.right) |right| {
                            std.debug.assert(right.color == .black);
                        }

                        return left_black_nodes;
                    },
                    .black => return left_black_nodes + 1,
                }
            }

            pub fn side(node: *const Node) union(enum) { left: *Node, right: *Node, root } {
                if (node.parent) |parent| (if (parent.left == node) {
                    return .{ .left = parent };
                } else if (parent.right == node) {
                    return .{ .right = parent };
                } else std.debug.panic("node must be child of own parent", .{})) else {
                    return .root;
                }
            }

            pub fn sibling(node: *Node) *Node {
                return switch (node.side()) {
                    .left => |parent| parent.right.?,
                    .right => |parent| parent.left.?,
                    .root => std.debug.panic("cannot get sibling of root", .{}),
                };
            }
        };

        pub fn deinit(tree: *Self) void {
            if (tree.root) |root| {
                root.deinit(tree.allocator);
                tree.allocator.destroy(root);
            }
        }

        pub fn init(allocator: Allocator) Self {
            return .{
                .root = null,
                .allocator = allocator,
            };
        }

        pub fn max(tree: *const Self) ?*const Node {
            return (tree.root orelse return null).max();
        }

        pub fn min(tree: *const Self) ?*const Node {
            return (tree.root orelse return null).min();
        }

        pub fn find(tree: *const Self, data: T) ?*Node {
            var node = tree.root orelse return null;
            while (true) {
                switch (orderFn(data, node.data)) {
                    .lt => node = node.left orelse return null,
                    .gt => node = node.right orelse return null,
                    .eq => return node,
                }
            }
        }

        pub fn insert(tree: *Self, data: T) !void {
            var parent = tree.root orelse {
                const node = try tree.allocator.create(Node);
                node.* = .{
                    .data = data,
                    .parent = null,
                    .left = null,
                    .right = null,
                    .color = .black,
                };
                tree.root = node;
                return;
            };

            const node = try tree.allocator.create(Node);
            errdefer tree.allocator.destroy(node);
            node.* = .{
                .data = data,
                .parent = undefined,
                .left = null,
                .right = null,
                .color = .red,
            };

            while (true) {
                if (orderFn(data, parent.data) == .lt) {
                    parent = parent.left orelse {
                        node.parent = parent;
                        parent.left = node;
                        break;
                    };
                } else {
                    parent = parent.right orelse {
                        node.parent = parent;
                        parent.right = node;
                        break;
                    };
                }
            }

            tree.fixInsert(node);
        }

        fn fixInsert(tree: *Self, node: *Node) void {
            var current_node = node;
            while (current_node != tree.root and current_node.parent.?.color == .red) {
                const parent = current_node.parent.?;
                const grandparent = parent.parent.?;

                if (parent == grandparent.left) {
                    const uncle = grandparent.right;
                    if (uncle != null and uncle.?.color == .red) {
                        uncle.?.color = .black;
                        parent.color = .black;
                        grandparent.color = .red;
                        current_node = grandparent;
                    } else {
                        if (current_node == parent.right) {
                            current_node = parent;
                            tree.leftRotate(current_node);
                        }

                        current_node.parent.?.color = .black;
                        current_node.parent.?.parent.?.color = .red;
                        tree.rightRotate(current_node.parent.?.parent.?);
                    }
                } else if (parent == grandparent.right) {
                    const uncle = grandparent.left;
                    if (uncle != null and uncle.?.color == .red) {
                        uncle.?.color = .black;
                        parent.color = .black;
                        grandparent.color = .red;
                        current_node = grandparent;
                    } else {
                        if (current_node == parent.left) {
                            current_node = parent;
                            tree.rightRotate(current_node);
                        }

                        current_node.parent.?.color = .black;
                        current_node.parent.?.parent.?.color = .red;
                        tree.leftRotate(current_node.parent.?.parent.?);
                    }
                } else {
                    std.debug.panic("parent must be child of grandparent", .{});
                }
            }

            tree.root.?.color = .black;
        }

        fn leftRotate(tree: *Self, node: *Node) void {
            //   n
            // l   r
            //    1 2
            // -->
            //    r
            //  n   2
            // l 1

            const right_child = node.right.?;

            // put r.left in place of n.right
            node.right = right_child.left;
            if (right_child.left) |left| {
                left.parent = node;
            }

            // put n.right in place of n
            right_child.parent = node.parent;
            switch (node.side()) {
                .left => |parent| parent.left = right_child,
                .right => |parent| parent.right = right_child,
                .root => tree.root = right_child,
            }

            right_child.left = node;
            node.parent = right_child;
        }

        fn rightRotate(tree: *Self, node: *Node) void {
            //    n
            //  l   r
            // 1 2
            // -->
            //   l
            // 1   n
            //    2 r

            const left_child = node.left.?;

            // put l.right in place of n.left
            node.left = left_child.right;
            if (left_child.right) |right| {
                right.parent = node;
            }

            // put n.left in place of n
            left_child.parent = node.parent;
            switch (node.side()) {
                .left => |parent| parent.left = left_child,
                .right => |parent| parent.right = left_child,
                .root => tree.root = left_child,
            }

            left_child.right = node;
            node.parent = left_child;
        }

        pub fn deleteNodeWithZeroOrOneChildren(tree: *Self, nil_node: *Node, node: *Node) ?*Node {
            defer tree.allocator.destroy(node);

            var moved_up_node: ?*Node = undefined;

            if (node.left) |left| {
                moved_up_node = left;
            } else if (node.right) |right| {
                moved_up_node = right;
            } else if (node.color == .black) {
                moved_up_node = nil_node;
            } else {
                moved_up_node = null;
            }

            switch (node.side()) {
                .left => |parent| parent.left = moved_up_node,
                .right => |parent| parent.right = moved_up_node,
                .root => tree.root = moved_up_node,
            }

            if (moved_up_node) |moved| {
                moved.parent = node.parent;
            }

            return moved_up_node;
        }

        pub fn delete(tree: *Self, node: *Node) void {
            var deleted_node_color: Color = undefined;
            var moved_up_node: ?*Node = undefined;
            var nil_node = Node{
                .parent = undefined,
                .right = null,
                .left = null,
                .color = .black,
                .data = undefined,
            };

            if (node.left == null or node.right == null) {
                deleted_node_color = node.color;
                moved_up_node = tree.deleteNodeWithZeroOrOneChildren(&nil_node, node);
            } else {
                const successor = node.right.?.minMut();
                node.data = successor.data;
                deleted_node_color = successor.color;
                moved_up_node = tree.deleteNodeWithZeroOrOneChildren(&nil_node, successor);
            }

            if (deleted_node_color == .black) {
                tree.fixDelete(moved_up_node.?);

                if (moved_up_node.? == &nil_node) {
                    switch (moved_up_node.?.side()) {
                        .right => |parent| parent.right = null,
                        .left => |parent| parent.left = null,
                        .root => tree.root = null,
                    }
                }
            }
        }

        pub fn isBlackOrNull(node: ?*Node) bool {
            return node == null or node.?.color == .black;
        }

        pub fn fixDelete(tree: *Self, node: *Node) void {
            if (node == tree.root) {
                node.color = .black;
                return;
            }

            var parent = node.parent.?;
            var sibling = node.sibling();

            if (sibling.color == .red) {
                sibling.color = .black;
                parent.color = .red;

                switch (node.side()) {
                    .left => tree.leftRotate(parent),
                    .right => tree.rightRotate(parent),
                    .root => unreachable,
                }

                parent = node.parent.?;
                sibling = node.sibling();
            }

            if (isBlackOrNull(sibling.left) and isBlackOrNull(sibling.right)) {
                sibling.color = .red;
                if (parent.color == .red) {
                    parent.color = .black;
                } else {
                    tree.fixDelete(parent);
                }
            } else {
                switch (node.side()) {
                    .left => if (isBlackOrNull(sibling.right)) {
                        sibling.left.?.color = .black;
                        sibling.color = .red;
                        tree.rightRotate(sibling);
                        sibling = parent.right.?;
                    },
                    .right => if (isBlackOrNull(sibling.left)) {
                        sibling.right.?.color = .black;
                        sibling.color = .red;
                        tree.leftRotate(sibling);
                        sibling = parent.left.?;
                    },
                    .root => unreachable,
                }

                sibling.color = parent.color;
                parent.color = .black;
                switch (node.side()) {
                    .left => {
                        sibling.right.?.color = .black;
                        tree.leftRotate(parent);
                    },
                    .right => {
                        sibling.left.?.color = .black;
                        tree.rightRotate(parent);
                    },
                    .root => unreachable,
                }
            }
        }

        pub const Iter = struct {
            node: ?*Node,
            parents: Stack(*Node),

            pub fn next(it: *Iter) !?T {
                if (it.node) |n| {
                    var node = n;
                    while (true) {
                        if (node.left) |left| {
                            try it.parents.push(node);
                            node = left;
                        } else {
                            it.node = node.right;
                            return node.data;
                        }
                    }
                } else {
                    const node = it.parents.pop() orelse return null;
                    it.node = node.right;
                    return node.data;
                }
            }

            pub fn deinit(it: *Iter) void {
                it.parents.deinit();
            }
        };

        pub fn iter(tree: *const Self, allocator: Allocator) !Iter {
            return .{
                .node = tree.root,
                .parents = try Stack(*Node).init(allocator),
            };
        }
    };
}

pub fn orderAsc(comptime T: type) fn (T, T) std.math.Order {
    return struct {
        fn order(a: T, b: T) std.math.Order {
            return std.math.order(a, b);
        }
    }.order;
}

test RedBlackTree {
    {
        var tree = RedBlackTree(u8, orderAsc(u8)).init(std.testing.allocator);
        defer tree.deinit();

        try tree.insert(1);
        _ = tree.root.?.assertNoViolations();

        try tree.insert(0);
        _ = tree.root.?.assertNoViolations();

        try tree.insert(3);
        _ = tree.root.?.assertNoViolations();

        try tree.insert(2);
        _ = tree.root.?.assertNoViolations();

        try std.testing.expectEqual(tree.find(2).?.data, 2);
        try std.testing.expectEqual(tree.find(10), null);

        try std.testing.expectEqual(tree.min().?.data, 0);
        try std.testing.expectEqual(tree.max().?.data, 3);

        const node = tree.find(3).?;
        tree.delete(node);
        _ = tree.root.?.assertNoViolations();

        try std.testing.expectEqual(tree.find(3), null);

        var it = try tree.iter(std.testing.allocator);
        defer it.deinit();

        try std.testing.expectEqual(it.next(), 0);
        try std.testing.expectEqual(it.next(), 1);
        try std.testing.expectEqual(it.next(), 2);
    }

    {
        var tree = RedBlackTree(u8, orderAsc(u8)).init(std.testing.allocator);
        defer tree.deinit();

        try tree.insert(55);
        try tree.insert(40);
        try tree.insert(65);
        try tree.insert(60);
        try tree.insert(75);
        try tree.insert(57);
        _ = tree.root.?.assertNoViolations();

        tree.delete(tree.find(40).?);
        _ = tree.root.?.assertNoViolations();
    }
}

pub fn RedBlackTreeMap(comptime K: type, comptime V: type, orderFn: fn (K, K) std.math.Order) type {
    return struct {
        tree: Tree,

        pub const Entry = struct {
            key: K,
            value: V,

            fn order(a: Entry, b: Entry) std.math.Order {
                return orderFn(a.key, b.key);
            }
        };

        const Tree = RedBlackTree(Entry, Entry.order);
        const Self = @This();

        pub fn init(allocator: Allocator) Self {
            return .{ .tree = Tree.init(allocator) };
        }

        pub fn deinit(tree: *Self) void {
            tree.tree.deinit();
        }

        pub fn get(tree: *Self, key: K) ?V {
            const node = tree.tree.find(Entry{ .key = key, .value = undefined }) orelse return null;
            return node.data.value;
        }

        pub fn contains(tree: *Self, key: K) bool {
            return tree.tree.find(Entry{ .key = key, .value = undefined }) != null;
        }

        pub fn insert(tree: *Self, key: K, value: V) !void {
            if (tree.tree.find(Entry{ .key = key, .value = undefined })) |node| {
                node.data.value = value;
            } else {
                try tree.tree.insert(Entry{ .key = key, .value = value });
            }
        }

        pub fn remove(tree: *Self, key: K) ?V {
            if (tree.tree.find(Entry{ .key = key, .value = undefined })) |node| {
                const value = node.data.value;
                tree.tree.delete(node);
                return value;
            } else {
                return null;
            }
        }

        pub const Iter = struct {
            iter: Tree.Iter,

            pub fn next(it: *Iter) !?Entry {
                return it.iter.next();
            }

            pub fn deinit(it: *Iter) void {
                it.iter.deinit();
            }
        };

        pub fn iter(tree: *Self, allocator: Allocator) !Iter {
            return .{ .iter = try tree.tree.iter(allocator) };
        }
    };
}

test RedBlackTreeMap {
    const Map = RedBlackTreeMap(u64, []const u64, orderAsc(u64));
    var map = Map.init(std.testing.allocator);
    defer map.deinit();

    inline for (0..100) |i| {
        const entry = .{ i, &[_]u64{i * 10} };
        try map.insert(entry.@"0", entry.@"1");
        _ = map.tree.root.?.assertNoViolations();

        try std.testing.expectEqual(map.get(entry.@"0").?, entry.@"1");
    }

    inline for (.{ 99, 17, 68, 37, 43, 53, 23 }) |i| {
        try std.testing.expectEqualDeep(map.remove(i), &[_]u64{i * 10});
        _ = map.tree.root.?.assertNoViolations();
    }

    var it = try map.iter(std.testing.allocator);
    defer it.deinit();

    inline for (0..10) |i| {
        try std.testing.expectEqualDeep(try it.next(), Map.Entry{ .key = i, .value = &[_]u64{i * 10} });
    }

    try std.testing.expectEqualDeep(map.remove(6), &[_]u64{60});
    _ = map.tree.root.?.assertNoViolations();

    try std.testing.expectEqualDeep(map.remove(0), &[_]u64{0});
    _ = map.tree.root.?.assertNoViolations();
}
