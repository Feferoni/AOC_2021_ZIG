const std = @import("std");

pub fn sumRange(slice: []const u32, start: usize, end: usize) u32 {
    var sum: u32 = 0;
    for (slice[start..end]) |num| {
        sum += num;
    }
    return sum;
}
