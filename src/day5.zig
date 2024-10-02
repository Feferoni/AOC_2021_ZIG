const std = @import("std");
const readFile = @import("readFile.zig");

const Direction = enum {
    north,
    south,
    east,
    west,
    north_west,
    north_east,
    south_west,
    south_east,
};

const VentPlacement = struct {
    x1: u32,
    x2: u32,
    y1: u32,
    y2: u32,

    fn isHorizontal(self: *const VentPlacement) bool {
        return self.y1 == self.y2;
    }

    fn isVertical(self: *const VentPlacement) bool {
        return self.x1 == self.x2;
    }

    fn isPointingNorth(self: *const VentPlacement) bool {
        return self.y1 > self.y2;
    }

    fn isPointingSouth(self: *const VentPlacement) bool {
        return !self.isPointingNorth();
    }

    fn isPointingWest(self: *const VentPlacement) bool {
        return self.x1 > self.x2;
    }

    fn isPointingEast(self: *const VentPlacement) bool {
        return !self.isPointingWest();
    }

    fn getDirection(self: *const VentPlacement) Direction {
        if (self.isHorizontal()) {
            if (self.isPointingWest()) {
                return Direction.west;
            } else {
                return Direction.east;
            }
        }
        if (self.isVertical()) {
            if (self.isPointingNorth()) {
                return Direction.north;
            } else {
                return Direction.south;
            }
        }

        if (self.isPointingNorth()) {
            if (self.isPointingWest()) {
                return Direction.north_west;
            } else {
                return Direction.north_east;
            }
        } else {
            if (self.isPointingWest()) {
                return Direction.south_west;
            } else {
                return Direction.south_east;
            }
        }
    }

    fn getSteps(self: *const VentPlacement) u32 {
        const x_step = if (self.x1 > self.x2) self.x1 - self.x2 else self.x2 - self.x1;
        if (x_step != 0) return x_step;
        return if (self.y1 > self.y2) self.y1 - self.y2 else self.y2 - self.y1;
    }

    fn isDiagonal(self: *const VentPlacement) bool {
        return !self.isVertical() and !self.isHorizontal();
    }

    fn print(self: *const VentPlacement) void {
        std.debug.print("{},{} -> {},{}: Direction: {} \n", .{
            self.x1,
            self.y1,
            self.x2,
            self.y2,
            self.getDirection(),
        });
    }
};

fn getVentPlacements(allocator: std.mem.Allocator, lines: [][]const u8) []VentPlacement {
    var ventPlacements = std.ArrayList(VentPlacement).init(allocator);
    errdefer {
        for (ventPlacements) |ventPlacement| {
            allocator.free(ventPlacement);
        }
        ventPlacements.deinit();
    }

    for (lines) |line| {
        var iterator = std.mem.tokenizeAny(u8, line, " ,->");
        ventPlacements.append(VentPlacement{
            .x1 = std.fmt.parseInt(u32, iterator.next() orelse unreachable, 10) catch unreachable,
            .y1 = std.fmt.parseInt(u32, iterator.next() orelse unreachable, 10) catch unreachable,
            .x2 = std.fmt.parseInt(u32, iterator.next() orelse unreachable, 10) catch unreachable,
            .y2 = std.fmt.parseInt(u32, iterator.next() orelse unreachable, 10) catch unreachable,
        }) catch unreachable;
    }

    return ventPlacements.toOwnedSlice() catch unreachable;
}

const MaxValues = struct {
    x_max: u32,
    y_max: u32,
};

fn getMaxValues(ventPlacements: []const VentPlacement) MaxValues {
    var maxValues = MaxValues{ .x_max = 0, .y_max = 0 };

    for (ventPlacements) |ventPlacement| {
        if (ventPlacement.x1 > maxValues.x_max) maxValues.x_max = ventPlacement.x1;
        if (ventPlacement.x2 > maxValues.x_max) maxValues.x_max = ventPlacement.x2;
        if (ventPlacement.y1 > maxValues.y_max) maxValues.y_max = ventPlacement.y1;
        if (ventPlacement.y2 > maxValues.y_max) maxValues.y_max = ventPlacement.y2;
    }

    return maxValues;
}

fn getVentPlacementMap(allocator: std.mem.Allocator, maxValues: MaxValues, ventPlacements: []const VentPlacement, useDiagonal: bool) [][]u32 {
    var map = allocator.alloc([]u32, maxValues.y_max + 1) catch unreachable;
    errdefer allocator.free(map);

    for (map) |*row| {
        row.* = allocator.alloc(u32, maxValues.x_max + 1) catch unreachable;
        @memset(row.*, 0);
    }

    for (ventPlacements) |ventPlacement| {
        const steps = ventPlacement.getSteps() + 1;
        const x_start = ventPlacement.x1;
        const y_start = ventPlacement.y1;
        const direction = ventPlacement.getDirection();

        switch (direction) {
            Direction.north => {
                for (0..steps) |step| {
                    map[y_start - step][x_start] += 1;
                }
            },
            Direction.south => {
                for (0..steps) |step| {
                    map[y_start + step][x_start] += 1;
                }
            },
            Direction.west => {
                for (0..steps) |step| {
                    map[y_start][x_start - step] += 1;
                }
            },
            Direction.east => {
                for (0..steps) |step| {
                    map[y_start][x_start + step] += 1;
                }
            },
            else => {},
        }

        if (useDiagonal and ventPlacement.isDiagonal()) {
            switch (direction) {
                Direction.north_west => {
                    for (0..steps) |step| {
                        map[y_start - step][x_start - step] += 1;
                    }
                },
                Direction.north_east => {
                    for (0..steps) |step| {
                        map[y_start - step][x_start + step] += 1;
                    }
                },
                Direction.south_west => {
                    for (0..steps) |step| {
                        map[y_start + step][x_start - step] += 1;
                    }
                },
                Direction.south_east => {
                    for (0..steps) |step| {
                        map[y_start + step][x_start + step] += 1;
                    }
                },
                else => {},
            }
        }
    }

    return map;
}

fn getDangerNumber(ventPlacementMap: [][]const u32) u32 {
    var dangerNumber: u32 = 0;
    for (ventPlacementMap) |ventPlacementRow| {
        for (ventPlacementRow) |value| {
            if (value > 1) {
                dangerNumber += 1;
            }
        }
    }

    return dangerNumber;
}

pub fn part1(allocator: std.mem.Allocator) void {
    const lines = readFile.getLinesFromFile("day5.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    const ventPlacements = getVentPlacements(allocator, lines.items);
    defer {
        allocator.free(ventPlacements);
    }

    const maxValues = getMaxValues(ventPlacements);
    const useDiagonal: bool = false;
    const ventPlacementMap = getVentPlacementMap(allocator, maxValues, ventPlacements, useDiagonal);
    defer {
        for (ventPlacementMap) |ventPlacementRow| {
            allocator.free(ventPlacementRow);
        }
        allocator.free(ventPlacementMap);
    }

    std.debug.print("Part1 result: {}\n", .{getDangerNumber(ventPlacementMap)});
}

pub fn part2(allocator: std.mem.Allocator) void {
    const lines = readFile.getLinesFromFile("day5.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    const ventPlacements = getVentPlacements(allocator, lines.items);
    defer {
        allocator.free(ventPlacements);
    }

    const maxValues = getMaxValues(ventPlacements);
    const useDiagonal: bool = true;
    const ventPlacementMap = getVentPlacementMap(allocator, maxValues, ventPlacements, useDiagonal);
    defer {
        for (ventPlacementMap) |ventPlacementRow| {
            allocator.free(ventPlacementRow);
        }
        allocator.free(ventPlacementMap);
    }

    std.debug.print("Part2 result: {}\n", .{getDangerNumber(ventPlacementMap)});
}
