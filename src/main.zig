const std = @import("std");
const HashMap = @import("./hash_map.zig").HashMap;

test {
    std.testing.refAllDecls(@This());
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    {
        var map = try HashMap(u64, u64).new(10, allocator);
        defer map.deinit();

        try map.insert(1, 10);

        std.debug.print("{?}\n", .{map.get(1)});
    }
    _ = gpa.detectLeaks();
}
