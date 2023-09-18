const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn SinglyLinkedList(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Node = struct {
            data: T,
            next: ?*Node,

            pub fn deinit(self: *Node, allocator: Allocator) void {
                defer allocator.destroy(self);
                var next = self.next orelse return;
                next.deinit(allocator);
            }
        };

        head: ?*Node,
        allocator: Allocator,

        pub fn init(allocator: Allocator) Self {
            return .{ .head = null, .allocator = allocator };
        }

        pub fn insertHead(self: *Self, data: T) Allocator.Error!void {
            var head = try self.allocator.create(Node);
            head.* = .{ .data = data, .next = self.head };
            self.head = head;
        }

        pub fn popHead(self: *Self) ?T {
            var head = self.head orelse return null;
            self.head = head.next;
            return head.data;
        }

        pub fn getNode(self: *Self, index: usize) ?*Node {
            var node = self.head orelse return null;
            for (0..index) |_| {
                node = node.next orelse return null;
            }
            return node;
        }

        pub fn get(self: *Self, index: usize) ?T {
            return (self.getNode(index) orelse return null).data;
        }

        pub fn reverse(self: *Self) void {
            var node = self.head orelse return;
            var previous_node: ?*Node = null;

            while (true) {
                var next_node = node.next;
                node.next = previous_node;
                previous_node = node;
                node = next_node orelse break;
            }

            self.head = node;
        }

        pub fn deinit(self: *Self) void {
            var head = self.head orelse return;
            head.deinit(self.allocator);
        }
    };
}

test "singly linked list works" {
    var allocator = std.testing.allocator;
    const data = .{ 2, 4, 6, 8, 10 };
    var list = SinglyLinkedList(u64).init(allocator);
    defer list.deinit();

    inline for (data) |i| {
        try list.insertHead(i);
    }

    try std.testing.expectEqual(list.get(3), 4);

    list.reverse();

    try std.testing.expectEqual(list.get(3), 8);

    var node = list.head.?;
    inline for (data) |i| {
        blk: {
            try std.testing.expectEqual(node.data, i);
            node = node.next orelse break :blk;
        }
    }
}
