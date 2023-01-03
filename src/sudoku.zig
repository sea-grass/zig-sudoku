pub const Board = @import("board.zig").Board;
pub const DecisionTree = @import("DecisionTree.zig");

const std = @import("std");
const ansi = @import("ansi.zig");
const readLine = @import("io.zig").readLine;

const N = 3;

const SudokuError = error{
    UnsupportedBoardSize,
    InvalidValue,
    IndexOutOfBounds,
    CannotOverwritePuzzleValues,
};

pub const Sudoku = struct {
    allocator: std.mem.Allocator,
    board: Board(N),
    prng: std.rand.Random,
    pub fn init(allocator: std.mem.Allocator, prng: std.rand.Random) !Sudoku {
        return .{
            .allocator = allocator,
            .board = Board(N).init(allocator),
            .prng = prng,
        };
    }

    pub fn deinit(self: *Sudoku) void {
        _ = self;
    }

    pub fn set(self: *Sudoku, row: usize, col: usize, val: u4) !void {
        if (val > N * N) return SudokuError.InvalidValue;

        const len = N * N;
        const i = row * len + col;

        switch (self.board.cells[i].data) {
            .puzzle => {
                return SudokuError.CannotOverwritePuzzleValues;
            },
            .empty, .user => {
                self.board.cells[i].data = .{ .user = val };
            },
        }
    }

    pub fn get(self: *Sudoku, row: usize, col: usize) !u64 {
        const len = N * N;
        if (row >= len or col >= len) return SudokuError.IndexOutOfBounds;
        const i = row * len + col;
        return switch (self.board.cells[i].data) {
            .empty => 0,
            .puzzle, .user => |val| val,
        };
    }

    pub fn reset(self: *Sudoku) void {
        inline for (self.board.cells) |*cell| {
            cell.data = .empty;
        }
    }

    pub fn newGame(self: *Sudoku) !void {
        self.reset();
        var dt = DecisionTree.init(self.allocator);
        defer dt.deinit();
        // todo: generate a new sudoku
        for (self.board.cells) |*cell| {
            const valid_moves = try cell.get_valid_moves(self.board);
            defer self.board.allocator.free(valid_moves);
            std.debug.print("rc({d},{d}) can be {any}\n", .{ cell.row, cell.col, valid_moves });
            switch (valid_moves.len) {
                0 => {
                    // todo: backtrack
                    std.debug.print("Cannot fill this cell.\n", .{});
                },
                1 => {
                    cell.data = .{ .puzzle = valid_moves[0] };
                },
                else => {
                    // pick a random one and add an entry to the decision tree
                    const move_index = self.prng.intRangeAtMost(usize, 0, valid_moves.len - 1);
                    cell.data = .{ .puzzle = valid_moves[move_index] };
                    // todo: add entry to decision tree
                },
            }
            std.debug.print("rc({d},{d}) is now {d}\n", .{ cell.row, cell.col, switch (cell.data) {
                .puzzle, .user => |val| val,
                else => 99,
            } });
        }
    }

    pub fn newGameFromFile(self: *Sudoku, input_file: []const u8) !void {
        try self.board.newGameFromFile(input_file);
    }

    pub fn format(
        self: Sudoku,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("{s}", .{self.board});
    }

    test "init" {
        const num_cells = 81;
        var sudoku = try Sudoku.init(std.testing.allocator, rand());
        defer sudoku.deinit();

        try std.testing.expect(sudoku.board.cells.len == num_cells);
        var count: u8 = 0;
        for (sudoku.board.cells) |c| switch (c.data) {
            .empty => count += 1,
            else => continue,
        };
        try std.testing.expect(count == num_cells);
    }

    test "print" {
        std.debug.print("\n", .{});

        var sudoku = try Sudoku.init(std.testing.allocator, rand());
        defer sudoku.deinit();

        var row: usize = 0;

        // Generate a simple, completed Sudoku puzzle.
        const len = N * N;
        while (row < len) : (row += 1) {
            var col: usize = 0;
            while (col < len) : (col += 1) {
                const value = @truncate(u4, @mod(col + row * 4, 9) + 1);
                try sudoku.set(row, col, value);
            }
        }

        std.debug.print("\n{s}\n", .{sudoku});
    }

    test "set" {
        var sudoku = try Sudoku.init(std.testing.allocator, rand());
        defer sudoku.deinit();

        try sudoku.set(0, 2, 9);
        var count: u8 = 0;
        for (sudoku.board.cells) |c| switch (c.data) {
            .puzzle, .user => |x| switch (x) {
                9 => count += 1,
                else => continue,
            },
            else => continue,
        };
        try std.testing.expect(count == 1);
    }

    test "get" {
        var sudoku = try Sudoku.init(std.testing.allocator, rand());
        defer sudoku.deinit();

        try sudoku.set(0, 2, 9);
        const val = try sudoku.get(0, 2);
        try std.testing.expect(val == 9);
    }
};

test {
    _ = Sudoku;
}

inline fn rand() std.rand.Random {
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        std.os.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    return prng.random();
}
