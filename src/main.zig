const std = @import("std");
const day1 = @import("day1.zig");
const day2 = @import("day2.zig");
const day3 = @import("day3.zig");
const day4 = @import("day4.zig");
const day5 = @import("day5.zig");
const day6 = @import("day6.zig");
const day7 = @import("day7.zig");
const day8 = @import("day8.zig");
const day9 = @import("day9.zig");
const day10 = @import("day10.zig");
const day11 = @import("day11.zig");
const day12 = @import("day12.zig");
const day13 = @import("day13.zig");
const day14 = @import("day14.zig");
const day15 = @import("day15.zig");
const day16 = @import("day16.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        switch (leaked) {
            .ok => {},
            .leak => {
                std.debug.print("Leaked", .{});
            },
        }
    }
    const gpa_allocator = gpa.allocator();

    var arena = std.heap.ArenaAllocator.init(gpa_allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    // day1.part1(arena_allocator);
    // day1.part2(arena_allocator);
    // day2.part1(arena_allocator);
    // day2.part2(arena_allocator);
    // day3.part1(arena_allocator);
    // day3.part2(arena_allocator);
    // day4.part1(arena_allocator);
    // day4.part2(arena_allocator);
    // day5.part1(arena_allocator);
    // day5.part2(arena_allocator);
    // day6.part1(arena_allocator);
    // day6.part2(arena_allocator);
    // day7.part1(arena_allocator);
    // day7.part2(arena_allocator);
    // day8.part1(arena_allocator);
    // day8.part2(arena_allocator);
    // day9.part1(arena_allocator);
    // day9.part2(arena_allocator);
    // day10.part1(arena_allocator);
    // day10.part2(arena_allocator);
    // day11.part1(arena_allocator);
    // day11.part2(arena_allocator);
    // day12.part1(arena_allocator);
    // day12.part2(arena_allocator);
    // day13.part1(arena_allocator);
    // day13.part2(arena_allocator);
    // day14.part1(arena_allocator);
    // day14.part2(arena_allocator);
    // day15.part1(arena_allocator);
    // day15.part2(arena_allocator);
    day16.part1(arena_allocator);
    day16.part2(arena_allocator);
}
