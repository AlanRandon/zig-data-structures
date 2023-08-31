const std = @import("std");
const Array = @import("array.zig").Array;
const Allocator = std.mem.Allocator;

pub fn Stack(comptime T: type) type {
    return struct {
        const Self = @This();

        items: Array(T),

        fn init(allocator: Allocator) Allocator.Error!Self {
            return .{ .items = try Array(T).init(allocator) };
        }

        fn deinit(self: *Self) void {
            self.items.deinit();
        }

        fn push(self: *Self, item: T) Allocator.Error!void {
            try self.items.push(item);
        }

        fn pop(self: *Self) ?T {
            return self.items.pop();
        }

        fn peek(self: *Self) ?T {
            return self.items.last();
        }
    };
}

test "stack works" {
    const allocator = std.testing.allocator;
    var stack = try Stack(u64).init(allocator);
    defer stack.deinit();

    try stack.push(6);
    try stack.push(28);

    try std.testing.expectEqual(stack.peek(), 28);

    try stack.push(496);

    try std.testing.expectEqual(stack.pop(), 496);
}
