const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const meta = std.meta;

const util = @import("util.zig");
const gpa = util.gpa;

const raw_data = @embedFile("data/day04.txt");

const TERM = "XMAS";
const MERT = "SAMX";
const TERM_SIZE = 4;
const Word = [TERM_SIZE]u8;
const CellMatrix = [TERM_SIZE][TERM_SIZE]u8;

const Addr = struct {
    x: usize,
    y: usize,
};

const Maze = struct {
    buffer: *[]const u8,
    line_len: usize,
    line_count: usize,
    term: []u8,
    mert: []u8,
    alloc: Allocator,
    as: List(Addr) = undefined,

    pub fn init(self: *Maze, buffer: *[]const u8, alloc: Allocator) void {
        self.buffer = buffer;
        self.line_len = indexOf(u8, buffer.*, '\n').?;
        self.line_count = buffer.len / (self.line_len + 1) + 1;
        self.alloc = alloc;
        // self.display();
        self.as = List(Addr).init(alloc);
    }

    pub fn findAs(self: *Maze) void {
        if (self.as.items.len > 0) {
            return;
        }
        for (0..self.line_count) |y| {
            for (0..self.line_len) |x| {
                if (self.get(x, y) == 'A') {
                    const a = Addr{ .x = x, .y = y };
                    if (a.x < 1 or a.y < 1 or a.x + 1 > self.line_len or a.y + 1 > self.line_count) {
                        continue;
                    }
                    self.as.append(a) catch unreachable;
                }
            }
        }
    }

    pub fn findMases(self: *Maze) i32 {
        self.findAs();
        var c: i32 = 0;
        for (self.as.items) |a| {
            // top left to bottom right
            const tl = self.get(a.x - 1, a.y - 1);
            const br = self.get(a.x + 1, a.y + 1);
            const tr = self.get(a.x + 1, a.y - 1);
            const bl = self.get(a.x - 1, a.y + 1);
            if (((tl == 'M' and br == 'S') or (tl == 'S' and br == 'M')) and ((tr == 'M' and bl == 'S') or (tr == 'S' and bl == 'M'))) {
                c += 1;
            }
        }
        self.as.deinit();
        return c;
    }

    pub fn display(self: *Maze) void {
        print("\n", .{});
        for (0..self.line_count) |y| {
            for (0..self.line_len) |x| {
                print("{c}", .{self.get(x, y)});
            }
            print("\n", .{});
        }
    }

    pub fn deinit(self: *Maze) void {
        self.alloc.destroy(self);
        // self.as.deinit();
    }

    pub fn count(self: *Maze) i32 {
        return self.findMases();
    }

    pub fn index(self: *Maze, x: usize, y: usize) usize {
        return (y * (self.line_len + 1) + x);
    }

    pub fn _get(self: *Maze, i: usize) u8 {
        if (i >= self.buffer.len) {
            // print("ERR:{d} / {d}\n", .{ i, self.buffer.len });
            // unreachable;
            return 0; // gross
        }
        return (self.buffer.*)[i];
    }

    pub fn get(self: *Maze, x: usize, y: usize) u8 {
        return self._get(self.index(x, y));
    }

    pub fn findDiagonal(self: *Maze) i32 {
        var c: i32 = 0;
        for (0..self.line_count - TERM_SIZE + 1) |y| {
            for (0..self.line_len - TERM_SIZE + 1) |x| {
                var d1: Word = undefined;
                var d2: Word = undefined;
                for (0..TERM_SIZE) |j| {
                    const bx = (x + j);
                    const by = (y + j);
                    const cx = (x + TERM_SIZE - 1 - j);

                    d1[j] = self.get(bx, by);
                    d2[j] = self.get(cx, by);
                }
                if (eql(u8, &d1, TERM) or eql(u8, &d1, MERT)) c += 1;
                if (eql(u8, &d2, TERM) or eql(u8, &d2, MERT)) c += 1;
            }
        }
        return c;
    }
};

pub fn main() void {
    var m = gpa.create(Maze) catch unreachable;
    defer m.deinit();

    var buf: []const u8 = (&raw_data[0..]).*;
    m.init(&buf, gpa);
    // m.display();

    print(">>  {d}\n\n", .{m.count()});
}

pub fn stage1() void {
    var m = gpa.create(Maze) catch unreachable;
    defer m.deinit();

    var buf: []const u8 = (&raw_data[0..]).*;
    m.init(&buf, gpa);
    m.display();

    print(">>  {d}\n\n", .{m.count()});
}

//
//
const test_alloc = std.testing.allocator;

test "mases" {
    var m = test_alloc.create(Maze) catch unreachable;
    defer m.deinit();

    var buf: []const u8 = (&mases[0..]).*;
    m.init(&buf, test_alloc);
    const c = m.count();

    print(">>  {d}\n\n", .{c});
    try expectEq(4, m.findMases());
}

// test "mas" {
//     var m = test_alloc.create(Maze) catch unreachable;
//     defer m.deinit();

//     var buf: []const u8 = (&mas[0..]).*;
//     m.init(&buf, test_alloc);
//     const c = m.count();

//     print(">>  {d}\n\n", .{c});
//     try expectEq(1, m.findMases());
// }

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSeq = std.mem.tokenizeSequence;
const tokenizeSca = std.mem.tokenizeScalar;
const splitAny = std.mem.splitAny;
const splitSeq = std.mem.splitSequence;
const splitSca = std.mem.splitScalar;
const indexOf = std.mem.indexOfScalar;
const indexOfAny = std.mem.indexOfAny;
const indexOfStr = std.mem.indexOfPosLinear;

const lastIndexOf = std.mem.lastIndexOfScalar;
const lastIndexOfAny = std.mem.lastIndexOfAny;
const lastIndexOfStr = std.mem.lastIndexOfLinear;
const trim = std.mem.trim;
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;
const eql = std.mem.eql;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.block;
const asc = std.sort.asc;
const desc = std.sort.desc;
const expect = std.testing.expect;
const expectEq = std.testing.expectEqual;
const expectEqStrings = std.testing.expectEqualStrings;
const expectError = std.testing.expectError;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.

var sample: []const u8 =
    \\....XXMAS.
    \\.SAMXMS...
    \\...S..A...
    \\..A.A.MS.X
    \\XMASAMX.MM
    \\X.....XA.A
    \\S.S.S.S.SS
    \\.A.A.A.A.A
    \\..M.M.M.MM
    \\.X.X.XMASX
;

var diags: []const u8 =
    \\X..X.
    \\.MM..
    \\.AA..
    \\S..S.
    \\.AA..
    \\.MM..
    \\XXXXX
;

var mases: []const u8 =
    \\.M.S......
    \\..A..MSMS.
    \\.M.S.MAA..
    \\..A.ASMSM.
    \\.M.S.M....
    \\..........
    \\S.S.S.S.S.
    \\.A.A.A.A..
    \\M.M.M.M.M.
    \\..........
;

var mas: []const u8 =
    \\M.S
    \\.A.
    \\M.S
;
