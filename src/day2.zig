const std = @import("std");
const readFile = @import("readFile.zig");

const Direction = enum { forward, down, up };
const Instruction = struct { direction: Direction, distance: u32 };

fn getDirectionFromString(direction_str: []const u8) !Direction {
    if (std.mem.eql(u8, "forward", direction_str)) return Direction.forward;
    if (std.mem.eql(u8, "down", direction_str)) return Direction.down;
    if (std.mem.eql(u8, "up", direction_str)) return Direction.up;

    return error.InvalidDirectionStr;
}

fn convertLinesToInstructions(lines: std.ArrayList([]const u8)) ![]Instruction {
    var instructions = std.ArrayList(Instruction).init(std.heap.page_allocator);
    errdefer instructions.deinit();

    for (lines.items) |line| {
        var iterator = std.mem.splitAny(u8, line, " ");

        const direction_str = iterator.next() orelse return error.faultyDirection;
        const direction = try getDirectionFromString(direction_str);

        const value_str = iterator.next() orelse return error.faultyValue;
        const distance = try std.fmt.parseInt(u32, value_str, 10);

        const instruction = Instruction{ .direction = direction, .distance = distance };
        try instructions.append(instruction);
    }

    return instructions.toOwnedSlice();
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

pub fn part1() !void {
    const lines = try readFile.getLinesFromFile("day2.txt");
    defer lines.deinit();

    const instructions = try convertLinesToInstructions(lines);
    defer std.heap.page_allocator.free(instructions);

    std.debug.print("Part1 value: {}\n", .{getPart1Value(instructions)});
}

pub fn part2() !void {
    const lines = try readFile.getLinesFromFile("day2.txt");
    defer lines.deinit();

    const instructions = try convertLinesToInstructions(lines);
    defer std.heap.page_allocator.free(instructions);

    std.debug.print("Part2 value: {}\n", .{getPart2Value(instructions)});
}

test "part1" {
    const lines = try readFile.getLinesFromFile("day2_test.txt");
    defer lines.deinit();

    const instructions = try convertLinesToInstructions(lines);
    defer std.heap.page_allocator.free(instructions);

    try std.testing.expectEqual(150, getPart1Value(&instructions));
}

test "part2" {
    const lines = try readFile.getLinesFromFile("day2_test.txt");
    defer lines.deinit();

    const instructions = try convertLinesToInstructions(lines);
    defer std.heap.page_allocator.free(instructions);

    try std.testing.expectEqual(900, getPart2Value(&instructions));
}
