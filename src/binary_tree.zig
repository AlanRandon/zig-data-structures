const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn BinaryTree(comptime T: type) type {
    return struct {
        const Self = @This();

        const Node = struct {
            left: ?*Node,
            value: T,
            right: ?*Node,

            pub fn init(value: T) Node {
                return .{
                    .left = null,
                    .value = value,
                    .right = null,
                };
            }

            const ChildrenType = enum {
                leaf,
                left,
                right,
                both,
            };

            pub fn childrenType(self: *Node) ChildrenType {
                if (self.right) {
                    if (self.left) {
                        return ChildrenType.both;
                    }
                    return ChildrenType.right;
                }

                if (self.left) {
                    return ChildrenType.left;
                }

                return ChildrenType.leaf;
            }

            pub fn deinit(self: *Node, allocator: Allocator) void {
                inline for (.{ self.left, self.right }) |child_ptr| {
                    blk: {
                        var child = child_ptr orelse break :blk;
                        child.deinit(allocator);
                        allocator.destroy(child);
                    }
                }
            }

            pub fn insert(self: *Node, value: T, allocator: Allocator) Allocator.Error!void {
                if (value < self.value) {
                    if (self.left == null) {
                        self.left = try allocator.create(Node);
                        self.left.?.* = Node.init(value);
                        return;
                    }
                    try self.left.?.insert(value, allocator);
                } else {
                    if (self.right == null) {
                        self.right = try allocator.create(Node);
                        self.right.?.* = Node.init(value);
                        return;
                    }
                    try self.right.?.insert(value, allocator);
                }
            }

            pub fn minNode(self: *Node) *Node {
                const node = self.left orelse return self;
                return node.minNode();
            }

            pub fn maxNode(self: *Node) *Node {
                const node = self.right orelse return self;
                return node.maxNode();
            }

            fn format(self: *Node, indent: u64, writer: anytype) !void {
                try writer.print("[{}]\n", .{self.value});
                inline for (.{ .{ self.left, 'l' }, .{ self.right, 'r' } }) |pair| {
                    var child_ptr = pair.@"0";
                    var symbol: u8 = pair.@"1";
                    blk: {
                        var child = child_ptr orelse break :blk;
                        for (0..indent - 1) |_| {
                            _ = try writer.write(" | ");
                        }
                        try writer.print(" {c}-", .{symbol});
                        try child.format(indent + 1, writer);
                    }
                }
            }
        };

        root: ?Node,
        allocator: Allocator,

        pub fn init(allocator: Allocator) Self {
            return .{ .root = null, .allocator = allocator };
        }

        pub fn deinit(self: *Self) void {
            var root = self.root orelse return;
            root.deinit(self.allocator);
        }

        pub fn insert(self: *Self, value: T) Allocator.Error!void {
            if (self.root == null) {
                var node = Node.init(value);
                self.root = node;
                return;
            }

            try self.root.?.insert(value, self.allocator);
        }

        pub fn min(self: *Self) ?T {
            var root = self.root orelse return null;
            return root.minNode().value;
        }

        pub fn max(self: *Self) ?T {
            var root = self.root orelse return null;
            return root.maxNode().value;
        }

        pub fn format(value: *const Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
            _ = options;
            _ = fmt;
            var root = value.root orelse return;
            try root.format(1, writer);
        }
    };
}

test "binary tree works" {
    var allocator = std.testing.allocator;
    var tree = BinaryTree(u64).init(allocator);
    defer tree.deinit();

    inline for (.{ 5, 4, 9, 3, 2 }) |i| {
        try tree.insert(i);
    }

    try std.testing.expectEqual(tree.min(), 2);
    try std.testing.expectEqual(tree.max(), 9);
}
