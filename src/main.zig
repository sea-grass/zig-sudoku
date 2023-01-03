// zig-sudoku
// Author: sea-grass
// Date: 2022-12-08
// Play Sudoku in your terminal with zig-sudoku.

const std = @import("std");
const Sudoku = @import("sudoku.zig").Sudoku;
const ansi = @import("ansi.zig");
const readLine = @import("io.zig").readLine;

const ArgError = error{
    MissingFilePath,
    UnknownArgument,
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

    var sudoku = try Sudoku.init(allocator, rand);
    defer sudoku.deinit();

    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    var input_file: []const u8 = "";

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    if (args.skip()) {
        while (args.next()) |arg| {
            if (std.mem.eql(u8, arg, "-f")) {
                if (args.next()) |path| {
                    // todo: create absolute path
                    input_file = path;
                } else {
                    return ArgError.MissingFilePath;
                }
            } else {
                return ArgError.UnknownArgument;
            }
        }
    }

    var buffer: [8]u8 = undefined;

    if (input_file.len > 0) {
        try stdout.print("Loading sudoku from {s}. Press enter to continue.\n", .{input_file});
        _ = readLine(stdin, &buffer);
    }

    var state: enum {
        Title,
        Quit,
        StartGame,
        MakeGuess,
        ShowHelpText,
        LoadSudoku,
    } = if (input_file.len > 0) .LoadSudoku else .Title;

    while (state != .Quit) {
        try stdout.print("{s}\n", .{ansi.screen_clear});
        try stdout.print("Sudoku\n\n", .{});
        switch (state) {
            .LoadSudoku => {
                // todo: load from file
                try sudoku.newGameFromFile(input_file);
                state = .MakeGuess;
            },
            .Title => {
                try stdout.print("This is Sudoku.\nStart a new game? (Y/n): ", .{});
                if (readLine(stdin, &buffer)) |line| {
                    if (line.len == 0 or std.mem.eql(u8, line, "y") or std.mem.eql(u8, line, "Y")) {
                        state = .StartGame;
                    } else if (std.mem.eql(u8, line, "n") or std.mem.eql(u8, line, "N") or std.mem.eql(u8, line, "q") or std.mem.eql(u8, line, "Q")) {
                        state = .Quit;
                    } else {
                        try stdout.print("Unknown choice.\n", .{});
                    }
                } else {
                    try stdout.print("huh?\n", .{});
                }
            },
            .StartGame => {
                try sudoku.newGame();
                state = .MakeGuess;
            },
            .ShowHelpText => {
                try stdout.print("help text\n", .{});
                try stdout.print("Press enter to continue.\n", .{});
                _ = readLine(stdin, &buffer);
                state = .MakeGuess;
            },
            .MakeGuess => {
                try stdout.print("{s}\n", .{sudoku});
                try stdout.print("Place a number. (h for help, q to quit)\n<row> <column> <number>\n", .{});
                if (readLine(stdin, &buffer)) |line| {
                    if (std.mem.eql(u8, line, "h") or std.mem.eql(u8, line, "H")) {
                        state = .ShowHelpText;
                    } else if (std.mem.eql(u8, line, "q") or std.mem.eql(u8, line, "Q")) {
                        state = .Quit;
                    } else {
                        const move = parseMove(line) catch blk: {
                            try stdout.print("invalid move :(\n", .{});
                            break :blk null;
                        };
                        if (move) |m| {
                            try stdout.print("Move: {any}\n", .{m});
                            sudoku.set(m.row, m.col, m.value) catch {
                                try stdout.print("! Cannot replace a puzzle value.\n", .{});
                            };
                        }
                    }
                } else unreachable;
            },
            .Quit => unreachable,
        }
    }
}

const Move = struct {
    row: usize,
    col: usize,
    value: u4,
};

fn parseMove(line: []const u8) !Move {
    var tokens = std.mem.split(u8, line, " ");

    // todo: fix segfault when input is too long
    const move = .{
        .row = if (tokens.next()) |row| try std.fmt.parseUnsigned(usize, row, 10) else return error.InvalidMove,
        .col = if (tokens.next()) |col| try std.fmt.parseUnsigned(usize, col, 10) else return error.InvalidMove,
        .value = if (tokens.next()) |value| try std.fmt.parseUnsigned(u4, value, 10) else return error.InvalidMove,
    };

    if (tokens.next()) |_| {
        return error.InvalidMove;
    }
    return move;
}
