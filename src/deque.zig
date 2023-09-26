const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn Deque(comptime T: type) type {
    return struct {
        const Self = @This();

        items: []T,
        allocator: Allocator,

        pub fn init(allocator: Allocator) Self {
            return .{ .items = &[_]u8{}, .allocator = allocator };
        }

        pub fn deinit(deque: *Self) void {
            deque.allocator.free(deque.items);
        }

        // TODO: pushBack(T), pushFront(T), popBack(), popFront(), back(), front()
    };
}

test "deque works" {
    var deque = Deque(u8).init(std.testing.allocator);
    defer deque.deinit();
}
