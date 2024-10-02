const std = @import("std");
const readFile = @import("readFile.zig");

const Direction = enum { forward, down, up };
const Instruction = struct { direction: Direction, distance: u32 };

fn getDirectionFromString(direction_str: []const u8) Direction {
    if (std.mem.eql(u8, "forward", direction_str)) return Direction.forward;
    if (std.mem.eql(u8, "down", direction_str)) return Direction.down;
    if (std.mem.eql(u8, "up", direction_str)) return Direction.up;

    unreachable;
}

fn convertLinesToInstructions(allocator: std.mem.Allocator, lines: std.ArrayList([]u8)) []Instruction {
    var instructions = std.ArrayList(Instruction).init(allocator);
    errdefer instructions.deinit();

    for (lines.items) |line| {
        var iterator = std.mem.splitAny(u8, line, " ");

        const direction_str = iterator.next() orelse unreachable;
        const direction = getDirectionFromString(direction_str);

        const value_str = iterator.next() orelse unreachable;
        const distance = std.fmt.parseInt(u32, value_str, 10) catch |err| {
            std.debug.panic("Failed to parse \"{s}\" to int - err: {}", .{ value_str, err });
        };

        const instruction = Instruction{ .direction = direction, .distance = distance };
        instructions.append(instruction) catch unreachable;
    }

    return instructions.toOwnedSlice() catch unreachable;
}

fn getPart1Value(instructions: []const Instruction) u32 {
    var depth: u32 = 0;
    var distance: u32 = 0;

    for (instructions) |instruction| {
        switch (instruction.direction) {
            Direction.forward => distance += instruction.distance,
            Direction.down => depth += instruction.distance,
            Direction.up => depth -= instruction.distance,
        }
    }

    return depth * distance;
}

fn getPart2Value(instructions: []const Instruction) u32 {
    var depth: u32 = 0;
    var distance: u32 = 0;
    var aim: u32 = 0;

    for (instructions) |instruction| {
        switch (instruction.direction) {
            Direction.forward => {
                distance += instruction.distance;
                depth += aim * instruction.distance;
            },
            Direction.down => aim += instruction.distance,
            Direction.up => aim -= instruction.distance,
        }
    }

    return depth * distance;
}

pub fn part1(allocator: std.mem.Allocator) void {
    const lines = readFile.getLinesFromFile("day2.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    const instructions = convertLinesToInstructions(allocator, lines);
    defer allocator.free(instructions);

    std.debug.print("Part1 result: {}\n", .{getPart1Value(instructions)});
}

pub fn part2(allocator: std.mem.Allocator) void {
    const lines = readFile.getLinesFromFile("day2.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    const instructions = convertLinesToInstructions(allocator, lines);
    defer allocator.free(instructions);

    std.debug.print("Part2 result: {}\n", .{getPart2Value(instructions)});
}

test "part1" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const lines = readFile.getLinesFromFile("day2_test.txt", allocator);

    const instructions = convertLinesToInstructions(allocator, lines);
    defer allocator.free(instructions);

    try std.testing.expectEqual(@as(u32, 150), getPart1Value(instructions));
}

test "part2" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const lines = readFile.getLinesFromFile("day2_test.txt", allocator);

    const instructions = convertLinesToInstructions(allocator, lines);
    defer allocator.free(instructions);

    try std.testing.expectEqual(@as(u32, 900), getPart2Value(instructions));
}
