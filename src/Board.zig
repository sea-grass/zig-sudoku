const Board = @This();

cells: [81]Cell,
allocator: std.mem.Allocator,

const std = @import("std");
const ansi = @import("ansi.zig");
const readLine = @import("io.zig").readLine;

const N = 3;
const M = N * N;

const CellDataType = enum { empty, puzzle, user };
const CellData = union(CellDataType) {
    empty: void,
    puzzle: CellNumber,
    user: CellNumber,
};
const CellNumber = u64;

const Cell = struct {
    row: usize,
    col: usize,
    square: usize,
    row_index: usize,
    col_index: usize,
    square_index: usize,
    data: CellData,

    pub fn get_valid_moves(self: Cell, board: Board) ![]CellNumber {
        var seen: [M]bool = .{false} ** 9;
        {
            var row = try board.get_row(self.row);
            defer board.allocator.free(row);
            for (row) |cell| switch (cell.data) {
                .empty => continue,
                .user => |x| seen[x - 1] = true,
                .puzzle => |x| seen[x - 1] = true,
            };
        }

        var list = std.ArrayList(CellNumber).init(board.allocator);
        defer list.deinit();

        for (seen) |invalid_move, i| if (!invalid_move) {
            try list.append(@as(CellNumber, i + 1));
        };

        return list.toOwnedSlice();
    }
};

pub fn init(allocator: std.mem.Allocator) Board {
    return .{
        .allocator = allocator,
        .cells = blk: {
            var cells: [81]Cell = undefined;
            inline for (cells) |*cell, i| {
                const row = i / M;
                const col = @mod(i, M);
                // TODO: Refactor to use N
                const square = switch (row) {
                    0...2 => switch (col) {
                        0...2 => 0,
                        3...5 => 1,
                        6...8 => 2,
                        else => unreachable,
                    },
                    3...5 => switch (col) {
                        0...2 => 3,
                        3...5 => 4,
                        6...8 => 5,
                        else => unreachable,
                    },
                    6...8 => switch (col) {
                        0...2 => 6,
                        3...5 => 7,
                        6...8 => 8,
                        else => unreachable,
                    },
                    else => unreachable,
                };
                const row_index = i - (row * M);
                const col_index = i / M;
                const square_index = switch (i) {
                    0, 3, 6, 27, 30, 33, 54, 57, 60 => 0,
                    1, 4, 7, 28, 31, 34, 55, 58, 61 => 1,
                    2, 5, 8, 29, 32, 35, 56, 59, 62 => 2,
                    9, 12, 15, 36, 39, 42, 63, 66, 69 => 3,
                    10, 13, 16, 37, 40, 43, 64, 67, 70 => 4,
                    11, 14, 17, 38, 41, 44, 65, 68, 71 => 5,
                    18, 21, 24, 45, 48, 51, 72, 75, 78 => 6,
                    19, 22, 25, 46, 49, 52, 73, 76, 79 => 7,
                    20, 23, 26, 47, 50, 53, 74, 77, 80 => 8,
                    else => unreachable,
                };
                cell.* = .{
                    .row = row,
                    .col = col,
                    .square = square,
                    .row_index = row_index,
                    .col_index = col_index,
                    .square_index = square_index,
                    .data = .empty,
                };
            }
            break :blk cells;
        },
    };
}

pub fn get_row(self: Board, row_index: usize) ![]const Cell {
    const offset = row_index * M;
    const row = self.cells[offset .. offset + 9];

    var list = std.ArrayList(Cell).init(self.allocator);
    defer list.deinit();
    try list.appendSlice(row);
    return list.toOwnedSlice();
}

pub fn get_col(self: Board, col_index: usize) ![]const Cell {
    var list = std.ArrayList(Cell).init(self.allocator);
    defer list.deinit();

    var row_index: usize = 0;
    while (row_index < M) : (row_index += 1) {
        var board_index = row_index * M + col_index;
        const cell = self.cells[board_index];
        if (cell.row != row_index) {
            std.debug.print("error: cell.row_index({d}) != {d}\n", .{ cell.row_index, row_index });
            unreachable;
        }
        try list.append(cell);
    }
    return list.toOwnedSlice();
}

pub fn get_square(self: Board, square_index: usize) ![]const Cell {
    var list = std.ArrayList(Cell).init(self.allocator);
    defer list.deinit();

    const row_start: usize = switch (square_index) {
        0...2 => 0,
        3...5 => 3,
        6...8 => 6,
        else => unreachable,
    };

    const col_start: usize = switch (square_index) {
        0, 3, 6 => 0,
        1, 4, 7 => 3,
        2, 5, 8 => 6,
        else => unreachable,
    };

    var row: usize = row_start;

    while (row < (row_start + 3)) : (row += 1) {
        var col: usize = col_start;
        while (col < (col_start + 3)) : (col += 1) {
            var board_index = row * M + col;
            const cell = self.cells[board_index];
            if (cell.square != square_index) unreachable;
            try list.append(cell);
        }
    }

    return list.toOwnedSlice();
}

// read file, line by line, and populate the sudoku cells
// a well-specified sudoku should look like this
// 1 2 3  4 5 6  7 8 9
// 4 5 6  7 8 9  1 2 3
// 7 8 9  1 2 3  4 5 6
//
// 2 3 4  5 6 7  8 9 1
// 5 6 7  8 9 1  2 3 4
// 8 9 1  2 3 4  5 6 7
//
// 3 4 5  6 7 8  9 1 2
// 6 7 8  9 1 2  3 4 5
// 9 1 2  3 4 5  6 7 8
//
// The above Sudoku is considered complete, since all the spaces are filled.
// If any of the spaces are empty, they must be represented by the empty character (.).
// A row with some empty spots might look like this:
// 1 . 3  . . .  . 8 9
//
// Useful terminology for parsing:
// The `puzzle` is divided into `n` `lines`, each containing `n` chunks,
// where every `n`th line is followed by a blank line.
pub fn newGameFromFile(self: *Board, file_path: []const u8) !void {
    var buf: [9 * 4]u8 = undefined;

    var file = try std.fs.cwd().openFile(file_path, .{ .mode = .read_only });
    defer file.close();

    const reader = file.reader();
    const len = M;

    // We expect one character per number and one character for every
    // space between each number.
    const expected_chunk_len = N + N - 1;

    var block: usize = 0;
    while (block < N) : (block += 1) {
        var row: usize = block * N;
        var max_row = row + N;

        while (row < max_row) : (row += 1) {
            if (readLine(reader, &buf)) |line| {
                // read and set all cols in this row
                var row_it = std.mem.split(u8, line, "  ");

                var col: usize = 0;
                while (row_it.next()) |chunk| {
                    if (chunk.len != expected_chunk_len) return error.MalformedSudokuFile;

                    var square_it = std.mem.split(u8, chunk, " ");
                    while (square_it.next()) |cell| {
                        const i = row * len + col;
                        self.cells[i].data = if (std.mem.eql(u8, cell, ".")) .empty else .{ .puzzle = std.fmt.parseInt(CellNumber, cell, 10) catch {
                            return error.MalformedSudokuFile;
                        } };

                        col += 1;
                    }
                }
            } else unreachable;
        }

        if (block < N - 1) {
            if (readLine(reader, &buf)) |line| {
                _ = line;
                // ensure this is a blank line
            } else unreachable;
        }
    }

    // expect the rest of the file to be empty
    if (readLine(reader, &buf)) |_| unreachable;
}

pub fn format(
    self: Board,
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    _ = fmt;
    _ = options;
    const len = M;

    var row: usize = 0;
    {
        // print table header
        var col: usize = 0;
        try writer.print(" c", .{});
        while (col < len) : (col += 1) {
            // print subsquare divider
            if (col % N == 0) try writer.print(" ", .{});

            try writer.print("{d} ", .{col});
        }
        try writer.print("\n", .{});
    }

    try writer.print("r\n", .{});

    while (row < len) : (row += 1) {
        {
            // print column header
            try writer.print("{d} ", .{row});
        }
        var col: usize = 0;
        while (col < len) : (col += 1) {
            const i = row * len + col;
            // print subsquare divider
            if (col % N == 0) try writer.print(" ", .{});

            try switch (self.cells[i].data) {
                .empty => writer.print(".", .{}),
                .puzzle => |val| writer.print("{s}{d}{s}", .{ ansi.bold, val, ansi.normal }),
                .user => |val| writer.print("{d}", .{val}),
            };

            // print cell divider
            if (col < len - 1) try writer.print(" ", .{});
        }
        try writer.print("\n", .{});
        // print subsquare divider
        if ((row + 1) % N == 0) try writer.print("\n", .{});
    }
}

test "iterate over board cells" {
    std.debug.print("\n", .{});
    var board = Board.init(std.testing.allocator);

    for (board.cells) |cell, i| {
        const row = i / M;
        const col = @mod(i, M);
        try std.testing.expect(cell.row == row);
        try std.testing.expect(cell.col == col);
    }
}

test "iterate over cells by row" {
    std.debug.print("\n", .{});
    var board = Board.init(std.testing.allocator);

    var row_index: usize = 0;
    while (row_index < M) : (row_index += 1) {
        var row = try board.get_row(row_index);
        defer std.testing.allocator.free(row);
        for (row) |cell, i| {
            try std.testing.expect(cell.row == row_index);
            try std.testing.expect(cell.row_index == i);
        }
    }
}

test "iterate over cells by col" {
    std.debug.print("\n", .{});
    var board = Board.init(std.testing.allocator);

    var col_index: usize = 0;
    while (col_index < M) : (col_index += 1) {
        var col = try board.get_col(col_index);
        defer std.testing.allocator.free(col);
        for (col) |cell, i| {
            try std.testing.expect(cell.col == col_index);
            try std.testing.expect(cell.col_index == i);
        }
    }
}

test "iterate over cells by square" {
    std.debug.print("\n", .{});
    var board = Board.init(std.testing.allocator);

    var square_index: usize = 0;
    while (square_index < M) : (square_index += 1) {
        var square = try board.get_square(square_index);
        defer std.testing.allocator.free(square);
        for (square) |cell, i| {
            try std.testing.expect(cell.square == square_index);
            try std.testing.expect(cell.square_index == i);
        }
    }
}

test "read board from file" {
    std.debug.print("\n", .{});
    var board = Board.init(std.testing.allocator);
    try board.newGameFromFile("sudokus/1.txt");

    std.debug.print("{s}\n", .{board});
}

test "get valid moves" {
    std.debug.print("\n", .{});
    var board = Board.init(std.testing.allocator);
    try board.newGameFromFile("sudokus/1.txt");

    var first_row = try board.get_row(0);
    defer board.allocator.free(first_row);
    var valid_moves = try first_row[0].get_valid_moves(board);
    defer board.allocator.free(valid_moves);

    std.debug.print("valid moves for the first cell in the first row: {any}\n", .{valid_moves});
}
