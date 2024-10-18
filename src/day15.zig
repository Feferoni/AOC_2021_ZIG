const std = @import("std");
const util = @import("util.zig");

const Position = struct {
    x: usize,
    y: usize,

    fn init(allocator: std.mem.Allocator, x: usize, y: usize) *Position {
        const position = allocator.create(Position) catch unreachable;
        position.*.x = x;
        position.*.y = y;
        return position;
    }
};

const Map = struct {
    risk_map: [][]*MapEntry,
    allocator: std.mem.Allocator,

    const Self = @This();

    const MapEntry = struct {
        pos: *Position,
        risk_value: u8,
        risk_to_get_here: ?u32,
        visited: bool,
        came_from: ?*MapEntry,
        allocator: std.mem.Allocator,

        fn init(allocator: std.mem.Allocator, x: usize, y: usize, risk_value: u8) *MapEntry {
            const entry = allocator.create(MapEntry) catch unreachable;
            entry.*.pos = Position.init(allocator, x, y);
            entry.*.risk_value = risk_value;
            entry.*.came_from = null;
            entry.*.risk_to_get_here = null;
            entry.*.visited = false;
            return entry;
        }

        fn deinit(self: *MapEntry) void {
            self.allocator.free(self.pos);
            self.allocator.destroy(self);
        }
    };

    fn initPart1(allocator: std.mem.Allocator, lines: [][]const u8) Map {
        var cols = std.ArrayList([]*MapEntry).initCapacity(allocator, lines.len) catch unreachable;

        for (lines, 0..) |line, y| {
            var rows = std.ArrayList(*MapEntry).initCapacity(allocator, line.len) catch unreachable;
            for (line, 0..) |risk_level, x| {
                rows.append(MapEntry.init(allocator, x, y, risk_level - '0')) catch unreachable;
            }
            cols.append(rows.toOwnedSlice() catch unreachable) catch unreachable;
        }

        return Map{ .risk_map = cols.toOwnedSlice() catch unreachable, .allocator = allocator };
    }

    fn initPart2(allocator: std.mem.Allocator, lines: [][]const u8) Map {
        const col_len = lines.len * 5;
        var map = std.ArrayList([]*MapEntry).initCapacity(allocator, col_len) catch unreachable;

        for (lines, 0..) |line, y| {
            const row_len = line.len * 5;
            var row = std.ArrayList(*MapEntry).initCapacity(allocator, row_len) catch unreachable;
            for (line, 0..) |risk_level, x| {
                row.append(MapEntry.init(allocator, x, y, risk_level - '0')) catch unreachable;
            }

            for (line.len..row_len) |x| {
                const corresponding_entry = row.items[x - line.len];
                const new_risk_value = if (corresponding_entry.risk_value == 9) 1 else corresponding_entry.risk_value + 1;
                row.append(MapEntry.init(allocator, x, y, new_risk_value)) catch unreachable;
            }

            map.append(row.toOwnedSlice() catch unreachable) catch unreachable;
        }

        for (lines.len..col_len) |y| {
            const corresponding_row = map.items[y - lines.len];
            var new_row = std.ArrayList(*MapEntry).initCapacity(allocator, corresponding_row.len) catch unreachable;
            for (corresponding_row) |corresponding_entry| {
                const new_risk_value = if (corresponding_entry.risk_value == 9) 1 else corresponding_entry.risk_value + 1;
                new_row.append(MapEntry.init(allocator, corresponding_entry.pos.x, y, new_risk_value)) catch unreachable;
            }
            map.append(new_row.toOwnedSlice() catch unreachable) catch unreachable;
        }

        return Map{ .risk_map = map.toOwnedSlice() catch unreachable, .allocator = allocator };
    }

    fn deinit(self: *const Self) void {
        for (self.risk_map) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(self.risk_map);
    }

    fn getNeighbours(self: *const Self, entry: *const MapEntry) [4]?*MapEntry {
        std.debug.assert(self.risk_map.len > entry.pos.y);
        std.debug.assert(self.risk_map[0].len > entry.pos.x);

        var positions = [_]?*MapEntry{null} ** 4;

        if (entry.pos.y > 0) {
            const north_neighbour = self.risk_map[entry.pos.y - 1][entry.pos.x];
            positions[0] = north_neighbour;
        }

        if (entry.pos.y < self.risk_map.len - 1) {
            const south_neighbour = self.risk_map[entry.pos.y + 1][entry.pos.x];
            positions[1] = south_neighbour;
        }
        if (entry.pos.x > 0) {
            const west_neighbour = self.risk_map[entry.pos.y][entry.pos.x - 1];
            positions[2] = west_neighbour;
        }
        if (entry.pos.x < self.risk_map[0].len - 1) {
            const east_neighbour = self.risk_map[entry.pos.y][entry.pos.x + 1];
            positions[3] = east_neighbour;
        }

        return positions;
    }

    fn print(self: *const Self) void {
        for (self.risk_map) |cols| {
            for (cols) |entry| {
                std.debug.print("{}", .{entry.risk_value});
            }
            std.debug.print("\n", .{});
        }
    }

    fn printPath(self: *const Self, end: *MapEntry) void {
        var print_map = self.allocator.alloc([]u8, self.risk_map.len) catch unreachable;
        defer self.allocator.free(print_map);

        for (print_map, 0..) |*row, i| {
            row.* = self.allocator.alloc(u8, self.risk_map[i].len) catch unreachable;
            @memset(row.*, '.');
        }
        defer for (print_map) |row| {
            self.allocator.free(row);
        };

        var it: ?*MapEntry = end;
        while (true) {
            if (it == null) break;
            print_map[it.?.pos.y][it.?.pos.x] = '#';
            it = it.?.came_from;
        }

        for (print_map) |row| {
            std.debug.print("{s}\n", .{row});
        }
    }

    fn sortMapEntries(_: void, first: *MapEntry, second: *MapEntry) bool {
        return first.risk_to_get_here.? > second.risk_to_get_here.?;
    }

    fn getNextMapEntry(to_visit: *std.ArrayList(*MapEntry)) ?*MapEntry {
        if (to_visit.items.len == 0) return null;

        var best_index: usize = 0;
        var best_risk: u32 = std.math.maxInt(u32);

        for (to_visit.items, 0..) |entry, index| {
            if (entry.risk_to_get_here) |risk| {
                if (risk < best_risk) {
                    best_risk = risk;
                    best_index = index;
                }
            }
        }

        const best_entry = to_visit.orderedRemove(best_index);
        return best_entry;
    }

    fn containEntry(to_visit: *std.ArrayList(*MapEntry), to_check: *MapEntry) bool {
        for (to_visit.items) |entry| {
            if (std.meta.eql(entry.*, to_check.*)) return true;
        }

        return false;
    }

    fn findLowestRisk(self: *const Self) u32 {
        const start_pos = self.risk_map[0][0];
        start_pos.risk_to_get_here = 0;
        const end_pos = self.risk_map[self.risk_map.len - 1][self.risk_map[0].len - 1];

        var to_visit = std.ArrayList(*MapEntry).init(self.allocator);
        to_visit.append(start_pos) catch unreachable;

        while (getNextMapEntry(&to_visit)) |curr_map_entry| {
            curr_map_entry.visited = true;
            for (self.getNeighbours(curr_map_entry)) |neighbour| {
                if (neighbour == null) continue;

                const risk_to_go_there = curr_map_entry.risk_to_get_here.? + neighbour.?.risk_value;
                if (neighbour.?.risk_to_get_here == null) {
                    neighbour.?.risk_to_get_here = risk_to_go_there;
                    neighbour.?.came_from = curr_map_entry;
                } else {
                    if (neighbour.?.risk_to_get_here.? > risk_to_go_there) {
                        neighbour.?.risk_to_get_here = risk_to_go_there;
                        neighbour.?.came_from = curr_map_entry;
                    }
                }
                if (!neighbour.?.visited and !containEntry(&to_visit, neighbour.?)) {
                    to_visit.append(neighbour.?) catch unreachable;
                }

                if (std.meta.eql(neighbour.?.*, end_pos.*)) {
                    break;
                }
            }
        }

        return end_pos.risk_to_get_here.?;
    }
};

pub fn part1(allocator: std.mem.Allocator) void {
    const lines = util.getLinesFromFile("day15.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    const risk_map = Map.initPart1(allocator, lines.items);
    defer risk_map.deinit();

    std.debug.print("Part1 result: {}\n", .{risk_map.findLowestRisk()});
}

pub fn part2(allocator: std.mem.Allocator) void {
    const lines = util.getLinesFromFile("day15.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    const risk_map = Map.initPart2(allocator, lines.items);
    defer risk_map.deinit();

    std.debug.print("Part2 result: {}\n", .{risk_map.findLowestRisk()});
}
