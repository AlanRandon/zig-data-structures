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
            const head = try self.allocator.create(Node);
            head.* = .{ .data = data, .next = self.head };
            self.head = head;
        }

        pub fn popHead(self: *Self) ?T {
            const head = self.head orelse return null;
            self.head = head.next;
            const data = head.data;
            self.allocator.destroy(head);
            return data;
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
                const next_node = node.next;
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
    const allocator = std.testing.allocator;
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

pub fn DoublyLinkedList(comptime T: type) type {
    return struct {
        const Self = @This();

        const Node = struct {
            next: ?*Node,
            prev: ?*Node,
            data: T,
        };

        head: ?*Node,
        tail: ?*Node,
        allocator: Allocator,

        pub fn init(allocator: Allocator) Self {
            return .{
                .head = null,
                .tail = null,
                .allocator = allocator,
            };
        }

        pub fn popTail(list: *Self) ?T {
            const node = list.tail orelse return null;
            return list.remove(node);
        }

        pub fn popHead(list: *Self) ?T {
            const node = list.head orelse return null;
            return list.remove(node);
        }

        pub fn insertHead(list: *Self, value: T) !*Node {
            if (list.head) |head| {
                return list.insertBefore(head, value);
            } else {
                var node = try list.allocator.create(Node);
                node.prev = null;
                node.next = null;
                node.data = value;
                list.head = node;
                list.tail = node;
                return node;
            }
        }

        pub fn insertTail(list: *Self, value: T) !*Node {
            if (list.tail) |tail| {
                return list.insertAfter(tail, value);
            } else {
                var node = try list.allocator.create(Node);
                node.prev = null;
                node.next = null;
                node.data = value;
                list.head = node;
                list.tail = node;
                return node;
            }
        }

        pub fn remove(list: *Self, node: *Node) T {
            defer list.allocator.destroy(node);

            if (node.prev) |prev| {
                prev.next = node.next;
            } else {
                list.head = node.next;
            }

            if (node.next) |next| {
                next.prev = node.prev;
            } else {
                list.tail = node.prev;
            }

            return node.data;
        }

        pub fn insertAfter(list: *Self, node: *Node, value: T) !*Node {
            var new_node = try list.allocator.create(Node);
            new_node.data = value;
            new_node.next = node.next;
            new_node.prev = node;

            if (node.next == null) {
                list.tail = new_node;
            }

            node.next = new_node;

            return new_node;
        }

        pub fn insertBefore(list: *Self, node: *Node, value: T) !*Node {
            var new_node = try list.allocator.create(Node);
            new_node.data = value;
            new_node.prev = node.prev;
            new_node.next = node;

            if (node.prev == null) {
                list.head = new_node;
            }

            node.prev = new_node;

            return new_node;
        }

        pub fn deinit(list: *Self) void {
            var node = list.head orelse return;
            while (true) {
                const next = node.next;
                list.allocator.destroy(node);
                node = next orelse return;
            }
        }
    };
}

test "doubly linked list works" {
    var list = DoublyLinkedList(u8).init(std.testing.allocator);
    defer list.deinit();

    {
        // { 1 }
        _ = try list.insertHead(1);
        // { 1, 1 }
        const node = try list.insertTail(1);
        // { 1, 1, 2 }
        _ = try list.insertAfter(node, 2);
        // { 0, 1, 1, 2 }
        _ = try list.insertHead(0);
        // { 0, 1, 2 }
        _ = list.remove(node);
        // { 0, 1, 2, 3 }
        _ = try list.insertTail(3);
    }

    var node = list.head;
    inline for (.{ 0, 1, 2, 3 }) |i| {
        try std.testing.expectEqual(node.?.data, i);
        node = node.?.next;
    }
}
