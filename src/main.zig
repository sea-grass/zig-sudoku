// zig-sudoku
// Author: sea-grass
// Date: 2022-12-08
// Play Sudoku in your terminal with zig-sudoku.

const std = @import("std");
const Sudoku = @import("sudoku.zig").Sudoku;
const ansi = @import("ansi.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var sudoku = try Sudoku.init(allocator, 3);
    defer sudoku.deinit();

    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    var buffer: [8]u8 = undefined;

    var state: enum {
        Title,
        Quit,
        StartGame,
        MakeGuess,
        ShowHelpText,
    } = .Title;

    while (state != .Quit) {
        try stdout.print("{s}\n", .{ansi.screen_clear});
        try stdout.print("Sudoku\n\n", .{});
        switch (state) {
            .Title => {
                try stdout.print("This is Sudoku.\nStart a new game? (Y/n): ", .{});
                if (readLine(stdin, &buffer)) |line| {
                    if (line.len == 0 or std.mem.eql(u8, line, "y") or std.mem.eql(u8, line, "Y")) {
                        state = .StartGame;
                    } else if (std.mem.eql(u8, line, "n") or std.mem.eql(u8, line, "N")) {
                        state = .Quit;
                    } else {
                        try stdout.print("Unknown choice.\n", .{});
                    }
                } else {
                    try stdout.print("huh?\n", .{});
                }
            },
            .StartGame => {
                sudoku.newGame();
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

fn readLine(reader: anytype, buffer: []u8) ?[]const u8 {
    return reader.readUntilDelimiterOrEof(buffer, '\n') catch blk: {
        reader.skipUntilDelimiterOrEof('\n') catch {};
        break :blk undefined;
    };
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
