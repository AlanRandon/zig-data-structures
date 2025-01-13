const std = @import("std");
const Graph = @import("dsa").graph.WeightedGraph(u8);

pub fn makeGraph(allocator: std.mem.Allocator) !Graph {
    var graph = try Graph.init(allocator);

    const a = try graph.addNode('A');
    const b = try graph.addNode('B');
    const c = try graph.addNode('C');
    const d = try graph.addNode('D');

    graph.addUndirectedEdge(a, b, 10);
    graph.addUndirectedEdge(b, d, 15);
    graph.addUndirectedEdge(c, d, 4);
    graph.addUndirectedEdge(c, a, 6);
    graph.addUndirectedEdge(a, d, 5);

    return graph;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var graph = try makeGraph(allocator);
    defer graph.deinit();

    std.mem.doNotOptimizeAway(&graph);

    while (true) {
        try benchPrim(&graph);
    }
}

noinline fn benchPrim(graph: *const Graph) !void {
    var result = try @call(.never_inline, Graph.prim, .{graph});
    defer result.deinit();

    std.mem.doNotOptimizeAway(&result);
}
