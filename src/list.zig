const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn List(comptime T: type) type {
    return struct {
        const Self = @This();

        length: usize,
        data: []T,
        allocator: Allocator,

        pub fn new(allocator: Allocator) Allocator.Error!Self {
            return with_capacity(0, allocator);
        }

        pub fn with_capacity(capacity: usize, allocator: Allocator) Allocator.Error!Self {
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
    };
}

test "list works" {
    var allocator = std.testing.allocator;
    var list = try List(u64).new(allocator);
    defer list.deinit();

    // [ 1 , 2 ]
    try list.push(1);
    try list.push(2);

    // [ 1 ]
    var element = list.pop();

    // [ 1, 3 ]
    try list.push(3);

    try std.testing.expectEqual(list.get(1), 3);
    try std.testing.expectEqual(list.get(800), null);

    try std.testing.expectEqual(element, 2);
    try std.testing.expectEqual(list.pop(), 3);
    try std.testing.expectEqual(list.pop(), 1);
    try std.testing.expectEqual(list.pop(), null);
}
