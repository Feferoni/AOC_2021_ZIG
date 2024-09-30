const std = @import("std");
const day1 = @import("day1.zig");
const day2 = @import("day2.zig");
const day3 = @import("day3.zig");
const day4 = @import("day4.zig");

pub fn main() !void {
    day1.part1();
    day1.part2();
    day2.part1();
    day2.part2();
    day3.part1();
    day3.part2();
    day4.part1();
    day4.part2();
}
