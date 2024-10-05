const std = @import("std");

pub fn getNumbersFromLine(comptime T: type, allocator: std.mem.Allocator, line: []const u8, delimiters: []const u8) []T {
    var numbers = std.ArrayList(T).init(allocator);

    var iterator = std.mem.tokenizeAny(u8, line, delimiters);
    while (iterator.next()) |value_str| {
        const value = std.fmt.parseInt(T, value_str, 10) catch unreachable;
        numbers.append(value) catch unreachable;
    }

    return numbers.toOwnedSlice() catch unreachable;
}

pub fn sumRange(comptime T: type, slice: []const T, start: usize, end: usize) T {
    std.debug.assert(start <= slice.len);
    std.debug.assert(start <= end and end <= slice.len);

    var sum: T = 0;
    for (slice[start..end]) |num| {
        sum += num;
    }
    return sum;
}

pub fn multiplyRange(comptime T: type, slice: []const T, start: usize, end: usize) T {
    std.debug.assert(start <= slice.len);
    std.debug.assert(start <= end and end <= slice.len);

    if (start == end) return slice[start];
    var sum: T = slice[start];
    for (slice[start + 1 .. end]) |num| {
        sum *= num;
    }
    return sum;
}

pub fn getLinesFromFile(filename: []const u8, allocator: std.mem.Allocator) std.ArrayList([]u8) {
    const prefix_path = "./input/";
    var path_buffer: [std.fs.max_path_bytes]u8 = undefined;
    const full_path = std.fmt.bufPrint(&path_buffer, "{s}{s}", .{ prefix_path, filename }) catch |err| {
        std.debug.panic("Failed bufPrint with err: {}", .{err});
    };
    const file = std.fs.cwd().openFile(full_path, .{}) catch |err| {
        std.debug.panic("Failed to open file: {s} - err: {}", .{ full_path, err });
    };
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var lines: std.ArrayListAligned([]u8, null) = undefined;
    lines = std.ArrayList([]u8).init(allocator);
    errdefer {
        for (lines.items) |line| {
            std.heap.page_allocator.free(line);
        }
        lines.deinit();
    }

    var buf: [1024 * 1024]u8 = undefined;
    while (in_stream.readUntilDelimiterOrEof(&buf, '\n') catch unreachable) |line| {
        const dup = allocator.dupe(u8, line) catch unreachable;
        lines.append(dup) catch unreachable;
    }

    return lines;
}

test "getLinesFromFile" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    _ = getLinesFromFile("day2_test.txt", allocator);
}
