const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const splitSca = std.mem.splitScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;
const assert = std.debug.assert;
const indexOf = std.mem.indexOfScalar;
const lastIndexOf = std.mem.lastIndexOfScalar;

var data: []const u8 = @embedFile("data/day05.txt");
var sample: []const u8 = @embedFile("data/day05_sample.txt");

// ╘══════════════════════════════════════════════════════════════════════════════════════════════╛
//  Main
// ╒══════════════════════════════════════════════════════════════════════════════════════════════╕

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    var m = alloc.create(Validator) catch unreachable;
    m.init(alloc, &data);
    defer m.deinit();

    m.countFixed();
}

// ╘══════════════════════════════════════════════════════════════════════════════════════════════╛
//  Types
// ╒══════════════════════════════════════════════════════════════════════════════════════════════╕

const Rule = struct {
    before: i32,
    after: i32,
};

const Section = enum {
    Rules,
    Updates,
};

const Update = List(i32);

// ╘══════════════════════════════════════════════════════════════════════════════════════════════╛
//  Reader
// ╒══════════════════════════════════════════════════════════════════════════════════════════════╕

const Reader = struct {
    alloc: Allocator,
    buffer: *[]const u8,
    rules: List(Rule) = undefined,
    updates: List(Update) = undefined,
    section: Section = .Rules,

    pub fn init(self: *Reader, alloc: Allocator, buffer: *[]const u8) void {
        self.buffer = buffer;
        self.alloc = alloc;
        self.rules = List(Rule).init(alloc);
        self.updates = List(Update).init(alloc);
    }

    pub fn deinit(self: *Reader) void {
        for (self.updates.items) |update| {
            update.deinit();
        }
        self.updates.deinit();
        self.rules.deinit();
    }

    pub fn load(self: *Reader) void {
        var lines = splitSca(u8, (self.buffer.*), '\n');
        var it = lines.next();
        while (it) |line| : (it = lines.next()) {
            switch (self.section) {
                .Rules => {
                    if (line.len == 0) {
                        self.section = .Updates;
                        continue;
                    }
                    var bits = splitSca(u8, line, '|');
                    const rule = Rule{
                        .before = parseInt(i32, bits.next().?, 10) catch unreachable,
                        .after = parseInt(i32, bits.next().?, 10) catch unreachable,
                    };
                    self.rules.append(rule) catch unreachable;
                },
                .Updates => {
                    var update: Update = Update.init(self.alloc);
                    var bits = splitSca(u8, line, ',');
                    var iter = bits.next();
                    while (iter) |num| : (iter = bits.next()) {
                        const n = parseInt(i32, num, 10) catch unreachable;
                        update.append(n) catch unreachable;
                    }
                    self.updates.append(update) catch unreachable;
                },
            }
        }
    }
};

// ╘══════════════════════════════════════════════════════════════════════════════════════════════╛
//  Validator
// ╒══════════════════════════════════════════════════════════════════════════════════════════════╕

const Validator = struct {
    reader: *Reader = undefined,
    alloc: Allocator,

    pub fn init(self: *Validator, alloc: Allocator, buffer: *[]const u8) void {
        self.alloc = alloc;
        self.reader = alloc.create(Reader) catch unreachable;
        self.reader.init(alloc, buffer);
        self.reader.load();
    }

    pub fn deinit(self: *Validator) void {
        self.reader.deinit();
        self.alloc.destroy(self.reader);
        self.alloc.destroy(self);
    }

    pub fn check(self: *Validator, update: *const Update) bool {
        for (self.reader.rules.items) |rule| {
            if (!Validator.isSatisfied(update, &rule)) {
                return false;
            }
        }
        return true;
    }

    pub fn fix(self: *Validator, update: *Update) void {
        for (self.reader.rules.items) |rule| {
            if (!Validator.isSatisfied(update, &rule)) {
                const after_i = (indexOf(i32, update.items, rule.after)).?;
                const before_i = (lastIndexOf(i32, update.items, rule.before)).?;
                const before = update.orderedRemove(before_i);
                update.insert(after_i, before) catch unreachable;
                print("fixed {d}\n", .{before});
                for (update.items) |item| {
                    print("{d} ", .{item});
                }
                print("\n", .{});
                return;
            }
        }
        assert(self.check(update));
    }

    fn isSatisfied(update: *const Update, rule: *const Rule) bool {
        const before = rule.before;
        const after = rule.after;
        const after_i = if (indexOf(i32, update.items, after)) |i| i else return true;
        const before_i = if (lastIndexOf(i32, update.items, before)) |i| i else return true;
        return before_i < after_i;
    }

    pub fn countValid(self: *Validator) void {
        var count: i32 = 0;
        for (self.reader.updates.items) |update| {
            if (self.check(&update)) {
                const i = @divFloor(update.items.len, 2);
                count += update.items[i];
            }
        }
    }

    pub fn countFixed(self: *Validator) void {
        var count: i32 = 0;
        for (self.reader.updates.items) |*update| {
            if (self.check(update)) continue;
            while (!self.check(update)) {
                self.fix(update);
            }
            if (self.check(update)) {
                const i = @divFloor(update.items.len, 2);
                count += update.items[i];
            } else unreachable;
        }
        print("{d}\n", .{count});
    }
};
