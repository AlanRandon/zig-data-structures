const DoublyLinkedList = @import("./linked_list.zig").DoublyLinkedList;
const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn PriorityQueue(comptime T: type) type {
    return struct {
        const Self = @This();

        const Item = struct { priority: usize, item: T };

        list: DoublyLinkedList(Item),

        pub fn init(allocator: Allocator) !Self {
            return .{ .list = DoublyLinkedList(Item).init(allocator) };
        }

        pub fn deinit(self: *Self) void {
            self.list.deinit();
        }

        pub fn enqueue(self: *Self, item: T, priority: usize) !void {
            const i = Item{ .priority = priority, .item = item };
            var node = self.list.head;
            while (node) |n| {
                node = n.next;
                if (n.data.priority >= priority) {
                    _ = try self.list.insertBefore(n, i);
                    return;
                }
            }
            _ = try self.list.insertTail(i);
        }

        pub fn deqeueue(self: *Self) ?T {
            return if (self.list.popTail()) |item| item.item else null;
        }
    };
}

test PriorityQueue {
    var queue = try PriorityQueue(u8).init(std.testing.allocator);
    defer queue.deinit();

    try queue.enqueue(1, 1);
    try queue.enqueue(2, 1);
    try queue.enqueue(3, 2);
    try std.testing.expectEqual(3, queue.deqeueue());
    try std.testing.expectEqual(1, queue.deqeueue());
    try std.testing.expectEqual(2, queue.deqeueue());
}

pub fn CyclicQueue(comptime T: type, comptime size: usize) type {
    return struct {
        const Self = @This();

        data: [size]T,
        front: usize,
        rear: usize,

        pub fn init() Self {
            return .{
                .data = [_]T{undefined} ** size,
                .front = 0,
                .rear = 0,
            };
        }

        pub fn isEmpty(self: *Self) bool {
            return self.front == self.rear;
        }

        pub fn enqueue(self: *Self, item: T) !void {
            const rear = (self.rear + 1) % size;
            if (self.front == rear) {
                return error.QueueFull;
            }

            self.data[self.rear] = item;
            self.rear = rear;
        }

        pub fn deqeueue(self: *Self) ?T {
            if (self.isEmpty()) {
                return null;
            }

            const item = self.data[self.front];
            self.front = (self.front + 1) % size;
            return item;
        }
    };
}

test CyclicQueue {
    {
        var queue = CyclicQueue(u8, 10).init();
        try queue.enqueue(1);
        try queue.enqueue(2);
        try queue.enqueue(3);
        try std.testing.expectEqual(1, queue.deqeueue());
        try std.testing.expectEqual(2, queue.deqeueue());
        try std.testing.expectEqual(3, queue.deqeueue());
    }

    {
        var queue = CyclicQueue(u8, 3).init();
        try queue.enqueue(1);
        try queue.enqueue(2);
    }
}
