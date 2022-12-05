const std = @import("std");

const Table = struct {
    list: std.ArrayList(u8),
    allocator: std.mem.Allocator,
    data: []const []const []const u8,
    // The maximum width of all values in the column.
    // This is computed when the table is initialized.
    col_widths: []usize,
    pub fn init(allocator: std.mem.Allocator, data: []const []const []const u8) !Table {
        if (data.len < 1) return error.DataCannotBeEmpty;
        // assume all rows have the same number of columns
        // TODO: validate that all rows have the same number of columns
        const num_cols = data[0].len;
        if (num_cols < 1) return error.RowWithoutColumns;

        var col_widths = try allocator.alloc(usize, num_cols);
        errdefer allocator.free(col_widths);

        // todo: detect if we haven't set any of them
        for (data) |row, row_index| {
            if (row.len != num_cols) return error.UnexpectedNumberOfColumns;
            for (row) |col, col_index| {
                if (row_index == 0 or col.len > col_widths[col_index]) {
                    col_widths[col_index] = col.len;
                }
            }
        }

        return .{
            .list = std.ArrayList(u8).init(allocator),
            .allocator = allocator,
            .data = data,
            .col_widths = col_widths,
        };
    }

    pub fn deinit(self: *Table) void {
        self.allocator.free(self.col_widths);
        self.list.deinit();
    }

    pub fn print(self: Table, writer: anytype) !void {
        for (self.data) |row| {
            for (row) |col, i| {
                var padding = self.col_widths[i] - col.len;
                var j: usize = padding;
                while (j > 0) : (j -= 1) {
                    try writer.print(" ", .{});
                }
                try writer.print("{s} ", .{col});
            }
            try writer.print("\n", .{});
        }
    }
};

test "Table" {
    const allocator = std.testing.allocator;
    var table = try Table.init(allocator, &.{
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
    defer table.deinit();

    const stdout = std.io.getStdOut().writer();
    try stdout.print("\n", .{});
    try table.print(stdout);
}
