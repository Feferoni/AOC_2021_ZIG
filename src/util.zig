const std = @import("std");

pub fn sumRange(comptime T: type, slice: []const T, start: usize, end: usize) T {
    var sum: T = 0;
    for (slice[start..end]) |num| {
        sum += num;
    }
    return sum;
}
