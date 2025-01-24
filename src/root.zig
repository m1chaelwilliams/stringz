const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;

const StringError = error{
    IndexOutOfBounds,
};

const String = struct {
    const Self = @This();

    /// the buffer of data. len of buf is NOT always the length of the string!!!
    buf: []u8,
    /// the length of the string, not the capacity
    len: usize,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
            .buf = undefined,
            .len = 0,
        };
    }

    pub fn initCapacity(allocator: std.mem.Allocator, cap: usize) !Self {
        return Self{
            .allocator = allocator,
            .buf = try allocator.alloc(u8, cap),
            .len = 0,
        };
    }

    pub fn initFromSlice(allocator: std.mem.Allocator, str: []const u8) !Self {
        const buf = try allocator.alloc(u8, str.len);
        @memcpy(buf, str);
        return Self{
            .allocator = allocator,
            .len = str.len,
            .buf = buf,
        };
    }

    pub fn pushChar(self: *Self, char: u8) !void {
        if (self.len + 1 > self.buf.len) {
            self.buf = try self.allocator.realloc(self.buf, self.len + 1);
        }
        self.buf[self.len] = char;
        self.len += 1;
    }

    pub fn trimWhiteSpace(self: *Self) !void {
        if (self.len == 0) {
            return;
        }

        var left = 0;
        var right = self.len;

        while (left < self.len and self.buf[left] == ' ') : (left += 1) {}
        while (right > 0 and self.buf[right] == ' ') : (right -= 1) {}

        // whole string is whitespace
        if (left == right) {
            return;
        }

        std.mem.copyForwards(u8, self.buf, self.buf[left..right]);
        self.len = right;
    }

    pub fn pushSlice(self: *Self, str: []const u8) !void {
        if (self.len + str.len > self.buf.len) {
            self.buf = try self.allocator.realloc(self.buf, self.len + str.len);
        }
        std.mem.copyForwards(u8, self.buf[self.len..(self.len + str.len)], str);
        self.len += str.len;
    }

    pub fn pushString(self: *Self, other: *String) !void {
        try self.pushSlice(other.buf[0..other.len]);
        self.len += other.len;
    }

    pub fn slice(self: *const Self) []const u8 {
        return self.buf[0..self.len];
    }

    pub fn deinit(self: *const Self) void {
        self.allocator.free(self.buf);
    }

    pub fn clone(self: *const Self) !String {
        return String.initFromSlice(self.allocator, self.buf[0..self.len]);
    }

    pub fn empty(self: *Self) void {
        self.len = 0;
    }

    pub fn reverse(self: *Self) void {
        if (self.len < 2) {
            return;
        }

        var i: usize = 0;
        var j: usize = self.len - 1;

        while (i < self.len / 2) {
            const temp = self.buf[i];
            self.buf[i] = self.buf[j];
            self.buf[j] = temp;

            i += 1;
            j -= 1;
        }
    }

    pub fn prependChar(self: *Self, char: u8) !void {
        if (self.len + 1 > self.buf.len) {
            self.buf = try self.allocator.realloc(self.buf, self.len + 1);
        }
        for (self.buf, 0..) |ch, i| {
            self.buf[i + 1] = ch;
            self.buf[0] = char;
        }

        self.len += 1;
    }

    pub fn prependSlice(self: *Self, str: []const u8) !void {
        if (self.len + str.len > self.buf.len) {
            self.buf = try self.allocator.realloc(self.buf, self.len + str.len);
        }

        for (self.buf, 0..) |ch, i| {
            self.buf[i + str.len] = ch;
        }
        std.mem.copyForwards(u8, self.buf[0..str.len], str);
        self.len += 1;
    }

    pub fn insertChar(self: *Self, char: u8, index: usize) !void {
        return switch (index) {
            0 => self.prependChar(char),
            else => {
                if (index < self.len) {
                    if (self.len + 1 > self.buf.len) {
                        self.buf = try self.allocator.realloc(self.buf, self.len + 1);
                    }
                    var i = index;
                    while (i < self.len) : (i += 1) {
                        self.buf[i + 1] = self.buf[i];
                    }
                    self.buf[index] = char;
                    self.len += 1;
                    return;
                } else if (index == self.len) {
                    return self.pushChar(char);
                }
                return StringError.IndexOutOfBounds;
            },
        };
    }

    pub fn insertSlice(self: *Self, str: []const u8, index: usize) !void {
        return switch (index) {
            0 => self.prependSlice(str),
            else => {
                if (index < self.len) {
                    if (self.len + str.len > self.buf.len) {
                        self.buf = try self.allocator.realloc(self.buf, self.len + str.len);
                    }
                    var i = index;
                    while (i < self.len) : (i += 1) {
                        self.buf[i + str.len] = self.buf[i];
                    }
                    std.mem.copyForwards(u8, self.buf[index..(index + str.len)], str);
                    self.len += str.len;
                    return;
                } else if (index == self.len) {
                    return self.pushSlice(str);
                }
                return StringError.IndexOutOfBounds;
            },
        };
    }

    pub fn addCapacity(self: *Self, amt_to_add: usize) !void {
        self.buf = try self.allocator.realloc(self.buf, self.buf.len + amt_to_add);
    }

    pub fn eq(self: *const Self, other: *const String) bool {
        if (self.len != other.len) {
            return false;
        }

        var i: usize = 0;
        while (i < self.len) : (i += 1) {
            if (self.buf[i] != other.buf[i]) {
                return false;
            }
        }
        return true;
    }
};

test "cloning" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const s = try String.initFromSlice(allocator, "hello");
    defer s.deinit();

    const s2 = try s.clone();
    defer s2.deinit();

    assert(s.eq(&s2));
}

test "general testing" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var s = try String.initFromSlice(allocator, "hello, ");
    defer s.deinit();
    std.debug.print("{s}\n", .{s.slice()});

    try s.pushSlice("world!");
    std.debug.print("{s}\n", .{s.slice()});

    var s2 = try s.clone();
    defer s2.deinit();
    std.debug.print("{s}\n", .{s2.slice()});

    s2.empty();
    std.debug.print("{s}\n", .{s2.slice()});

    var s3 = try s.clone();
    defer s3.deinit();
    s3.reverse();
    std.debug.print("{s}\n", .{s3.slice()});
    try s3.pushChar('e');
    std.debug.print("{s}\n", .{s3.slice()});

    var s4 = try String.initFromSlice(allocator, ">><<");
    defer s4.deinit();
    var s5 = try s4.clone();
    defer s5.deinit();

    std.debug.print("{s}\n", .{s4.slice()});
    try s4.insertChar('o', 2);
    std.debug.print("{s}\n", .{s4.slice()});

    try s5.insertSlice("(awesome stuff)", 2);
    std.debug.print("{s}\n", .{s5.slice()});
}
