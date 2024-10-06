const std = @import("std");
const util = @import("util.zig");

const Direction = enum {
    north,
    south,
    west,
    east,
    north_west,
    north_east,
    south_west,
    south_east,
};

const ALL_DIRECTIONS = blk: {
    const fields = std.meta.fields(Direction);
    var directions: [fields.len]Direction = undefined;
    for (fields, 0..) |field, i| {
        directions[i] = @field(Direction, field.name);
    }
    break :blk directions;
};

const Position = struct {
    x: i64,
    y: i64,
};

const MoveDirectivies = struct {
    direction: Direction,
    moveDistance: Position,
};
const move_directives = blk: {
    const pairs = [_]MoveDirectivies{
        .{
            .direction = Direction.north,
            .moveDistance = Position{ .x = 0, .y = -1 },
        },
        .{
            .direction = Direction.south,
            .moveDistance = Position{ .x = 0, .y = 1 },
        },
        .{
            .direction = Direction.west,
            .moveDistance = Position{ .x = -1, .y = 0 },
        },
        .{
            .direction = Direction.east,
            .moveDistance = Position{ .x = 1, .y = 0 },
        },
        .{
            .direction = Direction.north_west,
            .moveDistance = Position{ .x = -1, .y = -1 },
        },
        .{
            .direction = Direction.north_east,
            .moveDistance = Position{ .x = 1, .y = -1 },
        },
        .{
            .direction = Direction.south_west,
            .moveDistance = Position{ .x = -1, .y = 1 },
        },
        .{
            .direction = Direction.south_east,
            .moveDistance = Position{ .x = 1, .y = 1 },
        },
    };
    break :blk pairs;
};

fn getMoveDistance(direction: Direction) Position {
    for (move_directives) |directives| {
        if (directives.direction == direction) return directives.moveDistance;
    }

    unreachable;
}

fn getNewPosition(currPos: Position, direction: Direction) Position {
    const move_distance = getMoveDistance(direction);
    return Position{ .x = currPos.x + move_distance.x, .y = currPos.y - move_distance.y };
}

const Entry = struct {
    energyLevel: i64 = undefined,
    hasFlashed: bool = false,
};

const EnergyMap = struct {
    map: [][]Entry,
    allocator: std.mem.Allocator,
    flashesCounted: i64 = 0,

    fn init(allocator: std.mem.Allocator, lines: [][]const u8) EnergyMap {
        std.debug.assert(lines.len > 0);
        std.debug.assert(lines[0].len > 0);

        const rowsLen = lines.len;
        const colsLen = lines[0].len;

        const newMap = allocator.alloc([]Entry, rowsLen) catch unreachable;
        for (newMap) |*row| {
            row.* = allocator.alloc(Entry, colsLen) catch unreachable;
        }

        for (0..rowsLen) |row| {
            for (0..colsLen) |col| {
                newMap[row][col].energyLevel = lines[row][col] - '0';
            }
        }

        return EnergyMap{
            .map = newMap,
            .allocator = allocator,
        };
    }

    fn deinit(self: *const EnergyMap) void {
        for (self.map) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(self.map);
    }

    fn print(self: *const EnergyMap) void {
        const red = "\x1b[31m";
        const reset = "\x1b[0m";

        for (self.map) |row| {
            for (row) |entry| {
                if (entry.hasFlashed) {
                    std.debug.print("{s}{}{s}", .{ red, entry.energyLevel, reset });
                } else {
                    std.debug.print("{}", .{entry.energyLevel});
                }
            }
            std.debug.print("\n", .{});
        }
    }

    fn resetHasFlashed(self: *EnergyMap) void {
        for (self.map) |row| {
            for (row) |*entry| {
                if (entry.hasFlashed) {
                    entry.hasFlashed = false;
                }
            }
        }
    }

    fn hasAllFlashed(self: *EnergyMap) bool {
        for (self.map) |row| {
            for (row) |*entry| {
                if (!entry.hasFlashed) {
                    return false;
                }
            }
        }
        return true;
    }

    fn resetEnergyLevels(self: *EnergyMap) void {
        for (self.map) |row| {
            for (row) |*entry| {
                if (entry.hasFlashed) {
                    entry.energyLevel = 0;
                }
            }
        }
    }

    fn isPosInEneryMap(self: *const EnergyMap, pos: Position) bool {
        if (0 > pos.y or pos.y > self.map.len - 1) return false;
        if (0 > pos.x or pos.x > self.map[0].len - 1) return false;
        return true;
    }

    fn getNeigboursPosition(self: *const EnergyMap, currPos: Position, direction: Direction) ?Position {
        const neighbourPos = getNewPosition(currPos, direction);
        if (self.isPosInEneryMap(neighbourPos)) return neighbourPos else return null;
    }

    fn increaseEnergyToAll(self: *EnergyMap) void {
        for (self.map) |row| {
            for (row) |*entry| {
                entry.energyLevel += 1;
            }
        }
    }

    fn startFlashingSequence(self: *EnergyMap, startPos: Position) void {
        var flashQueue = std.ArrayList(Position).init(self.allocator);
        defer flashQueue.deinit();

        flashQueue.append(startPos) catch unreachable;
        while (flashQueue.popOrNull()) |currPos| {
            const currEntry = &self.map[@intCast(currPos.y)][@intCast(currPos.x)];
            if (currEntry.hasFlashed) continue;

            for (ALL_DIRECTIONS) |direction| {
                if (self.getNeigboursPosition(currPos, direction)) |neighboursPos| {
                    const neighboursEntry = &self.map[@intCast(neighboursPos.y)][@intCast(neighboursPos.x)];

                    neighboursEntry.*.energyLevel += 1;

                    if (neighboursEntry.hasFlashed) continue;

                    if (neighboursEntry.energyLevel > 9) {
                        flashQueue.append(neighboursPos) catch unreachable;
                    }
                }
            }

            currEntry.*.hasFlashed = true;
            self.flashesCounted += 1;
        }
    }

    fn handleFlashing(self: *EnergyMap) void {
        for (self.map, 0..) |row, y| {
            for (row, 0..) |entry, x| {
                if (entry.energyLevel > 9 and !entry.hasFlashed) {
                    const currPos = Position{ .x = @intCast(x), .y = @intCast(y) };
                    self.startFlashingSequence(currPos);
                }
            }
        }
    }

    fn simulateSteps(self: *EnergyMap, nrOfSteps: usize) void {
        // std.debug.print("Initial state:\n", .{});
        // self.print();
        for (1..nrOfSteps + 1) |_| {
            // 1. increaseEnergyLevels of all by 1
            self.increaseEnergyToAll();

            // 2. handle flashing for entries with energy level greater than 9
            // which increases neighbours energy by 1, they in turn can flash.
            self.handleFlashing();

            // 3. first resetting the flashed ones to 0, for improved debugging view
            self.resetEnergyLevels();

            // std.debug.print("After Step: {}\n", .{step});
            // self.print();

            // 3. reset hasFlashed, a bit
            self.resetHasFlashed();
        }
    }

    fn simulateUntilAllHasFlashed(self: *EnergyMap) u64 {
        // std.debug.print("Initial state:\n", .{});
        // self.print();
        var step: u64 = 1;
        while (true) : (step += 1) {
            // 1. increaseEnergyLevels of all by 1
            self.increaseEnergyToAll();

            // 2. handle flashing for entries with energy level greater than 9
            // which increases neighbours energy by 1, they in turn can flash.
            self.handleFlashing();

            // 3. first resetting the flashed ones to 0, for improved debugging view
            self.resetEnergyLevels();

            // std.debug.print("After Step: {}\n", .{step});
            // self.print();
            if (self.hasAllFlashed()) {
                return step;
            }

            // 3. reset hasFlashed, a bit
            self.resetHasFlashed();
        }
        unreachable;
    }
};

pub fn part1(allocator: std.mem.Allocator) void {
    const lines = util.getLinesFromFile("day11.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    var energyMap = EnergyMap.init(allocator, lines.items);
    defer energyMap.deinit();

    energyMap.simulateSteps(10000);
    std.debug.print("Part1 result: {}\n", .{energyMap.flashesCounted});
}

pub fn part2(allocator: std.mem.Allocator) void {
    const lines = util.getLinesFromFile("day11.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    var energyMap = EnergyMap.init(allocator, lines.items);
    defer energyMap.deinit();

    std.debug.print("Part2 result: {}\n", .{energyMap.simulateUntilAllHasFlashed()});
}
