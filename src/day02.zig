const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day02.txt");

pub fn main() !void {
    var reports = Grid.init(gpa);
    defer reports.deinit();

    ingest(gpa, data, &reports);

    const ok = countAll(&reports);

    const stdout = std.io.getStdOut().writer();
    stdout.print("{d}\n", .{ok}) catch unreachable;
}

fn isOk(report: *Report) bool {
    var sign: i8 = undefined;

    for (report.items, 0..) |num, i| {
        if (i == 0) continue;

        const prev = report.items[i - 1];
        const delta = num - prev;

        if (i == 1)
            sign = clamp(delta, -1, 1);

        if (delta * sign > 3 or delta * sign <= 0)
            return false;
    }
    return true;
}

fn isDampenedOk(report: *Report) bool {
    if (isOk(report)) return true;

    for (0..report.items.len) |i| {
        var copy = report.clone() catch unreachable;
        _ = copy.orderedRemove(i);
        if (isOk(&copy)) return true;
    }

    return false;
}

fn countAll(reports: *Grid) usize {
    var count_ok: usize = 0;
    for (reports.items) |*report| {
        if (isDampenedOk(report))
            count_ok += 1;
    }
    return count_ok;
}

const Entry = i8;
const Report = List(Entry);
const Grid = List(Report);

fn ingest(allocator: Allocator, buffer: []const u8, reports: *Grid) void {
    var lines = splitSca(u8, buffer, '\n');
    var it = lines.next();
    while (it) |line| : (it = lines.next()) {
        if (line.len == 0) continue;
        var nums = tokenizeSca(u8, line, ' ');
        var nit = nums.next();
        var list = List(i8).init(allocator);

        while (nit) |chars| : (nit = nums.next()) {
            list.append(parseInt(i8, chars, 10) catch unreachable) catch unreachable;
        }
        reports.append(list) catch unreachable;
    }
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
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;
const clamp = std.math.clamp;
const trim = std.mem.trim;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.block;
const asc = std.sort.asc;
const desc = std.sort.desc;

test "1 2 3 4 5 : OK" {
    var report = Report.init(gpa);
    defer report.deinit();

    const vs = [_]i8{ 1, 2, 3, 4, 5 };
    for (vs) |v|
        report.append(v) catch unreachable;

    try std.testing.expect(isOk(&report));
}

test "1 4 6 9 11 : OK" {
    var report = Report.init(gpa);
    defer report.deinit();

    const vs = [_]i8{ 1, 4, 6, 9, 11 };
    for (vs) |v|
        report.append(v) catch unreachable;

    try std.testing.expect(isOk(&report));
}

test "14 11 10 9 6 4 : OK" {
    var report = Report.init(gpa);
    defer report.deinit();

    const vs = [_]i8{ 14, 11, 10, 9, 6, 4 };
    for (vs) |v|
        report.append(v) catch unreachable;

    try std.testing.expect(isOk(&report));
}

test "1 2 2 3 : FAIL (OK)" {
    var report = Report.init(gpa);
    defer report.deinit();

    const vs = [_]i8{ 1, 2, 2, 3 };
    for (vs) |v|
        report.append(v) catch unreachable;

    try std.testing.expect(!isOk(&report));
}

test "1 3 1 : FAIL" {
    var report = Report.init(gpa);
    defer report.deinit();

    const vs = [_]i8{ 1, 3, 1 };
    for (vs) |v|
        report.append(v) catch unreachable;

    try std.testing.expect(!isOk(&report));
}

test "3 2 3 : FAIL" {
    var report = Report.init(gpa);
    defer report.deinit();

    const vs = [_]i8{ 3, 2, 3 };
    for (vs) |v|
        report.append(v) catch unreachable;

    try std.testing.expect(!isOk(&report));
}
