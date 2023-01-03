const std = @import("std");

fn Tree(comptime Data: type) type {
    const Node = struct {
        data: Data,
    };

    return struct {
        allocator: std.mem.Allocator,
        children: ?std.ArrayList(*Node),

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .allocator = allocator,
                .children = null,
            };
        }
    };
}

pub fn DecisionTree(comptime Move: type) type {
    const Node = struct {
        move: Move,
        possible_moves: std.ArrayList(Move),
        parent: *@This(),
    };

    return struct {
        allocator: std.mem.Allocator,
        tree: Tree(Node),
        const Self = @This();
        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .allocator = allocator,
                .tree = Tree(Node).init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            _ = self;
        }
    };
}

test {
    const allocator = std.testing.allocator;
    const Move = struct {
        row: u32,
        col: u32,
        value: u32,
    };
    var tree = DecisionTree(Move).init(allocator);
    defer tree.deinit();
}

// Decision Tree
// Each node needs to know
// - the move to make
// - all possible moves that we could make from this move
// - its parent node
// when we make a move from the current node, we
// - make sure this move hasn't already been taken
// - create a new child node with the move
// - find all the new child node's possible moves
// - set the current node to the new child node
// - commit the change and set the square on the board
// when we backtrack, we
// - set the current node to the current node's parent node
// - repeat this process until the current node has at least one untraversed path
