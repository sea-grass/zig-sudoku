const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn Stack(comptime T: type) type {
    return struct {
        array_list: ArrayList(T),
        len: usize,

        pub fn head(self: Self) ?T {
            if (self.len == 0) return null;
            const items = self.array_list.items;
            return items[items.len - 1];
        }

        pub fn push(self: *Self, item: T) !void {
            try self.array_list.append(item);
            self.len = self.array_list.items.len;
        }

        pub fn pop(self: *Self) ?T {
            defer self.len = self.array_list.items.len;
            return self.array_list.popOrNull();
        }

        const Self = @This();

        pub fn init(a: Allocator) Self {
            return .{
                .array_list = ArrayList(T).init(a),
                .len = 0,
            };
        }

        pub fn deinit(self: *Self) void {
            self.array_list.deinit();
        }
    };
}

test "Stack" {
    const allocator = std.testing.allocator;
    var stack = Stack(u8).init(allocator);
    defer stack.deinit();

    {
        var i: usize = 10;
        while (i > 0) : (i -= 1) {
            try stack.push(@intCast(u8, i));
        }
    }

    std.debug.print("\n{d}\n", .{stack.head().?});

    while (stack.pop()) |item| {
        std.debug.print("\n{d} ({d} items remaining)\n", .{ item, stack.len });
    }
}
