const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn Array(comptime T: type) type {
    return struct {
        const Self = @This();

        length: usize,
        data: []T,
        allocator: Allocator,

        pub fn init(allocator: Allocator) Allocator.Error!Self {
            return withCapacity(0, allocator);
        }

        pub fn withCapacity(capacity: usize, allocator: Allocator) Allocator.Error!Self {
            return .{
                .length = 0,
                .data = try allocator.alloc(T, capacity),
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.data);
        }

        pub fn shrink(self: *Self) Allocator.Error!void {
            self.data = try self.allocator.realloc(self.data, self.length * @sizeOf(T));
        }

        pub fn push(self: *Self, element: T) Allocator.Error!void {
            if (self.data.len < self.length + 1) {
                const capacity = @max(self.data.len, 1) * @as(usize, 2);
                self.data = try self.allocator.realloc(self.data, capacity * @sizeOf(T));
            }

            self.data[self.length] = element;
            self.length += 1;
        }

        pub fn pop(self: *Self) ?T {
            if (self.length == 0) return null;
            const element = self.data[self.length - 1];
            self.length -= 1;
            return element;
        }

        pub fn get(self: *Self, index: usize) ?T {
            if (index >= self.length) return null;
            return self.data[index];
        }

        pub fn last(self: *Self) ?T {
            if (0 == self.length) return null;
            return self.data[self.length - 1];
        }

        pub fn first(self: *Self) ?T {
            return self.get(0);
        }
    };
}

test "array works" {
    var allocator = std.testing.allocator;
    var array = try Array(u64).init(allocator);
    defer array.deinit();

    // [ 1 , 2 ]
    try array.push(1);
    try array.push(2);

    // [ 1 ]
    var element = array.pop();

    // [ 1, 3 ]
    try array.push(3);

    try std.testing.expectEqual(array.get(1), 3);
    try std.testing.expectEqual(array.get(800), null);

    try std.testing.expectEqual(element, 2);
    try std.testing.expectEqual(array.pop(), 3);
    try std.testing.expectEqual(array.pop(), 1);
    try std.testing.expectEqual(array.pop(), null);
}
