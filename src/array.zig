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

        pub fn slice(self: *Self) []T {
            return self.data[0..self.length];
        }

        pub fn toOwnedSlice(self: Self) ![]T {
            var arr = self;
            try arr.shrink();
            return arr.slice();
        }
    };
}

test "array works" {
    const allocator = std.testing.allocator;
    var array = try Array(u64).init(allocator);
    defer array.deinit();

    // [ 1 , 2 ]
    try array.push(1);
    try array.push(2);

    // [ 1 ]
    const element = array.pop();

    // [ 1, 3 ]
    try array.push(3);

    try std.testing.expectEqual(array.get(1), 3);
    try std.testing.expectEqual(array.get(800), null);

    try std.testing.expectEqual(element, 2);
    try std.testing.expectEqual(array.pop(), 3);
    try std.testing.expectEqual(array.pop(), 1);
    try std.testing.expectEqual(array.pop(), null);
}

pub fn BitSet(comptime Int: type) type {
    if (@typeInfo(Int) != .int) {
        @compileError("BitSet must have an integer, passed: " ++ @typeName(Int));
    }

    if (@bitSizeOf(Int) != @sizeOf(Int) * 8) {
        @compileError("BitSet must have a non-padded integer, passed: " ++ @typeName(Int));
    }

    return struct {
        const Self = @This();

        data: []Int,
        length: usize,
        allocator: Allocator,

        pub fn init(allocator: Allocator) Self {
            return .{
                .data = allocator.alloc(Int, 0) catch unreachable,
                .length = 0,
                .allocator = allocator,
            };
        }

        pub fn initZero(length: usize, allocator: Allocator) !Self {
            const data = try allocator.alloc(Int, length / @bitSizeOf(Int) + 1);
            @memset(data, 0);

            return .{
                .data = data,
                .length = length,
                .allocator = allocator,
            };
        }

        pub fn push(self: *Self, value: u1) !void {
            self.data = try self.allocator.realloc(self.data, self.length / @bitSizeOf(Int) + 1);
            self.set(self.length, value);
            self.length += 1;
        }

        pub fn set(self: *Self, index: usize, value: u1) void {
            const array_index = index / @bitSizeOf(Int);
            const int_index = index % @bitSizeOf(Int);
            self.data[array_index] &= ~(@as(Int, 1) << @intCast(int_index));
            self.data[array_index] |= @as(Int, value) << @intCast(int_index);
        }

        pub fn get(self: *const Self, index: usize) u1 {
            const data = self.data[index / @bitSizeOf(Int)];
            const mask = ~(@as(Int, 1) << @intCast(index % @bitSizeOf(Int)));
            return @bitCast(data != mask & data);
        }

        pub fn reverse(self: *Self) !void {
            var bits = Self{
                .data = try self.allocator.dupe(Int, self.data),
                .length = self.length,
                .allocator = self.allocator,
            };
            defer bits.deinit();

            for (0..self.length) |i| {
                self.set(i, bits.get(self.length - 1 - i));
            }
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.data);
        }

        const Iter = struct {
            bit_set: *const Self,
            index: usize,

            pub fn next(it: *Iter) ?u1 {
                if (it.index >= it.bit_set.length) {
                    return null;
                }

                const result = it.bit_set.get(it.index);
                it.index += 1;
                return result;
            }
        };

        pub fn iter(self: *const Self) Iter {
            return .{ .bit_set = self, .index = 0 };
        }
    };
}

test "bit set works" {
    var bit_set = BitSet(u8).init(std.testing.allocator);
    defer bit_set.deinit();
    const test_bits = [_]u1{ 0, 1, 0, 0, 0, 1, 1, 1, 0, 1 };
    for (test_bits) |i| {
        try bit_set.push(i);
    }

    for (test_bits, 0..) |data, i| {
        try std.testing.expectEqual(data, bit_set.get(i));
    }
}
