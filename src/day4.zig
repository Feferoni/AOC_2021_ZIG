const std = @import("std");
const readFile = @import("readFile.zig");

const Entry = struct {
    marked: bool = false,
    value: u32 = undefined,
};

const Board = struct {
    gottenBingo: bool = false,
    board: [5][5]Entry,

    fn markNumber(self: *Board, drawnNr: u32) bool {
        for (0..5) |i| {
            for (0..5) |j| {
                if (self.board[i][j].value == drawnNr) {
                    self.board[i][j].marked = true;
                    return true;
                }
            }
        }
        return false;
    }

    fn gotBingo(self: *Board) bool {
        if (self.gottenBingo) {
            return true;
        }

        for (0..5) |i| {
            var count: u32 = 0;

            for (0..5) |j| {
                if (self.board[i][j].marked) {
                    count += 1;
                } else {
                    break;
                }
            }

            if (count == 5) {
                self.gottenBingo = true;
                return true;
            }
        }

        for (0..5) |i| {
            var count: u32 = 0;

            for (0..5) |j| {
                if (self.board[j][i].marked) {
                    count += 1;
                } else {
                    break;
                }
            }

            if (count == 5) {
                self.gottenBingo = true;
                return true;
            }
        }

        return false;
    }

    fn getSumOfUnmarked(self: *const Board) u32 {
        var sum: u32 = 0;
        for (0..5) |i| {
            for (0..5) |j| {
                if (!self.board[i][j].marked) {
                    sum += self.board[i][j].value;
                }
            }
        }
        return sum;
    }

    fn print(self: *const Board) void {
        for (0..5) |i| {
            for (0..5) |j| {
                std.debug.print("{},", .{self.board[i][j]});
            }
            std.debug.print("\n", .{});
        }
    }
};

const GameData = struct {
    drawNumbers: []u32,
    boards: []Board,

    fn allGottenBingo(self: *const GameData) bool {
        for (self.boards) |board| {
            if (!board.gottenBingo) return false;
        }
        return true;
    }
};

fn getDrawNumbers(line: []const u8) []u32 {
    var drawNumbers = std.ArrayList(u32).init(std.heap.page_allocator);
    errdefer drawNumbers.deinit();

    var iterator = std.mem.splitAny(u8, line, ",");
    while (iterator.next()) |value_str| {
        const number = std.fmt.parseInt(u32, value_str, 10) catch |err| {
            std.debug.panic("Failed to parse int {s} - err: {}", .{ value_str, err });
        };
        drawNumbers.append(number) catch unreachable;
    }

    return drawNumbers.toOwnedSlice() catch unreachable;
}

fn getRowNumbers(line: []const u8) [5]Entry {
    var rowNumbers: [5]Entry = undefined;
    var iterator = std.mem.tokenizeAny(u8, line, " ");

    for (0..5) |i| {
        const value_str = iterator.next() orelse unreachable;
        const number = std.fmt.parseInt(u32, value_str, 10) catch |err| {
            std.debug.panic("Failed to parse int {s} - err: {}", .{ value_str, err });
        };
        rowNumbers[i] = Entry{ .marked = false, .value = number };
    }

    return rowNumbers;
}

fn getBoards(lines: [][]const u8) []Board {
    var boards = std.ArrayList(Board).init(std.heap.page_allocator);
    errdefer boards.deinit();

    var i: u32 = 0;
    while (i < lines.len + 1) : (i += 6) {
        var currentBoard = Board{
            .board = [_][5]Entry{[_]Entry{.{}} ** 5} ** 5,
        };

        for (0..5) |j| {
            currentBoard.board[j] = getRowNumbers(lines[i + j]);
        }

        boards.append(currentBoard) catch unreachable;
    }

    return boards.toOwnedSlice() catch unreachable;
}

fn getGameData(lines: std.ArrayList([]u8)) GameData {
    std.debug.assert((lines.items.len - 1) % 6 == 0);
    const drawNumbers = getDrawNumbers(lines.items[0]);
    const boards = getBoards(lines.items[2..]);
    return GameData{ .drawNumbers = drawNumbers, .boards = boards };
}

fn playGamePart1(game: *GameData) u32 {
    for (game.drawNumbers) |number| {
        for (game.boards) |*board| {
            if (!board.markNumber(number)) {
                continue;
            }

            if (board.gotBingo()) {
                return board.getSumOfUnmarked() * number;
            }
        }
    }

    unreachable;
}

fn playGamePart2(game: *GameData) u32 {
    for (game.drawNumbers) |number| {
        for (game.boards) |*board| {
            if (!board.markNumber(number)) {
                continue;
            }

            _ = board.gotBingo();

            if (game.allGottenBingo()) {
                return board.getSumOfUnmarked() * number;
            }
        }
    }

    unreachable;
}

pub fn part1(allocator: std.mem.Allocator) void {
    const lines = readFile.getLinesFromFile("day4.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    var game = getGameData(lines);

    std.debug.print("Part1 result: {}\n", .{playGamePart1(&game)});
}

pub fn part2(allocator: std.mem.Allocator) void {
    var lines = readFile.getLinesFromFile("day4.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    var game = getGameData(lines);
    std.debug.print("Part2 result: {}\n", .{playGamePart2(&game)});
}

test "getDrawNumbers" {
    const numbers = getDrawNumbers("1,2,3,4,5");
    try std.testing.expectEqual(5, numbers.len);
    try std.testing.expectEqual(1, numbers[0]);
    try std.testing.expectEqual(2, numbers[1]);
    try std.testing.expectEqual(3, numbers[2]);
    try std.testing.expectEqual(4, numbers[3]);
    try std.testing.expectEqual(5, numbers[4]);
}

test "getRowNumbers" {
    const numbers = getRowNumbers("1  2  3  4 5");
    try std.testing.expectEqual(5, numbers.len);
    try std.testing.expectEqual(1, numbers[0].value);
    try std.testing.expectEqual(2, numbers[1].value);
    try std.testing.expectEqual(3, numbers[2].value);
    try std.testing.expectEqual(4, numbers[3].value);
    try std.testing.expectEqual(5, numbers[4].value);
}

test "getGameData" {
    const allocator = std.testing.allocator;
    const lines = readFile.getLinesFromFile("day4_test.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }
    _ = getGameData(lines);
}
