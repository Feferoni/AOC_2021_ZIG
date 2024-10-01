const std = @import("std");
const readFile = @import("readFile.zig");

const BitCount = struct { zero: u32, one: u32 };

fn bitsToDecimal(bits: []const u8) u64 {
    if (bits.len > 64) {
        unreachable;
    }

    var result: u64 = 0;

    for (bits) |bit| {
        switch (bit) {
            '0' => result = (result << 1),
            '1' => result = (result << 1) | 1,
            else => unreachable,
        }
    }

    return result;
}

fn flipUpToMSB(num: u64) u64 {
    if (num == 0) return 0;

    var result: u64 = 0;
    var found_msb = false;

    var i: u6 = 63;
    while (true) : (i -%= 1) {
        const bit = (num >> i) & 1;
        if (bit == 1) found_msb = true;
        if (found_msb) result |= (1 - bit) << i;
        if (i == 0) break;
    }

    return result;
}

fn calculateBitCountsByIndex(lines: std.ArrayList([]u8), index: usize) BitCount {
    var bitCount = BitCount{ .zero = 0, .one = 0 };
    for (lines.items) |line| {
        if (line[index] == '0') {
            bitCount.zero += 1;
        } else if (line[index] == '1') {
            bitCount.one += 1;
        }
    }
    return bitCount;
}

fn calculateBitCounts(allocator: std.mem.Allocator, lines: std.ArrayList([]u8)) []BitCount {
    std.debug.assert(lines.items.len > 0);
    std.debug.assert(lines.items[0].len > 0);

    const nrOfBits = lines.items[0].len;

    var bitCounts = allocator.alloc(BitCount, nrOfBits) catch unreachable;
    @memset(bitCounts, BitCount{ .zero = 0, .one = 0 });

    for (0..nrOfBits) |i| {
        bitCounts[i] = calculateBitCountsByIndex(lines, i);
    }

    return bitCounts;
}

fn convertBitCountToGamma(allocator: std.mem.Allocator, bitCounts: []const BitCount) u64 {
    if (bitCounts.len == 0) return 0;

    var bits = allocator.alloc(u8, bitCounts.len) catch unreachable;
    defer allocator.free(bits);

    for (bitCounts, 0..) |bitCount, i| {
        bits[i] = if (bitCount.one > bitCount.zero) '1' else '0';
    }

    return bitsToDecimal(bits);
}

fn getBitToKeep(keepMostPresentBit: bool, bitCount: BitCount) u8 {
    // When keepMostPresent is true, that means if there are equal 0 and 1 bits, keep 1. Otherwise keep the one with the highest count.
    // When keepMostPresent is false, that means if there are equal 0 and 1 bits, keep 0. Otherwise keep the one with the lowest count.
    if (bitCount.one == bitCount.zero) {
        if (keepMostPresentBit) {
            return '1';
        } else {
            return '0';
        }
    }

    if (keepMostPresentBit) {
        return if (bitCount.zero > bitCount.one) '0' else '1';
    } else {
        return if (bitCount.zero > bitCount.one) '1' else '0';
    }
}

fn getPartTwoValue(lines: std.ArrayList([]u8), keepMostPresentBit: bool) u64 {
    // Make temporary since we need to remove lines, and lines needs to be used again
    var lines_tmp = lines.clone() catch unreachable;
    defer lines_tmp.deinit();

    var i: usize = 0;
    while (i < lines_tmp.items[0].len) : (i += 1) {
        const bit_counts = calculateBitCountsByIndex(lines_tmp, i);
        const bit_to_keep = getBitToKeep(keepMostPresentBit, bit_counts);

        var j: usize = lines_tmp.items.len;
        while (j > 0) {
            j -= 1;
            const current_bit = lines_tmp.items[j][i];
            if (!(bit_to_keep == current_bit)) {
                _ = lines_tmp.orderedRemove(j);

                if (lines_tmp.items.len == 1) {
                    return bitsToDecimal(lines_tmp.items[0]);
                }
            }
        }
    }

    unreachable;
}

pub fn part1(allocator: std.mem.Allocator) void {
    const lines = readFile.getLinesFromFile("day3.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    const bitCounts = calculateBitCounts(allocator, lines);
    defer allocator.free(bitCounts);
    const gammaRate = convertBitCountToGamma(allocator, bitCounts);
    const epsilonRate = flipUpToMSB(gammaRate);

    std.debug.print("Part1 result: {}\n", .{gammaRate * epsilonRate});
}

pub fn part2(allocator: std.mem.Allocator) void {
    var lines = readFile.getLinesFromFile("day3.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    const oxygen_generator_rating = getPartTwoValue(lines, true);
    const co2_scrubber_rating = getPartTwoValue(lines, false);

    std.debug.print("Part2 result: {}\n", .{oxygen_generator_rating * co2_scrubber_rating});
}

test "bitsToNumber" {
    try std.testing.expectEqual(@as(u64, 0), bitsToDecimal("0000"));
    try std.testing.expectEqual(@as(u64, 1), bitsToDecimal("0001"));
    try std.testing.expectEqual(@as(u64, 2), bitsToDecimal("0010"));
    try std.testing.expectEqual(@as(u64, 4), bitsToDecimal("0100"));
    try std.testing.expectEqual(@as(u64, 8), bitsToDecimal("1000"));
    try std.testing.expectEqual(@as(u64, 14), bitsToDecimal("1110"));
    try std.testing.expectEqual(@as(u64, 15), bitsToDecimal("1111"));
}

test "flipUpToMSB" {
    try std.testing.expectEqual(bitsToDecimal("00000111"), flipUpToMSB(bitsToDecimal("00001000")));
    try std.testing.expectEqual(bitsToDecimal("00000101"), flipUpToMSB(bitsToDecimal("00001010")));
    try std.testing.expectEqual(bitsToDecimal("01111111"), flipUpToMSB(bitsToDecimal("10000000")));
    try std.testing.expectEqual(bitsToDecimal("00000000"), flipUpToMSB(bitsToDecimal("00000001")));
}

test "part1" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const lines = readFile.getLinesFromFile("day3_test.txt", allocator);

    const bitCounts = calculateBitCounts(allocator, lines);
    defer allocator.free(bitCounts);
    const gammaRate = convertBitCountToGamma(allocator, bitCounts);
    const epsilonRate = flipUpToMSB(gammaRate);
    try std.testing.expectEqual(@as(u64, 22), gammaRate);
    try std.testing.expectEqual(@as(u64, 9), epsilonRate);
}

test "part2" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const lines = readFile.getLinesFromFile("day3_test.txt", allocator);

    try std.testing.expectEqual(@as(u64, 23), getPartTwoValue(lines, true));
    try std.testing.expectEqual(@as(u64, 10), getPartTwoValue(lines, false));
}
