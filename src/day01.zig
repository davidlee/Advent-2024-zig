const std = @import("std");
const INPUT_FILE_PATH = "./data/day01.txt";
const MAX_SIZE = 1024 * 1024;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    // defer gpa.deinit();

    var left_list = std.ArrayList(u32).init(allocator);
    defer left_list.deinit();

    var right_list = std.ArrayList(u32).init(allocator);
    defer right_list.deinit();

    const file = try std.fs.cwd().openFile(INPUT_FILE_PATH, .{});
    defer file.close();

    const reader = file.reader();
    const buffer = try reader.readAllAlloc(allocator, MAX_SIZE);
    defer allocator.free(buffer);

    var lines_it = std.mem.splitScalar(u8, buffer, '\n');
    var it: ?[]const u8 = lines_it.first();

    var difference_sum: u32 = 0;

    while (it) |line| : (it = lines_it.next()) {
        if (line.len == 0) continue;

        var words_it = std.mem.tokenizeScalar(u8, line, ' ');
        const left = std.fmt.parseUnsigned(u32, words_it.next().?, 10) catch unreachable;
        const right = std.fmt.parseUnsigned(u32, words_it.next().?, 10) catch unreachable;

        try left_list.append(left);
        try right_list.append(right);
    }

    std.debug.assert(left_list.items.len == right_list.items.len);

    std.mem.sort(u32, left_list.items, {}, std.sort.asc(u32));
    std.mem.sort(u32, right_list.items, {}, std.sort.asc(u32));

    for (0..left_list.items.len) |i| {
        const ns = .{ .left = left_list.items[i], .right = right_list.items[i] };
        var diff: u32 = 0;

        if (ns.left > ns.right) {
            diff = ns.left - ns.right;
        } else if (ns.left < ns.right) {
            diff = ns.right - ns.left;
        }
        difference_sum += diff;
    }
    const stdout = std.io.getStdOut().writer();
    stdout.print("{d}\n", .{difference_sum}) catch unreachable;
}
