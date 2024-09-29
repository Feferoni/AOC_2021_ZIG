const std = @import("std");
const readFile = @import("readFile.zig");

fn sumRange(slice: []const u32, start: usize, end: usize) u32 {
    var sum: u32 = 0;
    for (slice[start..end]) |num| {
        sum += num;
    }
    return sum;
}

fn convertStringsToNumbers(lines: std.ArrayList([]u8)) ![]u32 {
    var numbers = std.ArrayList(u32).init(std.heap.page_allocator);
    errdefer numbers.deinit();

    for (lines.items) |line| {
        const number = try std.fmt.parseInt(u32, line, 10);
        try numbers.append(number);
    }

    return numbers.toOwnedSlice();
}

fn getNumberOfIncreases1(depths: []const u32) u32 {
    var count: u32 = 0;

    for (depths[1..], 0..) |curr, i| {
        const prev = depths[i];
        if (curr > prev) count += 1;
    }

    return count;
}

fn getNumberOfIncreases2(depths: []const u32, window_size: u32) u32 {
    var count: u32 = 0;

    var i: usize = window_size + 1;
    var prev: u32 = sumRange(depths, 0, window_size);

    while (i <= depths.len) : (i += 1) {
        const curr = sumRange(depths, i - window_size, i);
        if (curr > prev) count += 1;
        prev = curr;
    }

    return count;
}

pub fn part1() !void {
    const lines = try readFile.getLinesFromFile("day1.txt");
    defer lines.deinit();

    const depthScan = try convertStringsToNumbers(lines);
    defer std.heap.page_allocator.free(depthScan);

    std.debug.print("part1 result: {}\n", .{getNumberOfIncreases1(depthScan)});
}

pub fn part2() !void {
    const lines = try readFile.getLinesFromFile("day1.txt");
    defer lines.deinit();

    const depthScan = try convertStringsToNumbers(lines);
    defer std.heap.page_allocator.free(depthScan);

    std.debug.print("part2 result: {}\n", .{getNumberOfIncreases2(depthScan, 3)});
}

test "part1" {
    const depthScan = [_]u32{ 199, 200, 208, 210, 200, 207, 240, 269, 260, 263 };
    try std.testing.expectEqual(7, getNumberOfIncreases1(&depthScan));
}

test "part2" {
    const depthScan = [_]u32{ 199, 200, 208, 210, 200, 207, 240, 269, 260, 263 };
    try std.testing.expectEqual(5, getNumberOfIncreases2(&depthScan, 3));
}
