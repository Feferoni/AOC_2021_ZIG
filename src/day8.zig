const std = @import("std");
const util = @import("util.zig");

const FaultyData = struct {
    signalPatterns: [][]u8,
    digits: [][]u8,

    fn print(self: *const FaultyData) void {
        std.debug.print("SignalPatterns: ", .{});
        for (self.signalPatterns) |signalPattern| {
            std.debug.print("{s},", .{signalPattern});
        }
        std.debug.print("\nDigits: ", .{});
        for (self.digits) |digit| {
            std.debug.print("{s},", .{digit});
        }
        std.debug.print("\n", .{});
    }
};

fn parseString(allocator: std.mem.Allocator, string: []const u8) [][]u8 {
    var parsedList = std.ArrayList([]u8).init(allocator);

    var iterator = std.mem.tokenizeAny(u8, string, " ");
    while (iterator.next()) |parsed_str| {
        const dup = allocator.dupe(u8, parsed_str) catch unreachable;
        parsedList.append(dup) catch unreachable;
    }

    return parsedList.toOwnedSlice() catch unreachable;
}

fn getFaultyDataFromLine(allocator: std.mem.Allocator, line: []const u8) FaultyData {
    var iterator = std.mem.tokenizeAny(u8, line, "|");
    const signal_pattern_str = iterator.next() orelse unreachable;
    const digits_str = iterator.next() orelse unreachable;

    return FaultyData{ .signalPatterns = parseString(allocator, signal_pattern_str), .digits = parseString(allocator, digits_str) };
}

fn getFaultyDatasFromLines(allocator: std.mem.Allocator, lines: [][]const u8) []FaultyData {
    var data = std.ArrayList(FaultyData).init(allocator);
    data.resize(lines.len) catch unreachable;

    for (lines, 0..) |*line, i| {
        data.items[i] = getFaultyDataFromLine(allocator, line.*);
    }

    return data.toOwnedSlice() catch unreachable;
}

fn countUniqueDigits(parsedData: []const FaultyData) u32 {
    var counter: u32 = 0;
    for (parsedData) |data| {
        for (data.digits) |digit| {
            switch (digit.len) {
                2 => {
                    counter += 1;
                },
                4 => {
                    counter += 1;
                },
                3 => {
                    counter += 1;
                },
                7 => {
                    counter += 1;
                },
                else => {},
            }
        }
    }
    return counter;
}

fn createSequenceMask(sequence: []const u8) u32 {
    var mask: u32 = 0;
    for (sequence) |char| {
        if (char < 'a' and 'z' > char) unreachable;

        const bit_position: u5 = @intCast((char - 'a') % 32);
        mask |= @as(u32, 1) << bit_position;
    }

    return mask;
}

const BitMasks = struct {
    zero: u32 = 0,
    one: u32 = 0,
    two: u32 = 0,
    three: u32 = 0,
    four: u32 = 0,
    five: u32 = 0,
    six: u32 = 0,
    seven: u32 = 0,
    eight: u32 = 0,
    nine: u32 = 0,

    fn print(self: *const BitMasks) void {
        std.debug.print("Zero:  {b:0>32}\n", .{self.zero});
        std.debug.print("One:   {b:0>32}\n", .{self.one});
        std.debug.print("Two:   {b:0>32}\n", .{self.two});
        std.debug.print("Three: {b:0>32}\n", .{self.three});
        std.debug.print("Four:  {b:0>32}\n", .{self.four});
        std.debug.print("Five:  {b:0>32}\n", .{self.five});
        std.debug.print("Six:   {b:0>32}\n", .{self.six});
        std.debug.print("Seven: {b:0>32}\n", .{self.seven});
        std.debug.print("Eight: {b:0>32}\n", .{self.eight});
        std.debug.print("Nine:  {b:0>32}\n", .{self.nine});
    }
};

fn getNumbersBitMasks(signalPatterns: [][]u8) BitMasks {
    std.debug.assert(signalPatterns.len == 10);

    // Need to sort them so that the we can have correct index to the unique lengths.
    std.sort.block([]const u8, signalPatterns, {}, struct {
        fn lessThan(_: void, a: []const u8, b: []const u8) bool {
            return a.len < b.len;
        }
    }.lessThan);

    // ___Top___
    // |       |
    // l1      r1
    // |       |
    // ---Mid---
    // |       |
    // l2      r2
    // |       |
    // ---Bot---

    std.debug.assert(signalPatterns[0].len == 2); // should be 1 that contains r1, r2
    std.debug.assert(signalPatterns[1].len == 3); // should be 7 that contains r1, r2, top
    std.debug.assert(signalPatterns[2].len == 4); // should be 4 that contains r1, r2, l2, mid
    std.debug.assert(signalPatterns[9].len == 7); // should be 8 that contains all

    std.debug.assert(signalPatterns[3].len == 5); // either 3, 5, 2
    std.debug.assert(signalPatterns[4].len == 5); // either 3, 5, 2
    std.debug.assert(signalPatterns[5].len == 5); // either 3, 5, 2

    std.debug.assert(signalPatterns[6].len == 6); // either 6, 9, 0
    std.debug.assert(signalPatterns[7].len == 6); // either 6, 9, 0
    std.debug.assert(signalPatterns[8].len == 6); // either 6, 9, 0

    // The thought here is that we will create bitmasks of the chars that a sequence contains.
    // Then match the different patterns to solve which is which.
    var sequenceMasks = BitMasks{};
    sequenceMasks.one = createSequenceMask(signalPatterns[0]);
    sequenceMasks.seven = createSequenceMask(signalPatterns[1]);
    sequenceMasks.four = createSequenceMask(signalPatterns[2]);
    sequenceMasks.eight = createSequenceMask(signalPatterns[9]);

    var i: u32 = 0;
    var lengthFiveRemainder = [_]u32{0} ** 2; // should contain 5 and 2
    for (signalPatterns[3..6]) |pattern| {
        const mask = createSequenceMask(pattern);
        if ((mask & sequenceMasks.one) == sequenceMasks.one) {
            sequenceMasks.three = mask;
        } else {
            lengthFiveRemainder[i] = mask;
            i += 1;
        }
    }

    i = 0;
    var lengthSixRemainder = [_]u32{0} ** 2; // should contain 6 and 0
    for (signalPatterns[6..9]) |pattern| {
        const mask = createSequenceMask(pattern);
        if ((mask & sequenceMasks.three) == sequenceMasks.three) {
            sequenceMasks.nine = mask;
        } else {
            lengthSixRemainder[i] = mask;
            i += 1;
        }
    }

    if ((sequenceMasks.seven & lengthSixRemainder[0]) == sequenceMasks.seven) {
        sequenceMasks.zero = lengthSixRemainder[0];
        sequenceMasks.six = lengthSixRemainder[1];
    } else {
        sequenceMasks.zero = lengthSixRemainder[1];
        sequenceMasks.six = lengthSixRemainder[0];
    }

    if ((lengthFiveRemainder[0] & sequenceMasks.nine) == lengthFiveRemainder[0]) {
        sequenceMasks.five = lengthFiveRemainder[0];
        sequenceMasks.two = lengthFiveRemainder[1];
    } else {
        sequenceMasks.five = lengthFiveRemainder[1];
        sequenceMasks.two = lengthFiveRemainder[0];
    }

    return sequenceMasks;
}

fn decodeNumberFromFaultyData(data: FaultyData) u64 {
    var numbers = [_]u8{0} ** 4;

    const numbersBitMasks = getNumbersBitMasks(data.signalPatterns);

    for (data.digits, 0..) |digit_str, i| {
        const mask = createSequenceMask(digit_str);

        if (mask == numbersBitMasks.zero) {
            numbers[i] = '0';
        } else if (mask == numbersBitMasks.one) {
            numbers[i] = '1';
        } else if (mask == numbersBitMasks.two) {
            numbers[i] = '2';
        } else if (mask == numbersBitMasks.three) {
            numbers[i] = '3';
        } else if (mask == numbersBitMasks.four) {
            numbers[i] = '4';
        } else if (mask == numbersBitMasks.five) {
            numbers[i] = '5';
        } else if (mask == numbersBitMasks.six) {
            numbers[i] = '6';
        } else if (mask == numbersBitMasks.seven) {
            numbers[i] = '7';
        } else if (mask == numbersBitMasks.eight) {
            numbers[i] = '8';
        } else if (mask == numbersBitMasks.nine) {
            numbers[i] = '9';
        } else {
            unreachable;
        }
    }

    return std.fmt.parseInt(u64, &numbers, 10) catch unreachable;
}

fn decodeSumOfNumbersFromFaultyDatas(parsedDatas: []const FaultyData) u64 {
    var sumOfDigits: u64 = 0;
    for (parsedDatas) |data| {
        sumOfDigits += decodeNumberFromFaultyData(data);
    }
    return sumOfDigits;
}

pub fn part1(allocator: std.mem.Allocator) void {
    const lines = util.getLinesFromFile("day8.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    const parsedData = getFaultyDatasFromLines(allocator, lines.items);
    defer {
        for (parsedData) |data| {
            for (data.signalPatterns) |signal| {
                allocator.free(signal);
            }
            allocator.free(data.signalPatterns);
            for (data.digits) |digit| {
                allocator.free(digit);
            }
            allocator.free(data.digits);
        }
        allocator.free(parsedData);
    }
    std.debug.print("Part1 result: {}\n", .{countUniqueDigits(parsedData)});
}

pub fn part2(allocator: std.mem.Allocator) void {
    const lines = util.getLinesFromFile("day8.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }
    const parsedData = getFaultyDatasFromLines(allocator, lines.items);
    defer {
        for (parsedData) |data| {
            for (data.signalPatterns) |signal| {
                allocator.free(signal);
            }
            allocator.free(data.signalPatterns);
            for (data.digits) |digit| {
                allocator.free(digit);
            }
            allocator.free(data.digits);
        }
        allocator.free(parsedData);
    }

    std.debug.print("Part2 result: {}\n", .{decodeSumOfNumbersFromFaultyDatas(parsedData)});
}
