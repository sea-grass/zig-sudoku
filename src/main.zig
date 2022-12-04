const std = @import("std");
const Sudoku = @import("sudoku.zig").Sudoku;

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
    } = .Title;

    while (state != .Quit) {
        switch (state) {
            .Title => {
                try stdout.print("Sudoku .\nNew game? (Y/n): ", .{});
                if (try readLine(stdin, &buffer)) |line| {
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
                sudoku.reset();
                state = .MakeGuess;
            },
            .MakeGuess => {
                try sudoku.print(stdout);
                if (try readLine(stdin, &buffer)) |line| {
                    const move = parseMove(line);
                    try stdout.print("Move: {any}\n", .{move});
                } else {
                    try stdout.print("huh?\n", .{});
                }
            },
            .Quit => unreachable,
        }
    }
}

fn readLine(reader: anytype, buffer: []u8) !?[]const u8 {
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
