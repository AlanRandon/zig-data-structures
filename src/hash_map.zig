const std = @import("std");
const SinglyLinkedList = @import("linked_list.zig").SinglyLinkedList;
const Allocator = std.mem.Allocator;

pub fn HashMap(comptime K: type, comptime V: type) type {
    return struct {
        const Self = @This();

        const Entry = struct {
            key: K,
            value: V,
        };

        const Bucket = SinglyLinkedList(Entry);

        buckets: []Bucket,
        allocator: Allocator,

        pub fn init(capacity: usize, allocator: Allocator) Allocator.Error!Self {
            var buckets = try allocator.alloc(Bucket, capacity);

            for (0..buckets.len) |i| {
                buckets[i] = SinglyLinkedList(Entry).init(allocator);
            }

            return .{ .buckets = buckets, .allocator = allocator };
        }

        pub fn insert(self: *Self, key: K, value: V) Allocator.Error!void {
            const bucket = &self.buckets[hash(key) % self.buckets.len];
            var node = bucket.head;
            while (true) {
                if (node == null) {
                    try bucket.insertHead(.{ .key = key, .value = value });
                    return;
                } else if (std.meta.eql(node.?.data.key, key)) {
                    node.?.data.value = value;
                    return;
                } else {
                    node = node.?.next;
                }
            }
        }

        pub fn hash(key: K) u64 {
            var hasher = std.hash.Wyhash.init(0);
            std.hash.autoHash(&hasher, key);
            return hasher.final();
        }

        pub fn get(self: *Self, key: K) ?V {
            var bucket = self.buckets[hash(key) % self.buckets.len];
            var node = bucket.head orelse return null;
            while (true) {
                if (std.meta.eql(node.*.data.key, key)) {
                    return node.*.data.value;
                }
                node = node.next orelse return null;
            }
        }

        pub fn resize(self: *Self, capacity: usize) Allocator.Error!void {
            var new_map = try Self.init(capacity, self.allocator);
            for (self.buckets) |bucket_const| {
                var bucket = bucket_const;
                while (bucket.popHead()) |entry| {
                    const rehash = hash(entry.key) % new_map.buckets.len;
                    var new_bucket = new_map.buckets[rehash];
                    try new_bucket.insertHead(entry);
                }
            }
            self.allocator.free(self.buckets);
            self.buckets = new_map.buckets;
        }

        pub fn deinit(self: *Self) void {
            for (self.buckets) |bucket_ptr| {
                var bucket = bucket_ptr;
                bucket.deinit();
            }
            self.allocator.free(self.buckets);
        }
    };
}

test "hash map works" {
    var allocator = std.testing.allocator;
    var map = try HashMap(u64, u64).init(10, allocator);
    try map.resize(5);
    defer map.deinit();

    inline for (.{ .{ 1, 10 }, .{ 2, 20 } }) |entry| {
        try map.insert(entry.@"0", entry.@"1");
        try std.testing.expectEqual(map.get(entry.@"0").?, entry.@"1");
    }
}
