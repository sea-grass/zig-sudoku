const std = @import("std");

pub fn write(writer: anytype, allocator: std.mem.Allocator, data: []const []const []const u8) !void {
    if (data.len < 1) return error.DataCannotBeEmpty;
    // assume all rows have the same number of columns
    // TODO: validate that all rows have the same number of columns
    const num_cols = data[0].len;
    if (num_cols < 1) return error.RowWithoutColumns;

    var col_widths = try allocator.alloc(usize, num_cols);
    defer allocator.free(col_widths);

    // todo: detect if we haven't set any of them
    for (data) |row, row_index| {
        if (row.len != num_cols) return error.UnexpectedNumberOfColumns;
        for (row) |col, col_index| {
            if (row_index == 0 or col.len > col_widths[col_index]) {
                col_widths[col_index] = col.len;
            }
        }
    }

    for (data) |row| {
        for (row) |col, i| {
            var padding = col_widths[i] - col.len;
            var j: usize = padding;
            while (j > 0) : (j -= 1) {
                try writer.print(" ", .{});
            }
            try writer.print("{s} ", .{col});
        }
        try writer.print("\n", .{});
    }
}

test "Table" {
    const allocator = std.testing.allocator;
    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();

    try write(list.writer(), allocator, &.{
        @as([]const []const u8, &.{
            "name",
            "history grade",
            "art grade",
        }),
        @as([]const []const u8, &.{
            "Billy",
            "42",
            "92",
        }),
        @as([]const []const u8, &.{
            "Josh",
            "51",
            "83",
        }),
        @as([]const []const u8, &.{
            "Brenda",
            "58",
            "72",
        }),
    });

    const stdout = std.io.getStdOut().writer();
    try stdout.print("\n{s}\n", .{list.items});
}
