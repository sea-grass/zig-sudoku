const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn Tree(comptime T: type) type {
    return struct {
        pub const Self = @This();

        pub const Node = struct {
            data: T,
            parent: ?*@This(),
            children: ArrayList(*@This()),

            pub fn insert(self: *@This(), a: Allocator, data: T) !*@This() {
                var node: *Node = try a.create(Node);
                node.parent = self;
                node.children = ArrayList(*Node).init(a);
                node.data = data;

                try self.children.append(node);
                return node;
            }

            pub fn deinit(self: *@This(), a: Allocator) void {
                // TODO don't like how this happens here
                // but I also don't want every node to have
                // a reference to an allocator
                // ...might make sense to move deinit logic
                // from the node to the tree
                defer a.destroy(self);

                defer self.children.deinit();
                for (self.children.items) |c| {
                    c.deinit(a);
                }
            }
        };

        pub const Iterator = struct {
            tree: *Tree(T),
            allocator: Allocator,
            // depth-first search
            remaining: ?ArrayList(*Node) = null,
            started: bool = false,
            completed: bool = false,

            pub fn next(self: *@This()) !?*Node {
                if (self.tree.root == null) return null;
                if (self.completed) return null;

                if (!self.started) {
                    self.remaining = ArrayList(*Node).init(self.allocator);
                    try self.remaining.?.append(self.tree.root.?);
                    self.started = true;
                } else if (self.remaining.?.items.len == 0) {
                    self.completed = true;
                    self.remaining.?.deinit();
                    return null;
                }

                var node = self.remaining.?.pop();
                for (node.children.items) |child| {
                    // TODO don't add child if already seen
                    try self.remaining.?.append(child);
                }

                return node;
            }
        };

        allocator: Allocator,
        root: ?*Node,

        pub fn init(a: Allocator) Self {
            return .{
                .allocator = a,
                .root = null,
            };
        }

        pub fn deinit(self: *Self) void {
            if (self.root) |node| {
                node.deinit(self.allocator);
                //self.allocator.destroy(node);
            }
        }

        pub fn insert(self: *Self, parent: ?*Node, data: T) !*Node {
            if (parent == null and self.root != null) return error.UnknownTargetParentNode;

            if (parent == null) {
                if (self.root) |_| {
                    return error.UnknownTargetParentNode;
                } else return try self.insertRootNode(data);
            } else return try parent.?.insert(self.allocator, data);
        }

        // A slice gets inserted with each next item
        // being a child of the previous one.
        pub fn insertSlice(self: *Self, parent: ?*Node, data: []const T) !void {
            if (parent == null and self.root != null) return error.UnknownTargetParentNode;
            var curr: ?*Node = parent;
            for (data) |d| {
                curr = if (curr == null) try self.insertRootNode(d) else try curr.?.insert(self.allocator, d);
            }
        }

        fn insertRootNode(self: *Self, data: T) !*Node {
            // new root node
            var root: *Node = try self.allocator.create(Node);
            root.parent = null;
            root.children = ArrayList(*Node).init(self.allocator);
            root.data = data;
            self.root = root;
            return root;
        }
    };
}

test {
    const a = std.testing.allocator;
    var tree = Tree(u8).init(a);
    defer tree.deinit();

    _ = try tree.insert(tree.root, 1);
    _ = try tree.insertSlice(tree.root, &.{ 2, 3, 4 });
    std.debug.print("\ntree root: {d}\n", .{tree.root.?.data});

    var tree_it = Tree(u8).Iterator{ .tree = &tree, .allocator = a };

    while (try tree_it.next()) |node| {
        std.debug.print("Node {d} is in the tree\n", .{node.data});
    }
}
