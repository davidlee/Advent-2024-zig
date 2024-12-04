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

    pub fn init(self: *Maze, buffer: *[]const u8, alloc: Allocator) void {
        self.buffer = buffer;
        self.line_len = indexOf(u8, buffer.*, '\n').?;
        self.line_count = buffer.len / (self.line_len + 1) + 1;
        self.alloc = alloc;
        self.display();
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
    }

    pub fn count(self: *Maze) i32 {
        return (self.findHorizontal() +
            self.findVertical() +
            self.findDiagonal());
    }

    pub fn index(self: *Maze, x: usize, y: usize) usize {
        return (y * (self.line_len + 1) + x);
    }

    pub fn _get(self: *Maze, i: usize) u8 {
        if (i >= self.buffer.len) {
            print("ERR:{d} / {d}\n", .{ i, self.buffer.len });
            unreachable;
            // return 0;
        }
        return (self.buffer.*)[i];
    }

    pub fn get(self: *Maze, x: usize, y: usize) u8 {
        return self._get(self.index(x, y));
    }

    pub fn findHorizontal(self: *Maze) i32 {
        var c: i32 = 0;
        for (0..self.line_count) |y| {
            for (0..self.line_len - TERM_SIZE) |x| {
                var string: [TERM_SIZE]u8 = undefined;
                for (0..TERM_SIZE) |j| {
                    string[j] = self.get(x + j, y);
                }
                if (eql(u8, &string, TERM) or eql(u8, &string, MERT)) {
                    c += 1;
                    print("## [{d},{d}] HORZ | <{s}>\n", .{ x, y, string });
                }
            }
        }
        return c;
    }

    pub fn findVertical(self: *Maze) i32 {
        var c: i32 = 0;
        for (0..self.line_count) |y| {
            for (0..self.line_len) |x| {
                var string: [TERM_SIZE]u8 = undefined;

                for (0..TERM_SIZE) |j| {
                    const by = (y + j) % self.line_count;
                    string[j] = self.get(x, by);
                }
                if (eql(u8, &string, TERM) or eql(u8, &string, MERT)) {
                    print("++ [{d},{d}] VERT | <{s}>\n", .{ x, y, string });
                    c += 1;
                }
            }
        }
        return c;
    }

    pub fn findDiagonal(self: *Maze) i32 {
        var c: i32 = 0;
        for (0..self.line_count - TERM_SIZE + 1) |y| {
            for (0..self.line_len - TERM_SIZE + 1) |x| {
                // print("[x:{},y:{d}]", .{ x, y });
                var d1: Word = undefined;
                var d2: Word = undefined;
                for (0..TERM_SIZE) |j| {
                    const bx = (x + j);
                    const by = (y + j);
                    const cx = (x + TERM_SIZE - 1 - j);

                    d1[j] = self.get(bx, by);
                    d2[j] = self.get(cx, by);
                    // print("D2 [[{s}]] _ x:{},y:{} +j:{} ->(bx:{} by:{}) // -> (cx:{d} )\n", .{ d2, x, y, j, bx, by, cx });
                }
                if (eql(u8, &d1, TERM) or eql(u8, &d1, MERT)) {
                    // print("DIAG: >>{s} :: [{d},{d}]\n", .{ d1, x, y });
                    c += 1;
                }
                if (eql(u8, &d2, TERM) or eql(u8, &d2, MERT)) {
                    // print("DIAG: {s}<< :: [{d},{d}]\n", .{ d2, x, y });
                    c += 1;
                }
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
    m.display();

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
// const SimpleSample = "1234567890\n!@#$%^&*()\nabcdefghij\n1234567890\nABCDEFGHIJ"[0..];

// test "sample" {
//     var m = test_alloc.create(Maze) catch unreachable;
//     defer m.deinit();

//     var buf: []const u8 = (&sample[0..]).*;
//     m.init(&buf, test_alloc);

//     try expectEq(5, m.findHorizontal());
//     try expectEq(3, m.findVertical());
//     try expectEq(10, m.findDiagonal());
//     try expectEq(18, m.count());
// }

test "diags" {
    var m = test_alloc.create(Maze) catch unreachable;
    defer m.deinit();

    var buf: []const u8 = (&diags[0..]).*;
    m.init(&buf, test_alloc);

    try expectEq(4, m.findDiagonal());
}

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
