const std = @import("std");
const util = @import("util.zig");

fn Graph() type {
    return struct {
        nodes: std.StringHashMap(*Node),
        allocator: std.mem.Allocator,

        const Self = @This();

        const Node = struct {
            name: []const u8,
            neighbour: std.ArrayList(*Node),

            fn init(allocator: std.mem.Allocator, name: []const u8) Node {
                return Node{ .name = name, .neighbour = std.ArrayList(*Node).init(allocator) };
            }

            fn deinit(self: *Node) void {
                self.neighbour.deinit();
            }
        };

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .nodes = std.StringHashMap(*Node).init(allocator),
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            var it = self.nodes.iterator();
            while (it.next()) |*node| {
                node.value_ptr.*.deinit();
            }
            self.nodes.deinit();
            self.allocator.destroy(self);
        }

        pub fn containsNode(self: *Self, name: []const u8) bool {
            return self.nodes.contains(name);
        }

        pub fn addNode(self: *Self, name: []const u8) !void {
            if (self.containsNode(name)) {
                return error.NodeAlreadyExists;
            }

            const node = try self.allocator.create(Node);
            node.* = Node.init(self.allocator, try self.allocator.dupe(u8, name));

            try self.nodes.put(node.name, node);
        }

        pub fn getNode(self: *Self, name: []const u8) ?*Node {
            return self.nodes.get(name);
        }

        pub fn createEdge(self: *Self, node_name1: []const u8, node_name2: []const u8) !void {
            var node1 = self.getNode(node_name1) orelse return error.Node1NotFound;
            var node2 = self.getNode(node_name2) orelse return error.Node2NotFound;

            try node1.neighbour.append(node2);
            try node2.neighbour.append(node1);
        }

        const Path = struct {
            nodes: std.ArrayList([]const u8),
            visitedTwice: bool,
            allocator: std.mem.Allocator,

            fn init(allocator: std.mem.Allocator) !Path {
                return Path{ .nodes = std.ArrayList([]const u8).init(allocator), .visitedTwice = false, .allocator = allocator };
            }

            fn deinit(self: *Path) void {
                self.nodes.deinit();
            }

            fn clone(self: *Path) !Path {
                var new_path = try Path.init(self.allocator);
                new_path.visitedTwice = self.visitedTwice;
                try new_path.nodes.appendSlice(self.nodes.items);
                return new_path;
            }
        };

        pub fn findAllPaths(self: *Self, start: []const u8, end: []const u8) !std.ArrayList(std.ArrayList([]const u8)) {
            var all_valid_paths = std.ArrayList(std.ArrayList([]const u8)).init(self.allocator);

            var all_paths = try std.ArrayList(std.ArrayList([]const u8)).initCapacity(self.allocator, 100000);
            defer all_paths.deinit();

            const start_node = self.getNode(start) orelse return error.StartNodeNotFound;
            const end_node = self.getNode(end) orelse return error.EndNodeNotFound;

            // Adding path item to
            var start_path = std.ArrayList([]const u8).init(self.allocator);
            try start_path.append(start_node.name);

            try all_paths.append(start_path);

            while (all_paths.items.len > 0) {
                var current_path = all_paths.pop();

                const curr_name = current_path.getLastOrNull() orelse unreachable;
                if (curr_name.ptr == end_node.name.ptr) {
                    try all_valid_paths.append(current_path);
                    continue;
                }

                defer current_path.deinit();

                const curr_node = self.getNode(curr_name) orelse return error.NodeNotFound;
                for (curr_node.neighbour.items) |neighbour| {
                    if (util.isUppercase(neighbour.name) or util.countInstances(neighbour.name, current_path.items) == 0) {
                        var new_path = std.ArrayList([]const u8).init(self.allocator);
                        try new_path.appendSlice(current_path.items);
                        try new_path.append(neighbour.name);
                        try all_paths.append(new_path);
                    }
                }
            }

            return all_valid_paths;
        }

        pub fn findAllPaths2(self: *Self, start: []const u8, end: []const u8) !u32 {
            var path_count: u32 = 0;

            var different_paths = try std.ArrayList(Path).initCapacity(self.allocator, 100000);
            defer different_paths.deinit();

            const start_node = self.getNode(start) orelse return error.StartNodeNotFound;
            const end_node = self.getNode(end) orelse return error.EndNodeNotFound;

            // Adding path item to
            var path_item = try Path.init(self.allocator);
            try path_item.nodes.append(start_node.name);

            try different_paths.append(path_item);

            while (different_paths.items.len > 0) {
                var current_path = different_paths.pop();
                defer current_path.deinit();

                const curr_name = current_path.nodes.getLastOrNull() orelse unreachable;
                if (end_node.name.ptr == curr_name.ptr) {
                    path_count += 1;
                    continue;
                }

                const curr_node = self.getNode(curr_name) orelse return error.NodeNotFound;
                for (curr_node.neighbour.items) |neighbour| {
                    // Not allowed to repeat start
                    if (start_node.name.ptr == neighbour.name.ptr) continue;

                    // Conditions for creating a new path
                    if (util.isUppercase(neighbour.name)) {
                        var new_path = try current_path.clone();
                        try new_path.nodes.append(neighbour.name);
                        try different_paths.append(new_path);
                    } else if (current_path.visitedTwice == false and util.countInstances(neighbour.name, current_path.nodes.items) == 1) {
                        var new_path = try current_path.clone();
                        try new_path.nodes.append(neighbour.name);
                        new_path.visitedTwice = true;
                        try different_paths.append(new_path);
                    } else if (util.countInstances(neighbour.name, current_path.nodes.items) == 0) {
                        var new_path = try current_path.clone();
                        try new_path.nodes.append(neighbour.name);
                        try different_paths.append(new_path);
                    }
                }
            }

            return path_count;
        }
    };
}

fn createGraph(allocator: std.mem.Allocator, lines: [][]const u8) *Graph() {
    var graph = allocator.create(Graph()) catch unreachable;
    errdefer allocator.destroy(graph);
    graph.* = Graph().init(allocator);
    errdefer graph.deinit();

    for (lines) |line| {
        var iter = std.mem.splitAny(u8, line, "-");
        const name1 = iter.next() orelse unreachable;
        const name2 = iter.next() orelse unreachable;

        if (!graph.containsNode(name1)) {
            graph.addNode(name1) catch |err| {
                std.debug.panic("Caught error when adding node: {s} - err: {}", .{ name1, err });
            };
        }
        if (!graph.containsNode(name2)) {
            graph.addNode(name2) catch |err| {
                std.debug.panic("Caught error when adding node: {s} - err: {}", .{ name2, err });
            };
        }
        graph.createEdge(name1, name2) catch |err| {
            std.debug.panic("Caught error when creating edge: {s} <-> {s} - err: {}", .{ name1, name2, err });
        };
    }

    return graph;
}

fn findAllPaths(graph: *Graph()) usize {
    var all_paths = graph.findAllPaths("start", "end") catch |err| {
        std.debug.panic("Failed to find all paths: {}", .{err});
    };
    defer all_paths.deinit();

    for (all_paths.items) |path| {
        defer path.deinit();
        // util.printSlice([]const u8, path.items);
    }

    return all_paths.items.len;
}

fn findAllPaths2(graph: *Graph()) usize {
    return graph.findAllPaths2("start", "end") catch |err| {
        std.debug.panic("Failed to find all paths: {}", .{err});
    };
}

pub fn part1(allocator: std.mem.Allocator) void {
    const lines = util.getLinesFromFile("day12.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    var graph = createGraph(allocator, lines.items);
    defer graph.deinit();

    std.debug.print("Part1 result: {}\n", .{findAllPaths(graph)});
}

pub fn part2(allocator: std.mem.Allocator) void {
    const lines = util.getLinesFromFile("day12.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    var graph = createGraph(allocator, lines.items);
    defer graph.deinit();

    std.debug.print("Part2 result: {}\n", .{findAllPaths2(graph)});
}

test "insertAndPrint" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var graph = Graph(bool).init(allocator);
    defer graph.deinit();

    try graph.addNode("start", false);
    try graph.setStartNode("start");
    try graph.addNode("A", true);
    try graph.addNode("b", false);
    try graph.addNode("c", false);
    try graph.addNode("d", false);
    try graph.addNode("end", false);
    try graph.createEdge("start", "A");
    try graph.createEdge("start", "b");
    try graph.createEdge("A", "c");
    try graph.createEdge("A", "b");
    try graph.createEdge("b", "d");
    try graph.createEdge("A", "end");
    try graph.createEdge("b", "end");

    graph.print();
}
