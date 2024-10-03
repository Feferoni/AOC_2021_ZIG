const std = @import("std");
const util = @import("util.zig");

fn findOptimalPosition1(crab_positions: []const i64) struct { optimal: i64, fuel: u64 } {
    const n = crab_positions.len;
    var median: i64 = undefined;
    if (n % 2 == 1) {
        median = crab_positions[n / 2];
    } else {
        median = @divFloor(crab_positions[n / 2 - 1] + crab_positions[n / 2], 2);
    }

    var total_fuel: u64 = 0;
    for (crab_positions) |pos| {
        total_fuel += @abs(pos - median);
    }

    return .{ .optimal = median, .fuel = total_fuel };
}

fn calculateFuel(distance: u64) u64 {
    return (distance * (distance + 1)) / 2;
}

fn findOptimalPosition2(crab_positions: []const i64) struct { optimal: i64, fuel: u64 } {
    const min_pos = std.mem.min(i64, crab_positions);
    const max_pos = std.mem.max(i64, crab_positions);

    var optimal_pos: i64 = min_pos;
    var min_fuel: u64 = std.math.maxInt(u64);

    var current_pos = min_pos;
    while (current_pos <= max_pos) : (current_pos += 1) {
        var total_fuel: u64 = 0;

        for (crab_positions) |pos| {
            const distance = @abs(pos - current_pos);
            total_fuel += calculateFuel(distance);
        }

        if (total_fuel < min_fuel) {
            min_fuel = total_fuel;
            optimal_pos = current_pos;
        }
    }

    return .{ .optimal = optimal_pos, .fuel = min_fuel };
}

pub fn part1(allocator: std.mem.Allocator) void {
    const lines = util.getLinesFromFile("day7.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    std.debug.assert(lines.items.len == 1);

    const crab_positions = util.getNumbersFromLine(i64, allocator, lines.items[0], ",");
    defer allocator.free(crab_positions);

    std.sort.block(i64, crab_positions, {}, std.sort.asc(i64));
    const optimal = findOptimalPosition1(crab_positions);

    std.debug.print("Part1 result: {}\n", .{optimal.fuel});
}

pub fn part2(allocator: std.mem.Allocator) void {
    const lines = util.getLinesFromFile("day7.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }
    std.debug.assert(lines.items.len == 1);

    const crab_positions = util.getNumbersFromLine(i64, allocator, lines.items[0], ",");
    defer allocator.free(crab_positions);

    const optimal = findOptimalPosition2(crab_positions);

    std.debug.print("Part2 result: {}\n", .{optimal.fuel});
}
