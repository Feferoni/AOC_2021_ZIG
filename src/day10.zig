const std = @import("std");
const util = @import("util.zig");

const ChunkValue = struct {
    open: u8,
    close: u8,
    syntax_score: u32,
    missing_score: u32,
};
const chunks = blk: {
    const pairs = [_]ChunkValue{
        .{
            .open = '(',
            .close = ')',
            .syntax_score = 3,
            .missing_score = 1,
        },
        .{
            .open = '[',
            .close = ']',
            .syntax_score = 57,
            .missing_score = 2,
        },
        .{
            .open = '{',
            .close = '}',
            .syntax_score = 1197,
            .missing_score = 3,
        },
        .{
            .open = '<',
            .close = '>',
            .syntax_score = 25137,
            .missing_score = 4,
        },
    };
    break :blk pairs;
};

const Stack = struct {
    data: [1024]u8,
    len: usize,

    const Self = @This();

    fn init() Self {
        return Self{ .data = undefined, .len = 0 };
    }

    fn push(self: *Self, value: u8) void {
        if (self.len >= self.data.len) unreachable;
        self.data[self.len] = value;
        self.len += 1;
    }

    fn pop(self: *Self) ?u8 {
        if (self.len == 0) return null;
        self.len -= 1;
        return self.data[self.len];
    }

    fn isEmpty(self: *Self) bool {
        return self.len == 0;
    }

    fn getData(self: *Self) []u8 {
        if (self.len == 0) return &[_]u8{};

        return self.data[0..self.len];
    }
};

fn isOpenBracket(char: u8) bool {
    inline for (chunks) |chunk| {
        if (chunk.open == char) return true;
    }
    return false;
}

fn getClosingBracket(open: u8) u8 {
    inline for (chunks) |chunk| {
        if (chunk.open == open) return chunk.close;
    }
    unreachable;
}

fn getMissingScore(close: u8) u32 {
    inline for (chunks) |chunk| {
        if (chunk.close == close) return chunk.missing_score;
    }

    std.debug.print("Close char not found: {}\n", .{close});
    unreachable;
}

fn getIllegalSyntaxScore(close: u8) u32 {
    inline for (chunks) |chunk| {
        if (chunk.close == close) return chunk.syntax_score;
    }
    unreachable;
}

const ValidationError = union(enum) {
    missing_chars: Stack,
    invalid_char: u8,
    none: void,
};

fn validateBrackets(input: []const u8) ValidationError {
    var stack = Stack.init();
    for (input) |char| {
        if (isOpenBracket(char)) {
            stack.push(char);
        } else {
            const lastOpen = stack.pop() orelse unreachable;
            const expectedClose = getClosingBracket(lastOpen);
            if (char != expectedClose) return .{ .invalid_char = char };
        }
    }

    if (stack.isEmpty()) return .{ .none = {} };

    var reverse_stack = Stack.init();
    while (stack.pop()) |openBracket| {
        const closeBracket = getClosingBracket(openBracket);
        reverse_stack.push(closeBracket);
    }

    return .{ .missing_chars = reverse_stack };
}

fn calulateInvalidIndexScore(lines: [][]const u8) u32 {
    var char_map = comptime blk: {
        @setEvalBranchQuota(1000);
        var map: [256]u32 = undefined;
        for (&map) |*value| {
            value.* = 0;
        }

        break :blk map;
    };

    for (lines) |line| {
        const err = validateBrackets(line);
        switch (err) {
            .invalid_char => |char| char_map[char] += getIllegalSyntaxScore(char),
            else => {},
        }
    }

    return util.sumRange(u32, &char_map, 0, char_map.len);
}

fn getMissingScoreFromChars(chars: []const u8) u64 {
    var score: u64 = 0;
    for (chars) |char| {
        score *= 5;
        score += getMissingScore(char);
    }
    return score;
}

fn calculateIncompleteScore(allocator: std.mem.Allocator, lines: [][]const u8) u64 {
    var incompleteScores = std.ArrayList(u64).init(allocator);
    defer incompleteScores.deinit();

    for (lines) |line| {
        const err = validateBrackets(line);
        switch (err) {
            .invalid_char => {},
            .missing_chars => |chars| {
                incompleteScores.append(getMissingScoreFromChars(chars.data[0..chars.len])) catch unreachable;
            },
            .none => {},
        }
    }

    std.debug.assert(incompleteScores.items.len % 2 != 0);
    std.sort.block(u64, incompleteScores.items, {}, std.sort.asc(u64));

    return incompleteScores.items[incompleteScores.items.len / 2];
}

pub fn part1(allocator: std.mem.Allocator) void {
    const lines = util.getLinesFromFile("day10.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    std.debug.print("Part1 result: {}\n", .{calulateInvalidIndexScore(lines.items)});
}

pub fn part2(allocator: std.mem.Allocator) void {
    const lines = util.getLinesFromFile("day10.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    std.debug.print("Part2 result: {}\n", .{calculateIncompleteScore(allocator, lines.items)});
}

test "validateBrackets" {
    try std.testing.expectEqual(null, validateBrackets("(<{[]}>)"));
    try std.testing.expectEqual('}', validateBrackets("{([(<{}[<>[]}>{[]{[(<()>"));
    try std.testing.expectEqual(')', validateBrackets("[[<[([]))<([[{}[[()]]]"));
    try std.testing.expectEqual(']', validateBrackets("[{[{({}]{}}([{[{{{}}([]"));
    try std.testing.expectEqual(')', validateBrackets("[<(<(<(<{}))><([]([]()"));
    try std.testing.expectEqual('>', validateBrackets("<{([([[(<>()){}]>(<<{{"));
}
