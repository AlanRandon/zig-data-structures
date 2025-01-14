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

        pub fn fromSlice(data: []T, allocator: Allocator) Self {
            return .{
                .data = data,
                .length = data.len,
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

        pub fn get(self: *const Self, index: usize) ?T {
            if (index >= self.length) return null;
            return self.data[index];
        }

        pub fn last(self: *const Self) ?T {
            if (0 == self.length) return null;
            return self.data[self.length - 1];
        }

        pub fn first(self: *const Self) ?T {
            return self.get(0);
        }

        pub fn slice(self: *const Self) []T {
            return self.data[0..self.length];
        }

        pub fn toOwnedSlice(self: Self) ![]T {
            var arr = self;
            try arr.shrink();
            return arr.slice();
        }

        pub fn reverse(self: *Self) void {
            for (0..self.length / 2) |i| {
                std.mem.swap(T, &self.data[i], &self.data[self.length - 1 - i]);
            }
        }

        pub fn clone(self: *const Self) !Self {
            const data = try self.allocator.alloc(T, self.data.len);
            @memcpy(data, self.data);

            return .{
                .data = data,
                .length = self.length,
                .allocator = self.allocator,
            };
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

        pub fn fromSlice(data: []Int, allocator: Allocator) Self {
            return .{
                .data = data,
                .length = data.len * @bitSizeOf(Int),
                .allocator = allocator,
            };
        }

        pub fn init(allocator: Allocator) Self {
            return .{
                .data = allocator.alloc(Int, 0) catch unreachable,
                .length = 0,
                .allocator = allocator,
            };
        }

        pub fn initZero(length: usize, allocator: Allocator) !Self {
            const data = try allocator.alloc(Int, std.math.divCeil(usize, length, @bitSizeOf(Int)) catch unreachable);
            @memset(data, 0);

            return .{
                .data = data,
                .length = length,
                .allocator = allocator,
            };
        }

        pub fn push(self: *Self, value: u1) !void {
            const end_position = self.length;
            self.length += 1;
            self.data = try self.allocator.realloc(self.data, std.math.divCeil(usize, self.length, @bitSizeOf(Int)) catch unreachable);

            self.set(end_position, value);
        }

        pub fn pushInt(self: *Self, comptime T: type, value: T) !void {
            if (@typeInfo(T) != .int) {
                @compileError("pushInt() must have an integer, passed: " ++ @typeName(@TypeOf(value)));
            }

            const int_size = @bitSizeOf(T);
            const end_position = self.length;
            self.length += int_size;
            self.data = try self.allocator.realloc(self.data, std.math.divCeil(usize, self.length, @bitSizeOf(Int)) catch unreachable);

            for (0..int_size) |index| {
                const bit: u1 = @bitCast(value != value & ~(@as(T, 1) << @intCast(index)));
                self.set(end_position + index, bit);
            }
        }

        pub fn readInt(self: *const Self, comptime T: type, index: usize) T {
            var result: T = 0;
            for (0..@bitSizeOf(T)) |bit_index| {
                const bit = self.get(bit_index + index);
                result |= @as(T, @intCast(bit)) << @intCast(bit_index);
            }
            return result;
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

        pub const Iter = struct {
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

            pub fn readInt(it: *Iter, comptime T: type) ?T {
                if (it.index >= it.bit_set.length - 1 + @bitSizeOf(T)) {
                    return null;
                }

                const result = it.bit_set.readInt(T, it.index);
                it.index += @bitSizeOf(T);
                return result;
            }

            pub fn remaining(it: *const Iter) usize {
                return it.bit_set.length - it.index;
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

    try std.testing.expectEqual(2, bit_set.data.len);

    const len = bit_set.length;
    try bit_set.pushInt(u8, 10);
    try std.testing.expectEqual(10, bit_set.readInt(u8, len));
}
