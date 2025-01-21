const std = @import("std");
const Allocator = std.mem.Allocator;

const Color = enum { red, black };
const Direction = enum { left, right };

pub fn RedBlackTree(comptime T: type, comptime lessThanFn: fn (void, T, T) bool) type {
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

            pub fn debug(node: *Node, depth: usize) void {
                std.debug.print("{s}{}\n", .{ ([_]u8{'\t'} ** 1000)[0..depth], node.data });
                if (node.left) |left| left.debug(depth + 1);
                if (node.right) |right| right.debug(depth + 1);
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
                if (lessThanFn({}, data, parent.data)) {
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

            tree.rebalanceInsert(node);
        }

        fn rebalanceInsert(tree: *Self, node: *Node) void {
            var current_node = node;
            while (current_node != tree.root and current_node.parent.?.color == .red) {
                const parent = current_node.parent.?;
                const grandparent = parent.parent.?;

                if (parent == grandparent.left) {
                    const uncle = grandparent.right;
                    if (uncle != null and uncle.?.color == .red) {
                        parent.color = .black;
                        uncle.?.color = .black;
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
                        parent.color = .black;
                        uncle.?.color = .black;
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
            if (node.parent) |parent| {
                if (node == parent.left) {
                    parent.left = right_child;
                } else if (node == parent.right) {
                    parent.right = right_child;
                } else {
                    std.debug.panic("node must be child of own parent", .{});
                }
            } else {
                tree.root = right_child;
            }

            right_child.left = node;
        }

        fn rightRotate(tree: *Self, node: *Node) void {
            //    n
            //  l   r
            // 1 2
            // -->
            //   l
            // 1   n
            //    2 r

            const left_child = node.right.?;

            // put l.right in place of n.left
            node.left = left_child.right;
            if (left_child.right) |right| {
                right.parent = node;
            }

            // put n.left in place of n
            left_child.parent = node.parent;
            if (node.parent) |parent| {
                if (node == parent.left) {
                    parent.left = left_child;
                } else if (node == parent.right) {
                    parent.right = left_child;
                } else {
                    std.debug.panic("node must be child of own parent", .{});
                }
            } else {
                tree.root = left_child;
            }

            left_child.right = node;
        }
    };
}

test RedBlackTree {
    const allocator = std.testing.allocator;
    var tree = RedBlackTree(u8, std.sort.asc(u8)).init(allocator);
    defer tree.deinit();

    try tree.insert(0);
    try tree.insert(1);
    try tree.insert(2);
    try tree.insert(3);

    // try std.testing.expectEqual(tree.min(), 2);
    // try std.testing.expectEqual(tree.max(), 9);
}
