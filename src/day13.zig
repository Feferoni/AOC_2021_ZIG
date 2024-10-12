const std = @import("std");
const util = @import("util.zig");

const FoldType = enum { X, Y };
const FoldInstruction = struct { fold_type: FoldType, position: u32 };
const Position = struct { x: u32, y: u32 };

fn getFoldTypeFromStr(str: []const u8) FoldType {
    if (std.mem.eql(u8, "x", str)) return FoldType.X;
    if (std.mem.eql(u8, "y", str)) return FoldType.Y;
    unreachable;
}

fn parseLines(allocator: std.mem.Allocator, lines: [][]const u8) struct { side_max: Position, positions: []Position, fold_instructions: []const FoldInstruction } {
    var fold_instructions = std.ArrayList(FoldInstruction).init(allocator);
    var positions = std.ArrayList(Position).init(allocator);
    var max_x: u32 = 0;
    var max_y: u32 = 0;

    var parsing_positions: bool = true;
    for (lines) |line| {
        if (line.len == 0) {
            parsing_positions = false;
            continue;
        }

        if (parsing_positions) {
            var it = std.mem.splitAny(u8, line, ",");
            const x_str = it.next() orelse unreachable;
            const y_str = it.next() orelse unreachable;

            const x = std.fmt.parseInt(u32, x_str, 10) catch unreachable;
            const y = std.fmt.parseInt(u32, y_str, 10) catch unreachable;

            if (x > max_x) max_x = x;
            if (y > max_y) max_y = y;

            positions.append(Position{ .x = x, .y = y }) catch unreachable;
        } else {
            var it = std.mem.splitAny(u8, line, " ");
            _ = it.next() orelse unreachable;
            _ = it.next() orelse unreachable;
            const parse_str = it.next() orelse unreachable;
            var it2 = std.mem.splitAny(u8, parse_str, "=");

            const fold_type = getFoldTypeFromStr(it2.next() orelse unreachable);
            const position_value_str = it2.next() orelse unreachable;
            const position_value = std.fmt.parseInt(u32, position_value_str, 10) catch unreachable;
            fold_instructions.append(FoldInstruction{ .fold_type = fold_type, .position = position_value }) catch unreachable;
        }
    }

    return .{
        .side_max = Position{ .x = max_x + 1, .y = max_y + 1 },
        .positions = positions.toOwnedSlice() catch unreachable,
        .fold_instructions = fold_instructions.toOwnedSlice() catch unreachable,
    };
}

const TransparetPaper = struct {
    paper_map: [][]u8,
    current_size: Position,
    fold_instructions: []const FoldInstruction,
    allocator: std.mem.Allocator,

    const Self = @This();

    fn init(allocator: std.mem.Allocator, lines: [][]const u8) TransparetPaper {
        const paper_data = parseLines(allocator, lines);
        defer allocator.free(paper_data.positions);

        var paper_rows = allocator.alloc([]u8, paper_data.side_max.y) catch unreachable;
        for (paper_rows) |*row| {
            row.* = allocator.alloc(u8, paper_data.side_max.x) catch unreachable;
            @memset(row.*, '.');
        }

        for (paper_data.positions) |position| {
            paper_rows[position.y][position.x] = '#';
        }

        return TransparetPaper{
            .paper_map = paper_rows,
            .current_size = paper_data.side_max,
            .fold_instructions = paper_data.fold_instructions,
            .allocator = allocator,
        };
    }

    fn deinit(self: *const Self) void {
        for (self.paper_map) |rows| {
            self.allocator.free(rows);
        }
        self.allocator.free(self.paper_map);
        self.allocator.free(self.fold_instructions);
    }

    fn print(self: *const Self) void {
        std.debug.print("Fold instructions:\n", .{});
        for (self.fold_instructions) |fold_instruction| {
            std.debug.print("{} {}\n", .{ fold_instruction.fold_type, fold_instruction.position });
        }
        std.debug.print("Current size x: {} - y: {}\n", .{ self.current_size.x, self.current_size.y });
        std.debug.print("Paper map:\n", .{});
        for (0..self.current_size.y) |y| {
            for (0..self.current_size.x) |x| {
                std.debug.print("{c}", .{self.paper_map[y][x]});
            }
            std.debug.print("\n", .{});
        }
    }

    fn foldY(self: *Self, fold_row: u32) void {
        if (self.paper_map.len - 1 < fold_row) unreachable;

        for (fold_row..self.current_size.y) |row| {
            for (0..self.current_size.x) |col| {
                if (row == fold_row) {
                    self.paper_map[row][col] = 'x';
                    continue;
                }

                if (self.paper_map[row][col] == '#') {
                    const delta_fold = row - fold_row;
                    const new_row = fold_row - delta_fold;
                    self.paper_map[new_row][col] = '#';
                }
                self.paper_map[row][col] = 'x';
            }
        }

        self.current_size.y = fold_row;
    }

    fn foldX(self: *Self, fold_col: u32) void {
        if (self.paper_map.len == 0) unreachable;
        if (self.paper_map[0].len - 1 < fold_col) unreachable;

        for (0..self.current_size.y) |row| {
            for (fold_col..self.current_size.x) |col| {
                if (col == fold_col) {
                    self.paper_map[row][col] = 'x';
                }

                if (self.paper_map[row][col] == '#') {
                    const delta_fold = col - fold_col;
                    const new_col = fold_col - delta_fold;
                    self.paper_map[row][new_col] = '#';
                }
                self.paper_map[row][col] = 'x';
            }
        }

        self.current_size.x = fold_col;
    }

    fn fold(self: *Self, nr_of_folds: u32) u32 {
        var dots_visible: u32 = 0;

        for (self.fold_instructions, 0..) |fold_instruction, n| {
            if (n == nr_of_folds) break;

            switch (fold_instruction.fold_type) {
                FoldType.X => {
                    self.foldX(fold_instruction.position);
                },
                FoldType.Y => {
                    self.foldY(fold_instruction.position);
                },
            }

            // self.print();
        }

        for (self.paper_map) |cols| {
            for (cols) |row| {
                if (row == '#') dots_visible += 1;
            }
        }

        return dots_visible;
    }
};

pub fn part1(allocator: std.mem.Allocator) void {
    const lines = util.getLinesFromFile("day13.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    var paper = TransparetPaper.init(allocator, lines.items);
    defer paper.deinit();

    std.debug.print("Part1 result: {}\n", .{paper.fold(1)});
}

pub fn part2(allocator: std.mem.Allocator) void {
    const lines = util.getLinesFromFile("day13.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    var paper = TransparetPaper.init(allocator, lines.items);
    defer paper.deinit();

    std.debug.print("Part2 result: {}\n", .{paper.fold(1000)});
    paper.print();
}
