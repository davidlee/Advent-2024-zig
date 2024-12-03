const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day03.txt");

const StateTag = enum {
    Ready,
    Set,
    Go,

    fn index(self: StateTag) u8 {
        return @intFromEnum(self);
    }
};

const StateError = error{
    GuardFailed,
    InvalidTransition,
    OnEnterFailed,
    OnExitFailed,
};

const MAX_TRANSITIONS = 20;
const MAX_STATES = 20;

const State = struct {
    tag: StateTag,
    transitions: std.BoundedArray(*State, MAX_TRANSITIONS) = undefined,
    // context: void,
    guard: ?*const fn (*State) StateError!bool = null,
    on_enter: ?*const fn (*State, *State) StateError!void = null,
    on_exit: ?*const fn (*State, *State) StateError!void = null,

    pub fn index(self: *State) u8 {
        return @intFromEnum(self.tag);
    }

    pub fn name(self: *State) []const u8 {
        return @tagName(self.tag);
    }

    pub fn enter(self: *State, prev: *State) !void {
        if (self.on_enter) |on_enter|
            try on_enter(self, prev);
    }

    pub fn exit(self: *State, prev: *State) !void {
        if (self.on_exit) |on_exit|
            try on_exit(self, prev);
    }

    pub fn validTarget(self: *State, to: StateTag) bool {
        for (self.transitions) |t| {
            if (t == to) return true;
        }
        return false;
    }

    pub fn transitionTo(self: *State, to: StateTag) !void {
        if (!self.validTarget(to))
            return StateError.InvalidTransition;

        if (!self.guard(self))
            return StateError.GuardFailed;
    }

    pub fn create(tag: StateTag) *State {
        var state = State{
            .tag = tag,
        };
        state.transitions = std.BoundedArray(*State, MAX_TRANSITIONS).init(0) catch unreachable;
        // state.context = undefined;
        // state.guard = undefined;
        // state.on_enter = undefined;
        // state.on_exit = undefined;
        return &state;
    }
};

const FiniteStateMachine = struct {
    states: std.BoundedArray(*State, MAX_STATES) = .{},
    current: *State = undefined,
    stack: List(*State) = undefined,

    pub fn define(self: *FiniteStateMachine, state: *State) void {
        self.states.append(state) catch unreachable;
    }

    pub fn init(self: *FiniteStateMachine, current: *State) void {
        self.states = undefined;
        self.current = current;
        self.stack = List(*State).init(gpa);
    }

    pub fn transitionValid(self: *FiniteStateMachine, to: *State) bool {
        return self.current.validTarget(to);
    }

    pub fn transitionTo(self: *FiniteStateMachine, to: *State) !void {
        if (!self.transitionValid(to))
            return StateError.InvalidTransition;

        if (try !self.current.guard(self.current))
            return StateError.GuardFailed;

        try self.current.exit(to);
        const prev = self.current;
        self.current = to;
        try self.current.enter(prev);
        self.stack.append(self.current) catch unreachable;
    }

    pub fn create(allocator: std.mem.Allocator) *FiniteStateMachine {
        var fsm = allocator.create(FiniteStateMachine) catch unreachable;
        fsm.states = std.BoundedArray(*State, MAX_STATES).init(0) catch unreachable;
        fsm.stack = List(*State).init(allocator);
        fsm.current = undefined;
        return fsm;
    }
};

test "fsm" {
    var fsm = FiniteStateMachine.create(gpa);
    defer gpa.destroy(fsm);

    fsm.define(State.create(StateTag.Ready));
    fsm.define(State.create(StateTag.Set));
    fsm.define(State.create(StateTag.Go));

    fsm.init(fsm.states.get(0)); // Ready
    try std.testing.expectEqualStrings(fsm.current.name(), "Ready");
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
