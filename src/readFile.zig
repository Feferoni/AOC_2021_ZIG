const std = @import("std");

pub fn getLinesFromFile(filename: []const u8) !std.ArrayList([]u8) {
    const prefix_path = "./input/";
    var path_buffer: [std.fs.max_path_bytes]u8 = undefined;
    const full_path = try std.fmt.bufPrint(&path_buffer, "{s}{s}", .{ prefix_path, filename });

    const file = try std.fs.cwd().openFile(full_path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var lines: std.ArrayListAligned([]u8, null) = undefined;
    lines = std.ArrayList([]u8).init(std.heap.page_allocator);
    errdefer {
        for (lines.items) |line| {
            std.heap.page_allocator.free(line);
        }
        lines.deinit();
    }

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const dup = try std.heap.page_allocator.dupe(u8, line);
        try lines.append(dup);
    }

    return lines;
}
