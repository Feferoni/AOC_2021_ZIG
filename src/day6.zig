const std = @import("std");
const util = @import("util.zig");

fn getInitalListOfFishes(allocator: std.mem.Allocator, lines: [][]const u8) []u64 {
    std.debug.assert(lines.len == 1);

    var fishList = allocator.alloc(u64, 9) catch unreachable;
    @memset(fishList, 0);

    var iterator = std.mem.tokenizeAny(u8, lines[0], ",");
    while (iterator.next()) |value_str| {
        const value = std.fmt.parseInt(u32, value_str, 10) catch unreachable;
        fishList[value] += 1;
    }

    return fishList;
}

fn calculateLaternFishesAfterDays(fishList: *[]u64, days: u32) u64 {
    var tmpFishList: [9]u64 = undefined;
    for (0..days) |_| {
        @memset(&tmpFishList, 0);

        var fishDay: usize = 8;
        while (fishDay >= 0) {
            switch (fishDay) {
                0 => {
                    tmpFishList[8] += fishList.*[fishDay];
                    tmpFishList[6] += fishList.*[fishDay];
                    break;
                },
                else => {
                    tmpFishList[fishDay - 1] += fishList.*[fishDay];
                    fishDay -= 1;
                },
            }
        }

        @memcpy(fishList.ptr, &tmpFishList);
    }

    return util.sumRange(u64, fishList.*, 0, fishList.len);
}

pub fn part1(allocator: std.mem.Allocator) void {
    const lines = util.getLinesFromFile("day6.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    var fishList = getInitalListOfFishes(allocator, lines.items);
    defer allocator.free(fishList);

    const days: u32 = 80;
    std.debug.print("Part1 result: {}\n", .{calculateLaternFishesAfterDays(&fishList, days)});
}

pub fn part2(allocator: std.mem.Allocator) void {
    const lines = util.getLinesFromFile("day6.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    var fishList = getInitalListOfFishes(allocator, lines.items);
    defer allocator.free(fishList);

    const days: u32 = 256;
    std.debug.print("Part2 result: {}\n", .{calculateLaternFishesAfterDays(&fishList, days)});
}
