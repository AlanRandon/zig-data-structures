const std = @import("std");
const Allocator = std.mem.Allocator;
const HashMap = @import("hash_map.zig").HashMap;

fn memoizeReturnType(comptime F: type) type {
    const info = @typeInfo(F);

    const func_info = switch (info) {
        .pointer => |pointed| @typeInfo(pointed.child),
        else => @compileError("`memoizer` requires a function pointer, recieved " ++ @typeName(F)),
    };

    const func = switch (func_info) {
        .@"fn" => |func| func,
        else => @compileError("`memoizer` requires a function pointer, recieved " ++ @typeName(F)),
    };

    return struct {
        const Self = @This();

        const Input = std.meta.ArgsTuple(@Type(func_info));
        const Output = func.return_type orelse unreachable;

        const Cache = HashMap(Input, Output);

        cache: Cache,
        func: F,

        fn init(func_ptr: F, allocator: Allocator) Allocator.Error!Self {
            return .{
                .cache = try Cache.init(10, allocator),
                .func = func_ptr,
            };
        }

        pub fn deinit(self: *Self) void {
            self.cache.deinit();
        }

        pub fn call(self: *Self, input: Input) Allocator.Error!Output {
            return self.cache.get(input) orelse {
                const output = @call(.auto, self.func, input);
                try self.cache.insert(input, output);
                return output;
            };
        }
    };
}

pub fn memoizer(func: anytype, allocator: Allocator) Allocator.Error!memoizeReturnType(@TypeOf(func)) {
    return memoizeReturnType(@TypeOf(func)).init(func, allocator);
}

test memoizer {
    const add = struct {
        var count: u64 = 0;

        fn add(a: u64, b: u64) u64 {
            count += 1;
            return a + b;
        }
    };

    const allocator = std.testing.allocator;
    var add_memo = try memoizer(&add.add, allocator);
    defer add_memo.deinit();

    const a = try add_memo.call(.{ 1, 2 });
    const b = try add_memo.call(.{ 1, 2 });
    _ = try add_memo.call(.{ 1, 3 });

    try std.testing.expectEqual(a, b);
    try std.testing.expectEqual(add.count, 2);
}
