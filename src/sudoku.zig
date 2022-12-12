const std = @import("std");
const ansi = @import("ansi.zig");
const readLine = @import("io.zig").readLine;

const CellType = enum {
    // An empty cell contains no data. Meaning, it has no user- or puzzle-supplied data.
    empty,
    // A user cell contains user-supplied data. Can be overwritten.
    user,
    // A puzzle cell contains puzzle-supplied data that cannot be changed.
    puzzle,
};

const Cell = union(CellType) {
    empty: void,
    user: u4,
    puzzle: u4,
};

const SudokuError = error{
    UnsupportedBoardSize,
    InvalidValue,
    IndexOutOfBounds,
    CannotOverwritePuzzleValues,
};

const TableCellIterator = struct {
    index: u8,
    max: u8,
    len: u8,
    // n is the Sudoku size (for the typical 9x9, n=3)
    pub fn init(n: u8) @This() {
        return .{
            .index = 0,
            .max = n * n * n * n,
            .len = n * n,
        };
    }

    pub fn next(self: *@This()) ?struct { row: u8, col: u8 } {
        if (self.index >= self.max) return null;

        defer self.index += 1;

        return .{
            .col = self.index % self.len,
            .row = self.index / self.len,
        };
    }
};

pub const Sudoku = struct {
    allocator: std.mem.Allocator,
    n: u8,
    board: []Cell,
    prng: std.rand.Random,
    pub fn init(allocator: std.mem.Allocator, prng: std.rand.Random, n: u8) !Sudoku {
        if (n != 3) return SudokuError.UnsupportedBoardSize;

        const num_cells = n * n * n * n;

        var board = try allocator.alloc(Cell, num_cells);
        std.mem.set(Cell, board, .empty);

        return .{
            .allocator = allocator,
            .n = n,
            .board = board,
            .prng = prng,
        };
    }

    pub fn deinit(self: *Sudoku) void {
        self.allocator.free(self.board);
    }

    pub fn set(self: *Sudoku, row: usize, col: usize, val: u4) !void {
        if (val > self.n * self.n) return SudokuError.InvalidValue;

        const len = self.n * self.n;
        const i = row * len + col;

        switch (self.board[i]) {
            .puzzle => {
                return SudokuError.CannotOverwritePuzzleValues;
            },
            .empty, .user => {
                self.board[i] = .{ .user = val };
            },
        }
    }

    pub fn get(self: *Sudoku, row: usize, col: usize) !u4 {
        const len = self.n * self.n;
        if (row >= len or col >= len) return SudokuError.IndexOutOfBounds;
        const i = row * len + col;
        return switch (self.board[i]) {
            .empty => 0,
            .puzzle, .user => |val| val,
        };
    }

    pub fn reset(self: *Sudoku) void {
        std.mem.set(Cell, self.board, .empty);
    }

    pub fn newGame(self: *Sudoku) void {
        self.reset();
        // todo: generate a new sudoku
        const len = self.n * self.n;
        var cells_it = self.cells();
        while (cells_it.next()) |pos| {
            std.debug.print("{any}\n", .{pos});
            const i = pos.row * len + pos.col;
            self.board[i] = .{ .puzzle = self.prng.intRangeAtMost(u4, 1, 9) };
        }
    }

    fn cells(self: @This()) TableCellIterator {
        return TableCellIterator.init(self.n);
    }

    pub fn newGameFromFile(self: *Sudoku, file_path: []const u8) !void {
        var buf: [9 * 4]u8 = undefined;
        _ = self;

        var file = try std.fs.cwd().openFile(file_path, .{ .mode = .read_only });
        defer file.close();
        const reader = file.reader();
        std.debug.print("line!!()\n", .{});
        while (readLine(reader, &buf)) |line| {
            std.debug.print("line({s})\n", .{line});
        }
        // read file, line by line
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

    }

    pub fn format(
        self: Sudoku,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        const len = self.n * self.n;

        var row: usize = 0;
        {
            // print table header
            var col: usize = 0;
            try writer.print(" c", .{});
            while (col < len) : (col += 1) {
                // print subsquare divider
                if (col % self.n == 0) try writer.print(" ", .{});

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
                if (col % self.n == 0) try writer.print(" ", .{});

                try switch (self.board[i]) {
                    .empty => writer.print(".", .{}),
                    .puzzle => |val| writer.print("{s}{d}{s}", .{ ansi.bold, val, ansi.normal }),
                    .user => |val| writer.print("{d}", .{val}),
                };

                // print cell divider
                if (col < len - 1) try writer.print(" ", .{});
            }
            try writer.print("\n", .{});
            // print subsquare divider
            if ((row + 1) % self.n == 0) try writer.print("\n", .{});
        }
    }

    fn printCell(self: Sudoku, writer: anytype, row: usize, col: usize) !void {
        const len = self.n * self.n;
        const i = row * len + col;
        switch (self.board[i]) {
            .empty => {
                try writer.print(".", .{});
            },
            .puzzle => |val| {
                try writer.print("{s}{d}{s}", .{ ansi.bold, val, ansi.normal });
            },
            .user => |val| {
                try writer.print("{d}", .{val});
            },
        }
        if (col != len - 1) {
            try writer.print("  ", .{});
        }
    }

    fn printHeader(self: Sudoku, writer: anytype) !void {
        const num_cols = self.n * self.n;

        try writer.print("    ", .{});
        {
            var col: usize = 0;
            while (col < num_cols) : (col += 1) {
                if (col == num_cols - 1) {
                    try writer.print(" {d}", .{col});
                } else try writer.print(" {d}  ", .{col});
            }
            try writer.print("\n", .{});
        }

        try writer.print("    ", .{});
        {
            var col: usize = 0;
            while (col < num_cols) : (col += 1) {
                try writer.print(" *  ", .{});
            }
            try writer.print("\n", .{});
        }
    }

    fn printRowColumn(_: Sudoku, writer: anytype, row: ?usize) !void {
        if (row) |x| {
            try writer.print(" {d} >", .{x});
        } else try writer.print("   >", .{});
    }

    fn printRowDivider(_: Sudoku, writer: anytype) !void {
        try writer.print("\n", .{});
    }

    test "init" {
        const size = 3;
        const num_cells = 81;
        var sudoku = try Sudoku.init(std.testing.allocator, size);
        defer sudoku.deinit();

        try std.testing.expect(sudoku.n == size);
        try std.testing.expect(sudoku.board.len == num_cells);
        try std.testing.expect(std.mem.count(u4, sudoku.board, &[_]u4{0}) == num_cells);
    }

    test "print" {
        std.debug.print("\n", .{});

        const size = 3;
        var sudoku = try Sudoku.init(std.testing.allocator, size);
        defer sudoku.deinit();

        var row: usize = 0;

        // Generate a simple, completed Sudoku puzzle.
        const len = size * size;
        while (row < len) : (row += 1) {
            var col: usize = 0;
            while (col < len) : (col += 1) {
                const value = @truncate(u4, @mod(col + row * 4, 9) + 1);
                try sudoku.set(row, col, value);
            }
        }

        try sudoku.print(std.io.getStdOut().writer());
    }

    test "set" {
        const size = 3;

        var sudoku = try Sudoku.init(std.testing.allocator, size);
        defer sudoku.deinit();

        try sudoku.set(0, 2, 9);
        try std.testing.expect(std.mem.count(u4, sudoku.board, &[_]u4{9}) == 1);
    }

    test "get" {
        const size = 3;

        var sudoku = try Sudoku.init(std.testing.allocator, size);
        defer sudoku.deinit();

        try sudoku.set(0, 2, 9);
        const val = try sudoku.get(0, 2);
        try std.testing.expect(val == 9);
    }
};

test {
    _ = Sudoku;
}
