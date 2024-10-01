const std = @import("std");
const readFile = @import("readFile.zig");
const util = @import("util.zig");

fn convertStringsToNumbers(lines: std.ArrayList([]u8)) []u32 {
    var numbers = std.ArrayList(u32).init(std.heap.page_allocator);
    errdefer numbers.deinit();

    for (lines.items) |line| {
        const number = std.fmt.parseInt(u32, line, 10) catch |err| {
            std.debug.panic("Failed to parse \"{s}\" to an int - err: {}", .{ line, err });
        };

        numbers.append(number) catch unreachable;
    }

    return numbers.toOwnedSlice() catch unreachable;
}

fn getIncreaseCount(depths: []const u32) u32 {
    var count: u32 = 0;

    for (depths[1..], 0..) |curr, i| {
        const prev = depths[i];
        if (curr > prev) count += 1;
    }

    return count;
}

fn getIncreaseCountSlidingWindow(depths: []const u32, window_size: u32) u32 {
    var count: u32 = 0;

    var i: usize = window_size + 1;
    var prev: u32 = util.sumRange(depths, @as(usize, 0), window_size);

    while (i <= depths.len) : (i += 1) {
        const curr = util.sumRange(depths, i - window_size, i);
        if (curr > prev) count += 1;
        prev = curr;
    }

    return count;
}

pub fn part1(allocator: std.mem.Allocator) void {
    const lines = readFile.getLinesFromFile("day1.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    const depthScan = convertStringsToNumbers(lines);
    defer std.heap.page_allocator.free(depthScan);

    std.debug.print("part1 result: {}\n", .{getIncreaseCount(depthScan)});
}

pub fn part2(allocator: std.mem.Allocator) void {
    const lines = readFile.getLinesFromFile("day1.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    const depthScan = convertStringsToNumbers(lines);
    defer std.heap.page_allocator.free(depthScan);

    std.debug.print("part2 result: {}\n", .{getIncreaseCountSlidingWindow(depthScan, 3)});
}

test "part1" {
    const depthScan = [_]u32{ 199, 200, 208, 210, 200, 207, 240, 269, 260, 263 };
    try std.testing.expectEqual(7, getIncreaseCount(&depthScan));
}

test "part2" {
    const depthScan = [_]u32{ 199, 200, 208, 210, 200, 207, 240, 269, 260, 263 };
    try std.testing.expectEqual(5, getIncreaseCountSlidingWindow(&depthScan, 3));
}
