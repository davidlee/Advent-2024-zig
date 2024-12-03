const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day03.txt");

const State = enum {
    Mul,
    FirstNumber,
    SecondNumber,
    Done,
    Invalid,
};

const mul = "mul(";
const do = "do()";
const dont = "don't()";

const Operation = struct {
    state: State,
    start_index: usize = 0,
    index: usize = 0,
    buffer: *[]const u8 = undefined,
    operands: [2]u16 = .{ 0, 0 },

    fn apply(self: *Operation) u64 {
        return @as(u64, self.operands[0]) * @as(u64, self.operands[1]);
    }

    fn init(self: *Operation, buffer: *[]const u8, start_index: usize) void {
        self.* = .{ .buffer = buffer, .index = start_index, .start_index = start_index, .state = .Mul };
    }

    fn next(self: *Operation) bool {
        const i = self.index - self.start_index;
        const ch = self.buffer.*[self.index];
        // print("  state: {c} {d} {d} {s}\n", .{ ch, self.start_index, i, @tagName(self.state) });
        switch (self.state) {
            .Mul => {
                if (ch != mul[i]) {
                    self.state = .Invalid;
                }

                if (i == mul.len - 1)
                    self.state = .FirstNumber;
            },
            .FirstNumber => {
                switch (ch) {
                    '0'...'9' => self.operands[0] = self.operands[0] * 10 + (ch - '0'),
                    ',' => self.state = .SecondNumber,
                    else => self.state = .Invalid,
                }
            },
            .SecondNumber => {
                switch (ch) {
                    '0'...'9' => self.operands[1] = self.operands[1] * 10 + (ch - '0'),
                    ')' => self.state = .Done,
                    else => self.state = .Invalid,
                }
            },
            .Done => unreachable,
            .Invalid => unreachable,
        }
        // hack: don't skip the start of a valid seq after an invalid character
        // and no infinite loops either
        if (self.index - self.start_index == 0 or (ch != 'm' and ch != 'd'))
            self.index += 1;

        return self.state != .Done and self.state != .Invalid;
    }
};

const Parser = struct {
    buffer: *[]const u8,
    index: usize = 0,
    total: u64 = 0,
    skip: bool = false,

    fn init(self: *Parser, buffer: *[]const u8) void {
        self.* = .{ .buffer = buffer, .index = 0, .total = 0 };
    }

    fn nextWordIs(self: *Parser, word: []const u8) bool {
        if (self.index + word.len <= self.buffer.len) {
            for (word, 0..) |ch, i| {
                if (self.buffer.*[self.index + i] != ch) return false;
            }
            return true;
        }
        return false;
    }

    fn process(self: *Parser) void {
        while (self.index < self.buffer.len) {
            if (self.skip) {
                if (self.nextWordIs(do)) {
                    self.skip = false;
                    self.index += do.len - 1;
                }
                self.index += 1;
                continue;
            } else if (self.nextWordIs(dont)) {
                self.skip = true;
                self.index += dont.len - 1;
                continue;
            }

            var op = gpa.create(Operation) catch unreachable;
            defer gpa.destroy(op);

            op.init(self.buffer, self.index);
            while (op.next()) {}
            if (op.state == .Done) {
                self.total += op.apply();
            }
            self.index = op.index;
        }
    }
};

pub fn main() void {
    var parser = gpa.create(Parser) catch unreachable;
    defer gpa.destroy(parser);
    var buffer: []const u8 = data;
    parser.init(&buffer);
    parser.process();

    const stdout = std.io.getStdOut().writer();
    stdout.print("{d}\n", .{parser.total}) catch unreachable;
}

// tests
//

test "op OK" {
    var op = std.testing.allocator.create(Operation) catch unreachable;
    defer std.testing.allocator.destroy(op);

    var buffer: []const u8 = "mul(13,24)";
    op.init(&buffer, 0);
    while (op.next()) {}
    try std.testing.expectEqual(.Done, op.state);
    try std.testing.expectEqual(13, op.operands[0]);
    try std.testing.expectEqual(24, op.operands[1]);
    try std.testing.expectEqual(312, op.apply());
}

test "op BAD" {
    var op = std.testing.allocator.create(Operation) catch unreachable;
    defer std.testing.allocator.destroy(op);

    var buffer: []const u8 = "mul(13, 42)";
    op.init(&buffer, 0);
    while (op.next()) {}
    try std.testing.expectEqual(.Invalid, op.state);
}

test "parser OK" {
    var parser = std.testing.allocator.create(Parser) catch unreachable;
    defer std.testing.allocator.destroy(parser);

    var buffer: []const u8 = "mul(12,10)";
    parser.init(&buffer);

    try std.testing.expectEqual(0, parser.total);
    parser.process();

    try std.testing.expectEqual(120, parser.total);
}

test "parser sneaky bitch OK" {
    var parser = std.testing.allocator.create(Parser) catch unreachable;
    defer std.testing.allocator.destroy(parser);

    var buffer: []const u8 = "mul(12mul(12,10)";
    parser.init(&buffer);

    try std.testing.expectEqual(0, parser.total);
    parser.process();

    try std.testing.expectEqual(120, parser.total);
}

test "word is" {
    var parser = std.testing.allocator.create(Parser) catch unreachable;
    defer std.testing.allocator.destroy(parser);

    var buffer: []const u8 = "don't()";
    parser.init(&buffer);
    try std.testing.expect(parser.nextWordIs("don't"));
}

test "parser 2" {
    var parser = std.testing.allocator.create(Parser) catch unreachable;
    defer std.testing.allocator.destroy(parser);

    var buffer: []const u8 = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))";
    parser.init(&buffer);

    try std.testing.expectEqual(0, parser.total);
    parser.process();

    try std.testing.expectEqual(48, parser.total);
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

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.block;
const asc = std.sort.asc;
const desc = std.sort.desc;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
