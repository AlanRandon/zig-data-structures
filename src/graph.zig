const std = @import("std");
const Array = @import("./array.zig").Array;
const Allocator = std.mem.Allocator;

pub fn WeightedGraph(T: type) type {
    return struct {
        nodes: Array(T),
        // [i * num_nodes + j] = weight of edge ij
        adjacency_matrix: []?Weight,
        allocator: Allocator,

        const NodeIndex = usize;
        const Weight = usize;
        const Self = @This();

        pub fn init(allocator: Allocator) !Self {
            return .{
                .nodes = try Array(T).init(allocator),
                .adjacency_matrix = undefined,
                .allocator = allocator,
            };
        }

        pub fn addNode(graph: *Self, data: T) !NodeIndex {
            const old_number_nodes = graph.nodes.length;
            try graph.nodes.push(data);
            errdefer _ = graph.nodes.pop();

            const adjacency_matrix = try graph.allocator.alloc(?Weight, graph.nodes.length * graph.nodes.length);
            @memset(adjacency_matrix, null);
            for (0..old_number_nodes) |i| {
                for (0..old_number_nodes) |j| {
                    adjacency_matrix[i * graph.nodes.length + j] = graph.adjacency_matrix[i * old_number_nodes + j];
                }
            }

            if (old_number_nodes > 0) {
                graph.allocator.free(graph.adjacency_matrix);
            }
            graph.adjacency_matrix = adjacency_matrix;

            return old_number_nodes;
        }

        pub fn getNode(graph: *const Self, node: NodeIndex) T {
            return graph.nodes.slice()[node];
        }

        pub fn addEdge(graph: *Self, from: NodeIndex, to: NodeIndex, weight: Weight) void {
            graph.adjacency_matrix[from * graph.nodes.length + to] = weight;
        }

        pub fn addUndirectedEdge(graph: *Self, a: NodeIndex, b: NodeIndex, weight: Weight) void {
            graph.addEdge(a, b, weight);
            graph.addEdge(b, a, weight);
        }

        pub fn edgeWeight(graph: *const Self, from: NodeIndex, to: NodeIndex) ?Weight {
            return graph.adjacency_matrix[from * graph.nodes.length + to];
        }

        pub fn deinit(graph: *Self) void {
            if (graph.nodes.length > 0) {
                graph.allocator.free(graph.adjacency_matrix);
            }

            graph.nodes.deinit();
        }

        const DijkstraResult = struct {
            path: Array(NodeIndex),
            length: Weight,

            fn deinit(result: *DijkstraResult) void {
                result.path.deinit();
            }
        };

        const DijkstraNodeInfo = union(enum) {
            final_value: Weight,
            working_value: Weight,
            no_value,

            pub fn weight(info: *const DijkstraNodeInfo) ?Weight {
                return switch (info.*) {
                    .final_value, .working_value => |value| value,
                    else => null,
                };
            }
        };

        pub fn dijkstra(graph: *const Self, from: NodeIndex, to: NodeIndex) !DijkstraResult {
            const weights = try graph.allocator.alloc(DijkstraNodeInfo, graph.nodes.length);
            defer graph.allocator.free(weights);
            @memset(weights, .no_value);

            weights[from] = .{ .final_value = 0 };
            var current_node: ?usize = from;

            while (current_node) |cn| {
                if (cn == to) {
                    break;
                }

                for (0..graph.nodes.length) |i| {
                    if (graph.edgeWeight(cn, i)) |edge_weight| {
                        const new_value = weights[cn].weight().? + edge_weight;
                        switch (weights[i]) {
                            .final_value => {},
                            .no_value => weights[i] = .{ .working_value = new_value },
                            .working_value => |*value| value.* = @min(value.*, new_value),
                        }
                    }
                }

                current_node = null;
                for (weights, 0..) |weight, i| {
                    switch (weight) {
                        .final_value, .no_value => {},
                        .working_value => |value| {
                            if (current_node) |j| {
                                if (weights[j].working_value > value) {
                                    current_node = i;
                                }
                            } else {
                                current_node = i;
                            }
                        },
                    }
                }

                if (current_node) |new_node| {
                    weights[new_node] = .{ .final_value = weights[new_node].working_value };
                }
            }

            var path_node = to;
            var path_value = switch (weights[to]) {
                .final_value => |value| value,
                else => return error.EndNodeUnreachable,
            };
            const path_weight = path_value;

            var path = try Array(NodeIndex).init(graph.allocator);
            errdefer path.deinit();

            while (path_value > 0) {
                for (weights, 0..) |weight, i| {
                    if (graph.edgeWeight(i, path_node)) |edge_weight| {
                        switch (weight) {
                            .final_value => |value| {
                                if (std.math.sub(Weight, path_value, edge_weight) catch null == value) {
                                    try path.push(path_node);
                                    path_node = i;
                                    path_value = value;
                                }
                            },
                            else => {},
                        }
                    }
                }
            }

            try path.push(path_node);
            path.reverse();

            return DijkstraResult{ .path = path, .length = path_weight };
        }

        pub fn isUndirected(graph: *const Self) bool {
            for (0..graph.nodes.length) |i| {
                for (0..graph.nodes.length) |j| {
                    if (graph.edgeWeight(i, j) != graph.edgeWeight(j, i)) {
                        return false;
                    }
                }
            }

            return true;
        }

        pub fn prim(graph: *const Self) !Self {
            if (!graph.isUndirected()) {
                return error.GraphDirected;
            }

            if (graph.nodes.length == 0) {
                return Self{
                    .nodes = try Array(T).init(graph.allocator),
                    .adjacency_matrix = undefined,
                    .allocator = graph.allocator,
                };
            }

            const adjacency_matrix = try graph.allocator.alloc(?Weight, graph.adjacency_matrix.len);
            errdefer graph.allocator.free(adjacency_matrix);
            @memset(adjacency_matrix, null);

            var result_nodes = try graph.nodes.clone();
            errdefer result_nodes.deinit();

            var result = Self{
                .nodes = result_nodes,
                .adjacency_matrix = adjacency_matrix,
                .allocator = graph.allocator,
            };

            const linked_nodes = try graph.allocator.alloc(bool, graph.nodes.length);
            defer graph.allocator.free(linked_nodes);
            @memset(linked_nodes, false);
            linked_nodes[0] = true;

            var min_edge: ?struct {
                from: NodeIndex,
                to: NodeIndex,
                weight: Weight,
            } = null;

            while (true) {
                min_edge = null;

                for (linked_nodes, 0..) |from_linked, from| {
                    // grow from current MST
                    if (!from_linked) {
                        continue;
                    }

                    for (linked_nodes, 0..) |to_linked, to| {
                        // avoid cycles
                        if (to_linked) {
                            continue;
                        }

                        const weight = graph.edgeWeight(from, to) orelse continue;
                        const is_smaller = if (min_edge) |edge| weight < edge.weight else true;
                        if (is_smaller) {
                            min_edge = .{
                                .weight = weight,
                                .from = from,
                                .to = to,
                            };
                        }
                    }
                }

                if (min_edge) |edge| {
                    linked_nodes[edge.to] = true;
                    result.addUndirectedEdge(edge.from, edge.to, edge.weight);
                } else {
                    break;
                }
            }

            for (linked_nodes) |linked| {
                if (!linked) {
                    return error.GraphIncomplete;
                }
            }

            return result;
        }
    };
}

test "graphs work" {
    const Graph = WeightedGraph(u8);
    var graph = try Graph.init(std.testing.allocator);
    defer graph.deinit();

    const a = try graph.addNode('A');
    const b = try graph.addNode('B');
    const c = try graph.addNode('C');
    graph.addEdge(a, b, 10);
    graph.addEdge(b, a, 12);
    graph.addEdge(b, c, 17);

    try std.testing.expectEqual(10, graph.edgeWeight(a, b));
    try std.testing.expectEqual(12, graph.edgeWeight(b, a));

    var result = try graph.dijkstra(a, c);
    defer result.deinit();

    try std.testing.expectEqual(27, result.length);
    try std.testing.expectEqualSlices(Graph.NodeIndex, &[_]Graph.NodeIndex{ a, b, c }, result.path.slice());
}

test "dijkstra works" {
    const Graph = WeightedGraph(u8);
    var graph = try Graph.init(std.testing.allocator);
    defer graph.deinit();

    const s = try graph.addNode('S');
    const a = try graph.addNode('A');
    const b = try graph.addNode('B');
    const c = try graph.addNode('C');
    const d = try graph.addNode('D');
    const e = try graph.addNode('E');
    const f = try graph.addNode('F');
    const g = try graph.addNode('G');
    const h = try graph.addNode('H');
    const t = try graph.addNode('T');

    graph.addUndirectedEdge(s, a, 7);
    graph.addUndirectedEdge(s, b, 6);
    graph.addUndirectedEdge(s, d, 16);
    graph.addUndirectedEdge(a, d, 5);
    graph.addUndirectedEdge(b, d, 8);
    graph.addUndirectedEdge(a, c, 10);
    graph.addUndirectedEdge(b, e, 3);
    graph.addUndirectedEdge(c, d, 4);
    graph.addUndirectedEdge(c, f, 3);
    graph.addUndirectedEdge(c, g, 1);
    graph.addUndirectedEdge(d, g, 6);
    graph.addUndirectedEdge(e, g, 6);
    graph.addUndirectedEdge(e, h, 4);
    graph.addUndirectedEdge(g, h, 1);
    graph.addUndirectedEdge(f, t, 2);
    graph.addUndirectedEdge(g, t, 8);
    graph.addUndirectedEdge(h, t, 10);

    var result = try graph.dijkstra(s, t);
    defer result.deinit();

    try std.testing.expectEqual(20, result.length);
    try std.testing.expectEqualSlices(Graph.NodeIndex, &[_]Graph.NodeIndex{ s, b, e, h, g, c, f, t }, result.path.slice());
}

test "prim works" {
    const Graph = WeightedGraph(u8);
    var graph = try Graph.init(std.testing.allocator);
    defer graph.deinit();

    const a = try graph.addNode('A');
    const b = try graph.addNode('B');
    const c = try graph.addNode('C');
    const d = try graph.addNode('D');

    graph.addUndirectedEdge(a, b, 3);
    graph.addUndirectedEdge(a, d, 1);
    graph.addUndirectedEdge(b, d, 2);
    graph.addUndirectedEdge(d, c, 3);

    var result = try graph.prim();
    defer result.deinit();

    try std.testing.expectEqual(1, result.edgeWeight(a, d));
    try std.testing.expectEqual(2, result.edgeWeight(b, d));
    try std.testing.expectEqual(3, result.edgeWeight(c, d));
    try std.testing.expectEqual(null, result.edgeWeight(a, b));
}