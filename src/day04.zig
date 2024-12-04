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

const term = "XMAS";
const mert = "SAMX"; // todo

const TERM_SIZE = term.len;
const BORDER = TERM_SIZE / 2;

const Word = [TERM_SIZE]u8;
const CellMatrix = [TERM_SIZE][TERM_SIZE]u8;

const Window = struct {
    cells: CellMatrix = undefined,
    data: *Data,
    start_x: usize,
    start_y: usize,

    pub fn init(data: *Data, x: usize, y: usize) Window {
        var w = Window{
            .data = data,
            .start_x = x,
            .start_y = y,
        };
        for (w.start_y..w.start_y + TERM_SIZE, 0..) |ry, iy| {
            for (w.start_x..w.start_x + TERM_SIZE, 0..) |rx, ix| {
                w.cells[iy][ix] = w.getChar(rx, ry);
            }
        }
        return w;
    }

    pub fn xyToIndex(self: *Window, x: usize, y: usize) usize {
        const d = self.data;
        const width = d.line_len;
        return (y * (width + 1)) + x;
    }

    fn getChar(self: *Window, x: usize, y: usize) u8 {
        const i = self.xyToIndex(x, y);
        if (i >= self.data.buffer.len) return '?';
        return (self.data.buffer.*)[i];
    }

    pub fn display(self: *Window) void {
        for (self.cells) |ys| {
            for (ys) |ch| {
                print("{c}", .{ch});
            }
            print(" :: [{d},{d}]\n", .{ self.start_x, self.start_y });
        }
        print("\n", .{});
    }

    pub fn countMatches(self: *const Window) i32 {
        return countHorz(self.cells) + countVert(self.cells) + countDiag(self.cells);
    }

    pub fn countHorz(cells: CellMatrix) i32 {
        var c: i32 = 0;
        for (cells) |ys| {
            if (eql(u8, &ys, term) or eql(u8, &ys, mert)) c += 1;
        }
        return c;
    }

    pub fn countVert(cells: CellMatrix) i32 {
        var sllec: CellMatrix = undefined;
        for (cells, 0..) |ys, iy| {
            for (ys, 0..) |x, ix| {
                sllec[ix][iy] = x;
            }
        }
        return countHorz(sllec);
    }

    fn countDiag(cells: CellMatrix) i32 {
        var c: i32 = 0;
        var ds: [2]Word = undefined;
        for (0..cells.len) |y| {
            for (0..cells.len) |x| {
                const j = TERM_SIZE - x - 1;
                ds[0][x] = cells[y][x];
                ds[1][x] = cells[y][j];
            }
        }

        if (eql(u8, &ds[0], term) or eql(u8, &ds[0], mert) or
            eql(u8, &ds[1], term) or eql(u8, &ds[1], mert)) c += 1;

        return c;
    }
};

const Data = struct {
    buffer: *[]const u8,
    line_len: usize,
    line_count: usize,
    row: usize,
    col: usize,
    windows: List(Window),

    fn init(alloc: Allocator, buffer: *[]const u8) Data {
        return .{
            .buffer = buffer,
            .line_len = 0,
            .line_count = 0,
            .row = 0,
            .col = 0,
            .windows = List(Window).init(alloc),
        };
    }

    fn setup(self: *Data) void {
        self.line_len = indexOf(u8, self.buffer.*, '\n').?;
        var it = splitSca(u8, self.buffer.*, '\n');
        while (it.next()) |_| {
            self.line_count += 1;
        }
    }

    fn buildWindowList(self: *Data) void {
        const bx = self.line_len - TERM_SIZE + 1;
        const by = self.line_count - TERM_SIZE + 1;

        for (0..by) |y| {
            for (0..bx) |x| {
                self.windows.append(Window.init(self, x, y)) catch unreachable;
            }
        }
        print("\n", .{});
    }

    fn count(self: *Data) i32 {
        var c: i32 = 0;
        for (self.windows.items) |w| {
            c += w.countMatches();
        }
        return c;
    }
};

pub fn main() !void {

    //part1();
}

pub fn part1(alloc: Allocator) i32 {
    var buffer: []const u8 = sample[0..];
    var grid = Data.init(alloc, &buffer);

    grid.setup();
    grid.buildWindowList();
    return grid.count();
}

//
// TEST
//
//
//
const test_alloc = std.testing.allocator;
const SimpleSample = "1234567890\n!@#$%^&*()\nabcdefghij\n1234567890\nABCDEFGHIJ"[0..];

test "sample data" {
    var buffer: []const u8 = sample[0..];
    var grid = Data.init(test_alloc, &buffer);
    grid.setup();
    const answer = part1(test_alloc);
    try std.testing.expectEqual(21, answer);
}

test "Window - sanity" {
    var buffer: []const u8 = SimpleSample;
    var grid = Data.init(test_alloc, &buffer);
    grid.setup();

    try expectEq(10, grid.line_len);
}

test "Window - getChar" {
    var buffer: []const u8 = sample[0..];
    var grid = Data.init(test_alloc, &buffer);
    grid.setup();

    var window = Window.init(&grid, 0, 0);

    for (0..4) |x| {
        try expectEq('.', window.getChar(x, 0));
    }
    try expectEq('S', window.getChar(1, 1));
    try expectEq('M', window.getChar(3, 1));

    window = Window.init(&grid, 4, 4);
    try expectEq('A', window.cells[0][0]);
    try expectEq('M', window.cells[0][1]);
    try expectEq('X', window.cells[0][2]);
    try expectEq('.', window.cells[0][3]);
    try expectEq('A', window.cells[3][3]);
}

test "collect Windows" {
    var buffer: []const u8 = sample[0..];
    var grid = Data.init(test_alloc, &buffer);
    grid.setup();
    try expectEq(grid.line_len, 10);
    try expectEq(grid.line_count, 10);

    // var list = List(Window).init(test_alloc);
    // defer list.deinit();

    grid.buildWindowList();
    // for (list.items) |*w| {
    //     w.display();
    // }

    try expectEq(49, grid.windows.items.len);
}

test "count" {
    var buffer: []const u8 = (
        \\XMAX
        \\MMMX
        \\AAMM
        \\SAMX
    )[0..];

    var grid = Data.init(test_alloc, &buffer);
    grid.setup();

    var w = Window.init(&grid, 0, 0);
    // w.display();

    try expectEq(1, Window.countHorz(w.cells));
    try expectEq(1, Window.countVert(w.cells));
    try expectEq(1, Window.countDiag(w.cells));
    try expectEq(3, w.countMatches());
}

//
//
//
//
//
//

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

var sample =
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
