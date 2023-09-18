// const std = @import("std");
// const Allocator = std.mem.Allocator;

// pub fn merge_sort(comptime T: type, data: []T) void {
//     _ = data;
// }

// pub fn merge(comptime T: type, a: []T, b: []T, allocator: Allocator) []T {
//     var a_index = 0;
//     var b_index = 0;
//     var index = 0;
//     while (true) {
//         switch (std.math.order(a[a_index], b[b_index])) {
//             .gt => {
//                 output[index] = a[a_index];
//                 a_index += 1;
//             },
//             .lt | .eq => {
//                 output[index] = b[b_index];
//                 b_index += 1;
//             },
//         }
//         index += 1;
//     }
// }

// test "merge sort works" {
//     var data = []u8{ 4, 7, 1, 5 };
//     merge_sort(data);
//     try std.testing.expectEqual(data, []u8{ 1, 4, 5, 7 });
// }
