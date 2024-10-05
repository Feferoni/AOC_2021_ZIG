const std = @import("std");
const util = @import("util.zig");

const Position = struct {
    x: usize,
    y: usize,
};

const Entry = struct {
    height: u32,
    basinNumber: ?u32 = null,
};

const HeightMap = struct {
    map: [][]Entry,
    allocator: std.mem.Allocator,
    numberOfBasins: u32 = 0,

    fn init(allocator: std.mem.Allocator, rowsLen: usize, colsLen: usize, defaultValue: u32) HeightMap {
        const newMap = allocator.alloc([]Entry, rowsLen) catch unreachable;
        for (newMap) |*row| {
            row.* = allocator.alloc(Entry, colsLen) catch unreachable;
            @memset(row.*, Entry{ .height = defaultValue });
        }

        return HeightMap{
            .map = newMap,
            .allocator = allocator,
        };
    }

    fn deinit(self: *const HeightMap) void {
        for (self.map) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(self.map);
    }

    fn print(self: *const HeightMap) void {
        for (self.map) |row| {
            for (row) |entry| {
                std.debug.print("{}", .{entry.height});
            }
            std.debug.print("\n", .{});
        }
    }

    fn printBasin(self: *const HeightMap) void {
        for (self.map) |row| {
            for (row) |entry| {
                if (entry.basinNumber) |basinNumber| {
                    std.debug.print("{}", .{basinNumber});
                } else {
                    std.debug.print("x", .{});
                }
            }
            std.debug.print("\n", .{});
        }
    }

    fn isLowPoint(self: *const HeightMap, pos: Position) bool {
        std.debug.assert(pos.y < self.map.len);
        std.debug.assert(pos.x < self.map[pos.y].len);

        const currentHeigt = self.map[pos.y][pos.x].height;
        const y_max = self.map.len - 1;
        const x_max = self.map[0].len - 1;

        const westHeigher = if (pos.x == 0 or (pos.x > 0 and currentHeigt < self.map[pos.y][pos.x - 1].height)) true else false;
        const eastHeigher = if (pos.x == x_max or (pos.x < x_max and currentHeigt < self.map[pos.y][pos.x + 1].height)) true else false;
        const northHeigher = if (pos.y == 0 or (pos.y > 0 and currentHeigt < self.map[pos.y - 1][pos.x].height)) true else false;
        const southHeigher = if (pos.y == y_max or (pos.y < y_max and currentHeigt < self.map[pos.y + 1][pos.x].height)) true else false;

        return westHeigher and eastHeigher and northHeigher and southHeigher;
    }

    fn isPosInUndefinedBasin(self: *const HeightMap, pos: Position) bool {
        if (pos.y > self.map.len - 1) return false;
        if (pos.x > self.map[0].len - 1) return false;
        if (self.map[pos.y][pos.x].height == 9) return false;
        return if (self.map[pos.y][pos.x].basinNumber == null) true else false;
    }
};

fn getHeightMap(allocator: std.mem.Allocator, lines: [][]const u8) HeightMap {
    std.debug.assert(lines.len > 0);
    std.debug.assert(lines[0].len > 0);

    const rowsLen = lines.len;
    const colsLen = lines[0].len;

    const map = HeightMap.init(allocator, rowsLen, colsLen, undefined);
    for (map.map, 0..) |*row, y| {
        for (row.*, 0..) |*entry, x| {
            const height: u32 = lines[y][x] - '0';
            entry.*.height = height;
        }
    }

    return map;
}

fn traverseAndSetBasin(heightMap: *HeightMap, startPos: Position) void {
    // Since this is either not in a basin, or is already defined, we dont need to traverse this position
    if (!heightMap.isPosInUndefinedBasin(startPos)) return;

    var visitQueue = std.ArrayList(Position).init(heightMap.allocator);
    defer visitQueue.deinit();
    visitQueue.append(startPos) catch unreachable;

    while (visitQueue.popOrNull()) |currentPos| {
        heightMap.*.map[currentPos.y][currentPos.x].basinNumber = heightMap.numberOfBasins;

        // get neighbours and add to visitQueue if they haven't been visited
        if (currentPos.y > 0) {
            const northNeighbour = Position{ .x = currentPos.x, .y = currentPos.y - 1 };
            if (heightMap.isPosInUndefinedBasin(northNeighbour)) visitQueue.append(northNeighbour) catch unreachable;
        }
        if (currentPos.y < heightMap.map.len - 1) {
            const southNeighbour = Position{ .x = currentPos.x, .y = currentPos.y + 1 };
            if (heightMap.isPosInUndefinedBasin(southNeighbour)) visitQueue.append(southNeighbour) catch unreachable;
        }
        if (currentPos.x > 0) {
            const westNeighbour = Position{ .x = currentPos.x - 1, .y = currentPos.y };
            if (heightMap.isPosInUndefinedBasin(westNeighbour)) visitQueue.append(westNeighbour) catch unreachable;
        }
        if (currentPos.x < heightMap.map[0].len - 1) {
            const eastNeighbour = Position{ .x = currentPos.x + 1, .y = currentPos.y };
            if (heightMap.isPosInUndefinedBasin(eastNeighbour)) visitQueue.append(eastNeighbour) catch unreachable;
        }
    }

    heightMap.*.numberOfBasins += 1;
}

fn mapBasins(heightMap: *HeightMap) void {
    for (heightMap.map, 0..) |row, y| {
        for (row, 0..) |_, x| {
            const currPos = Position{ .x = x, .y = y };
            traverseAndSetBasin(heightMap, currPos);
        }
    }
}

fn getSumOfRiskLevel(heightMap: HeightMap) u32 {
    var riskLevel: u32 = 0;
    for (0..heightMap.map.len) |y| {
        for (0..heightMap.map[y].len) |x| {
            if (heightMap.isLowPoint(Position{ .x = x, .y = y })) {
                riskLevel += 1 + heightMap.map[y][x].height;
            }
        }
    }
    return riskLevel;
}

fn getThreeLargestBasinScore(heightMap: HeightMap) u32 {
    var basinsCounter = heightMap.allocator.alloc(u32, heightMap.numberOfBasins) catch unreachable;
    @memset(basinsCounter, 0);
    defer heightMap.allocator.free(basinsCounter);

    for (heightMap.map) |row| {
        for (row) |entry| {
            if (entry.basinNumber) |basinNumber| {
                basinsCounter[basinNumber] += 1;
            }
        }
    }

    std.sort.block(u32, basinsCounter, {}, std.sort.desc(u32));

    return util.multiplyRange(u32, basinsCounter, 0, 3);
}

pub fn part1(allocator: std.mem.Allocator) void {
    const lines = util.getLinesFromFile("day9.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    const heightMap = getHeightMap(allocator, lines.items);
    defer heightMap.deinit();
    std.debug.print("Part1 result: {}\n", .{getSumOfRiskLevel(heightMap)});
}

pub fn part2(allocator: std.mem.Allocator) void {
    const lines = util.getLinesFromFile("day9.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    var heightMap = getHeightMap(allocator, lines.items);
    defer heightMap.deinit();
    mapBasins(&heightMap);

    std.debug.print("Part2 result: {}\n", .{getThreeLargestBasinScore(heightMap)});
}
