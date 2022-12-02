const std = @import("std");

const SudokuError = error{
    UnsupportedBoardSize,
    InvalidValue,
    IndexOutOfBounds,
};

pub const Sudoku = struct {
    allocator: std.mem.Allocator,
    n: u8,
    board: []u4,
    pub fn init(allocator: std.mem.Allocator, n: u8) !Sudoku {
        if (n != 3) return SudokuError.UnsupportedBoardSize;

        const num_cells = n * n * n * n;

        var board = try allocator.alloc(u4, num_cells);
        std.mem.set(u4, board, 0);

        return .{
            .allocator = allocator,
            .n = n,
            .board = board,
        };
    }

    pub fn deinit(self: *Sudoku) void {
        self.allocator.free(self.board);
    }

    pub fn set(self: *Sudoku, row: usize, col: usize, val: u4) !void {
        if (val > self.n * self.n) return SudokuError.InvalidValue;
        const len = self.n * self.n;
        const i = row * len + col;
        self.board[i] = val;
    }

    pub fn get(self: *Sudoku, row: usize, col: usize) !u4 {
        const len = self.n * self.n;
        if (row >= len or col >= len) return SudokuError.IndexOutOfBounds;
        const i = row * len + col;
        return self.board[i];
    }

    pub fn print(self: Sudoku) !void {
        const stdout = std.io.getStdOut().writer();

        const len = self.n * self.n;

        var row: usize = 0;
        while (row < len) : (row += 1) {
            if (row == 0) try self.printHeader();
            try self.printRowColumn(row);

            var col: usize = 0;
            while (col < len) : (col += 1) {
                try self.printCell(row, col);
            }
            try stdout.print("\n", .{});

            if (row != len - 1) try self.printRowDivider();
        }
    }

    fn printCell(self: Sudoku, row: usize, col: usize) !void {
        const stdout = std.io.getStdOut().writer();
        const len = self.n * self.n;
        const i = row * len + col;
        switch (self.board[i]) {
            0 => {
                try stdout.print(" .", .{});
            },
            else => |val| {
                try stdout.print(" {d}", .{val});
            },
        }
        if (col != len - 1) {
            try stdout.print(" :", .{});
        }
    }

    fn printHeader(self: Sudoku) !void {
        const stdout = std.io.getStdOut().writer();
        const num_cols = self.n * self.n;

        try stdout.print("    ", .{});
        {
            var col: usize = 0;
            while (col < num_cols) : (col += 1) {
                if (col == num_cols - 1) {
                    try stdout.print(" {d}", .{col});
                } else try stdout.print(" {d}  ", .{col});
            }
            try stdout.print("\n", .{});
        }

        try stdout.print("    ", .{});
        {
            var col: usize = 0;
            while (col < num_cols) : (col += 1) {
                try stdout.print(" *  ", .{});
            }
            try stdout.print("\n", .{});
        }
    }

    fn printRowColumn(_: Sudoku, row: ?usize) !void {
        const stdout = std.io.getStdOut().writer();
        if (row) |x| {
            try stdout.print(" {d} *", .{x});
        } else try stdout.print("   *", .{});
    }

    fn printRowDivider(_: Sudoku) !void {
        const stdout = std.io.getStdOut().writer();
        try stdout.print("\n", .{});
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

        try sudoku.print();
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
