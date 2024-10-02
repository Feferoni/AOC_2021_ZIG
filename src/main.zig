const std = @import("std");
const day1 = @import("day1.zig");
const day2 = @import("day2.zig");
const day3 = @import("day3.zig");
const day4 = @import("day4.zig");
const day5 = @import("day5.zig");

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
    const allocator = gpa.allocator();

    // day1.part1(allocator);
    // day1.part2(allocator);
    // day2.part1(allocator);
    // day2.part2(allocator);
    // day3.part1(allocator);
    // day3.part2(allocator);
    // day4.part1(allocator);
    // day4.part2(allocator);
    day5.part1(allocator);
    day5.part2(allocator);
}
