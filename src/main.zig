const std = @import("std");
const Sudoku = @import("sudoku.zig").Sudoku;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();
    var state: enum {
        Title,
        Quit,
        Playing,
    } = .Title;
    var buffer: [8]u8 = undefined;
    while (state != .Quit) {
        switch (state) {
            .Title => {
                try stdout.print("Sudoku .\nNew game? (Y/n): ", .{});
                var line = (try stdin.readUntilDelimiterOrEof(
                    &buffer,
                    '\n',
                )).?;

                try stdout.print("Sup {s}\n", .{line});
                if (line.len == 0 or std.mem.eql(u8, line, "y") or std.mem.eql(u8, line, "Y")) {
                    state = .Playing;
                } else if (std.mem.eql(u8, line, "n") or std.mem.eql(u8, line, "N")) {
                    state = .Quit;
                } else {
                    try stdout.print("Unknown choice.\n", .{});
                }
            },
            .Playing => {
                try playSudoku();
                state = .Quit;
            },
            .Quit => break,
        }
    }
}

pub fn playSudoku() !void {
    const allocator = std.heap.page_allocator;
    var sudoku = try Sudoku.init(allocator, 3);
    defer sudoku.deinit();

    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();
    var buffer: [8]u8 = undefined;

    var loop = true;
    while (loop) {
        try sudoku.print(stdout);
        var line = (try stdin.readUntilDelimiterOrEof(
            &buffer,
            '\n',
        )).?;
        var tokens = std.mem.split(u8, line, " ");
        const move = .{
            .row = tokens.next() orelse return error.InvalidMove,
            .col = tokens.next() orelse return error.InvalidMove,
            .value = tokens.next() orelse return error.InvalidMove,
        };
        try stdout.print("Move: {any}\n", .{move});
    }
}
