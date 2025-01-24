const std = @import("std");
const Array = @import("array.zig").Array;
const Allocator = std.mem.Allocator;

pub fn Stack(comptime T: type) type {
    return struct {
        const Self = @This();

        items: Array(T),

        pub fn init(allocator: Allocator) Allocator.Error!Self {
            return .{ .items = try Array(T).init(allocator) };
        }

        pub fn deinit(self: *Self) void {
            self.items.deinit();
        }

        pub fn push(self: *Self, item: T) Allocator.Error!void {
            try self.items.push(item);
        }

        pub fn pop(self: *Self) ?T {
            return self.items.pop();
        }

        pub fn peek(self: *Self) ?T {
            return self.items.last();
        }

        pub fn isEmpty(self: *Self) bool {
            return self.items.length == 0;
        }
    };
}

test Stack {
    var stack = try Stack(u64).init(std.testing.allocator);
    defer stack.deinit();

    try stack.push(6);
    try stack.push(28);

    try std.testing.expectEqual(stack.peek(), 28);

    try stack.push(496);

    try std.testing.expectEqual(stack.pop(), 496);
}
