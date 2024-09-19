const std = @import("std");
const SinglyLinkedList = @import("linked_list.zig").SinglyLinkedList;
const Allocator = std.mem.Allocator;

pub fn HashMap(comptime K: type, comptime V: type) type {
    return struct {
        const Self = @This();

        pub const Entry = struct {
            key: K,
            value: V,
        };

        const Bucket = SinglyLinkedList(Entry);

        buckets: []Bucket,
        allocator: Allocator,
        entries: usize,

        pub fn init(capacity: usize, allocator: Allocator) Allocator.Error!Self {
            var buckets = try allocator.alloc(Bucket, capacity);

            for (0..buckets.len) |i| {
                buckets[i] = SinglyLinkedList(Entry).init(allocator);
            }

            return .{ .buckets = buckets, .allocator = allocator, .entries = 0 };
        }

        pub fn insert(self: *Self, key: K, value: V) Allocator.Error!void {
            try self.insertNoResize(key, value);
            try self.resizeIfNeeded();
        }

        pub fn remove(self: *Self, key: K) Allocator.Error!?V {
            const data = self.removeNoResize(key);
            try self.resizeIfNeeded();
            return data;
        }

        pub fn insertNoResize(self: *Self, key: K, value: V) Allocator.Error!void {
            const bucket = &self.buckets[hash(key) % self.buckets.len];
            var node = bucket.head;
            while (true) {
                if (node == null) {
                    try bucket.insertHead(.{ .key = key, .value = value });
                    self.entries += 1;
                    return;
                } else if (std.meta.eql(node.?.data.key, key)) {
                    node.?.data.value = value;
                    return;
                } else {
                    node = node.?.next;
                }
            }
            self.entries += 1;
        }

        pub fn removeNoResize(self: *Self, key: K) ?V {
            var bucket = &self.buckets[hash(key) % self.buckets.len];
            var previous_node: ?*Bucket.Node = null;
            var node = bucket.head orelse return null;
            while (true) {
                if (std.meta.eql(node.data.key, key)) {
                    if (previous_node) |previous| {
                        previous.next = node.next;
                    } else {
                        bucket.head = node.next;
                    }

                    const data = node.data.value;
                    self.allocator.destroy(node);
                    self.entries -|= 1;

                    return data;
                }
                previous_node = node;
                node = node.next orelse return null;
            }
        }

        pub fn hash(key: K) u64 {
            var hasher = std.hash.Wyhash.init(0);
            std.hash.autoHash(&hasher, key);
            return hasher.final();
        }

        pub fn getPtr(self: *Self, key: K) ?*V {
            const bucket = self.buckets[hash(key) % self.buckets.len];
            var node = bucket.head orelse return null;
            while (true) {
                if (std.meta.eql(node.data.key, key)) {
                    return &node.*.data.value;
                }
                node = node.next orelse return null;
            }
        }

        pub fn get(self: *Self, key: K) ?V {
            return (self.getPtr(key) orelse return null).*;
        }

        pub fn resize(self: *Self, capacity: usize) Allocator.Error!void {
            const new_map = try Self.init(capacity, self.allocator);
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
            self.entries = new_map.entries;
        }

        pub fn resizeIfNeeded(self: *Self) Allocator.Error!void {
            // if there is <80% the capacity occupied
            if (self.entries * 10 / self.buckets.len < 7) {
                return;
            }

            // if there is >120% the capacity occupied
            if (self.entries * 10 / self.buckets.len > 12) {
                return;
            }

            try resize(self, self.entries);
        }

        pub fn deinit(self: *Self) void {
            for (self.buckets) |bucket_ptr| {
                var bucket = bucket_ptr;
                bucket.deinit();
            }
            self.allocator.free(self.buckets);
        }

        fn dbgBuckets(self: *Self) void {
            std.debug.print("------\n", .{});
            for (self.buckets) |bucket| {
                std.debug.print("{any}\n\n", .{bucket.head});
            }
            std.debug.print("------\n", .{});
        }

        pub const Iter = struct {
            node: ?*Bucket.Node,
            buckets: []Bucket,

            pub fn next(it: *Iter) ?Entry {
                while (it.node == null) {
                    if (it.buckets.len > 0) {
                        it.node = it.buckets[0].head;
                        it.buckets = it.buckets[1..];
                    } else {
                        return null;
                    }
                }

                const node = it.node.?;
                it.node = node.next;
                return node.data;
            }
        };

        pub fn iter(self: *Self) Iter {
            return .{ .buckets = self.buckets, .node = null };
        }
    };
}

test "hash map works" {
    const allocator = std.testing.allocator;
    var map = try HashMap(u64, u64).init(10, allocator);
    try map.resize(5);
    defer map.deinit();

    inline for (.{ .{ 1, 10 }, .{ 2, 20 } }) |entry| {
        try map.insert(entry.@"0", entry.@"1");
        try std.testing.expectEqual(map.get(entry.@"0").?, entry.@"1");
    }

    try std.testing.expectEqual(try map.remove(2), 20);
    try std.testing.expectEqual(map.get(2), null);
}
