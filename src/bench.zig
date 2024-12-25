const std = @import("std");
const graph = @import("./graph.zig");

const Benchmark = struct {
    timer: std.time.Timer,

    fn init() !Benchmark {
        return .{
            .timer = try std.time.Timer.start(),
        };
    }

    fn runBench(bench: *Benchmark, spec: anytype, args: anytype) void {
        const start = bench.timer.lap();

        for (0..spec.iterations) |_| {
            const result = @call(.auto, spec.bench, args);
            std.mem.doNotOptimizeAway(&result);
        }

        const end = bench.timer.lap();

        const elapsed_ns = @as(f64, @floatFromInt(end - start));
        const average_time = @as(u64, @intFromFloat(elapsed_ns / spec.iterations));

        std.debug.print("{s}: {} ns/iteration\n", .{ spec.name, average_time });
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var benchmark = try Benchmark.init();

    {
        var arena = std.heap.ArenaAllocator.init(allocator);
        defer arena.deinit();

        const Graph = graph.WeightedGraph(u8);
        var g = try Graph.init(arena.allocator());

        const a = try g.addNode('A');
        const b = try g.addNode('B');
        const c = try g.addNode('C');
        const d = try g.addNode('D');

        g.addUndirectedEdge(a, b, 10);
        g.addUndirectedEdge(b, d, 15);
        g.addUndirectedEdge(c, d, 4);
        g.addUndirectedEdge(c, a, 6);
        g.addUndirectedEdge(a, d, 5);

        benchmark.runBench(struct {
            const iterations = 1_000_000;
            const name = "prim";

            fn bench(input: *const Graph) !Graph {
                return try input.prim();
            }
        }, .{&g});

        benchmark.runBench(struct {
            const iterations = 1_000_000;
            const name = "kruskal";

            fn bench(input: *const Graph) !Graph {
                return try input.kruskal();
            }
        }, .{&g});
    }
}
