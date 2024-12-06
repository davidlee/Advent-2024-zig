const std = @import("std");
const util = @import("util.zig");

const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const List = std.ArrayList;
const gpa = util.gpa;
const test_allocator = util.test_allocator;

const splitSca = std.mem.splitScalar;
const indexOf = std.mem.indexOfScalar;
const indexOfAny = std.mem.indexOfAny;

const print = std.debug.print;

var data: []const u8 = @embedFile("data/day06.txt");
var sample: []const u8 = @embedFile("data/day06_sample.txt");

// ╘══════════════════════════════════════════════════════════════════════════════════════════════╛
//  Main
// ╒══════════════════════════════════════════════════════════════════════════════════════════════╕

pub fn main() !void {
    var grid = Grid.init(gpa, &data);
    grid.walk();
    grid.display();
    print(" {d}", .{grid.footsteps.items.len});
}

// ╘══════════════════════════════════════════════════════════════════════════════════════════════╛
//  Types
// ╒══════════════════════════════════════════════════════════════════════════════════════════════╕

const Point = struct {
    x: usize,
    y: usize,

    fn move(self: Point, grid: *Grid, direction: [2]i32) Point {
        _ = grid;
        var x = self.x;
        var y = self.y;
        if (direction[0] < 0) {
            x -|= @abs(direction[0]);
        } else {
            x += @as(usize, @intCast(direction[0]));
            // x = @min(grid.width, x + @as(usize, @intCast(direction[0])));
        }
        if (direction[1] < 0) {
            y -|= @abs(direction[1]);
        } else {
            y += @as(usize, @intCast(direction[1]));
            // y = @min(grid.height, y + @as(usize, @intCast(direction[1])));
        }
        return Point{ .x = x, .y = y };
    }
};

const Set = AutoHashMap(Point, u32);

const Directions = [4][2]i32{
    .{ 0, -1 }, // Up
    .{ 1, 0 }, // Right
    .{ 0, 1 }, // Down
    .{ -1, 0 }, // Left
};

const MapError = error{OutOfBounds};

// ╘══════════════════════════════════════════════════════════════════════════════════════════════╛
//  Grid
// ╒══════════════════════════════════════════════════════════════════════════════════════════════╕
const Grid = struct {
    width: usize = 0,
    height: usize = 0,
    buffer: *[]const u8,
    position: Point = undefined,
    dir_i: usize = 0,
    rocks: List(Point) = undefined,
    footsteps: List(Point) = undefined,

    fn get(self: *const Grid, x: usize, y: usize) u8 {
        return (self.buffer.*)[y * (self.width + 1) + x];
    }

    fn outOfBounds(self: *const Grid, x: usize, y: usize) bool {
        return (x < 0 or x > self.width or y < 0 or y > self.height);
    }

    fn passable(self: *const Grid, x: usize, y: usize) bool {
        if (self.outOfBounds(x, y)) return false;
        for (self.rocks.items) |rock| {
            if (rock.x == x and rock.y == y) {
                return false;
            }
        }
        return true;
    }

    fn init(alloc: Allocator, buffer: *[]const u8) Grid {
        var g = Grid{
            .buffer = buffer,
            .rocks = List(Point).init(alloc),
            .footsteps = List(Point).init(alloc),
        };
        g.width = indexOf(u8, buffer.*, '\n').?;
        g.height = buffer.len / g.width;
        for (0..g.height) |y| {
            for (0..g.width) |x| {
                const tile = g.get(x, y);
                switch (tile) {
                    '#' => g.rocks.append(Point{ .x = int(x), .y = int(y) }) catch unreachable,
                    '^' => g.position = Point{ .x = int(x), .y = int(y) },
                    else => {},
                }
            }
        }

        return g;
    }

    fn walk(self: *Grid) void {
        while (true) {
            const next = self.position.move(&(self.*), Directions[self.dir_i]);
            // print("pos: {d},{d}\n", .{ self.position.x, self.position.y });
            // print("next: {d},{d}\n", .{ next.x, next.y });
            // self.display();
            if (self.outOfBounds(next.x, next.y)) {
                return;
            }
            if (self.passable(next.x, next.y)) {
                self.addFootsteps(next);
                self.position = next;
                continue;
            } else {
                self.dir_i = (self.dir_i + 1) % Directions.len;
                print(">> {d}", .{self.dir_i});
            }
        }
    }

    fn addFootsteps(self: *Grid, pos: Point) void {
        if (self.hasVisited(pos.x, pos.y))
            return;

        self.footsteps.append(pos) catch unreachable;
    }

    fn hasVisited(self: *Grid, x: usize, y: usize) bool {
        for (self.footsteps.items) |footstep|
            if (footstep.x == x and footstep.y == y)
                return true;
        return false;
    }

    fn display(self: *Grid) void {
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                if (self.position.x == x and self.position.y == y) {
                    print("^", .{});
                } else if (self.passable(x, y)) {
                    if (self.hasVisited(x, y)) {
                        print("$", .{});
                    } else {
                        print(".", .{});
                    }
                } else {
                    print("#", .{});
                }
            }
            print("\n", .{});
        }
        print("\n\n", .{});
    }

    fn deinit(self: *Grid) void {
        self.map.deinit();
        self.rocks.deinit();
        self.footsteps.deinit();
    }

    fn int(i: usize) usize {
        return @as(usize, @intCast(i));
    }
};

// ╘══════════════════════════════════════════════════════════════════════════════════════════════╛
//  tests
// ╒══════════════════════════════════════════════════════════════════════════════════════════════╕

const expect = std.testing.expect;
const expectEq = std.testing.expectEqual;
const expectEqStrings = std.testing.expectEqualStrings;
const expectError = std.testing.expectError;

test "it compiles" {
    try expect(true);
}
