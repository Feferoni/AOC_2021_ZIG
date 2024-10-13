const std = @import("std");
const util = @import("util.zig");

fn getInsertionRules(allocator: std.mem.Allocator, lines: [][]const u8) std.AutoHashMap([2]u8, u8) {
    var insertion_rules = std.AutoHashMap([2]u8, u8).init(allocator);

    for (lines) |line| {
        var it = std.mem.splitAny(u8, line, " ");

        const pair_elements = it.next() orelse unreachable;
        _ = it.next() orelse unreachable;
        const insert_element = it.next() orelse unreachable;

        std.debug.assert(pair_elements.len == 2);
        std.debug.assert(insert_element.len == 1);

        insertion_rules.put(.{ pair_elements[0], pair_elements[1] }, insert_element[0]) catch unreachable;
    }

    return insertion_rules;
}

fn getPolymerPairs(allocator: std.mem.Allocator, line: []const u8) std.AutoHashMap([2]u8, u64) {
    var polymer_pairs = std.AutoHashMap([2]u8, u64).init(allocator);

    for (1..line.len) |i| {
        const first_element = line[i - 1];
        const second_element = line[i];
        const entry = polymer_pairs.getOrPut([_]u8{ first_element, second_element }) catch unreachable;
        if (!entry.found_existing) entry.value_ptr.* = 0;
        entry.value_ptr.* += 1;
    }

    return polymer_pairs;
}

const PolymerData = struct {
    element_count: std.AutoHashMap(u8, u64),
    polymer_pairs: std.AutoHashMap([2]u8, u64),
    insertion_rules: std.AutoHashMap([2]u8, u8),
    allocator: std.mem.Allocator,

    const Self = @This();

    const InsertionRule = struct {
        pair_elements: [2]u8,
        insert_element: u8,

        fn getInsertElements(self: *const InsertionRule, pair_elements: []u8) ?u8 {
            std.debug.assert(pair_elements.len == 2);
            if (std.mem.eql(u8, pair_elements, &self.pair_elements)) return self.insert_element;
            return null;
        }
    };

    fn init(allocator: std.mem.Allocator, lines: [][]const u8) PolymerData {
        var element_count = std.AutoHashMap(u8, u64).init(allocator);

        for (lines[0]) |char| {
            const entry = element_count.getOrPut(char) catch unreachable;
            if (!entry.found_existing) entry.value_ptr.* = 0;
            entry.value_ptr.* += 1;
        }

        return PolymerData{
            .element_count = element_count,
            .polymer_pairs = getPolymerPairs(allocator, lines[0]),
            .insertion_rules = getInsertionRules(allocator, lines[2..]),
            .allocator = allocator,
        };
    }

    fn deinit(self: *Self) void {
        self.polymer_pairs.deinit();
        self.insertion_rules.deinit();
    }

    fn print(self: *const Self) void {
        std.debug.print("Polymer_pairs:\n", .{});
        var it = self.polymer_pairs.iterator();
        while (it.next()) |polymer_pair| {
            std.debug.print("Pair: {s} count: {}\n", .{ polymer_pair.key_ptr.*, polymer_pair.value_ptr.* });
        }

        // var it2 = self.insertion_rules.iterator();
        // std.debug.print("Insertion rules: \n", .{});
        // while (it2.next()) |rule| {
        //     std.debug.print("Pair_elements: {s} - insert_element: {c}\n", .{ rule.key_ptr.*, rule.value_ptr.* });
        // }

        std.debug.print("Element_count:\n", .{});
        var it3 = self.element_count.iterator();
        while (it3.next()) |element| {
            std.debug.print("Element: {c} - count: {}\n", .{ element.key_ptr.*, element.value_ptr.* });
        }
    }

    fn getElementValue(self: *const Self) u64 {
        var lowest: ?u64 = null;
        var highest: ?u64 = null;

        var it2 = self.element_count.iterator();
        while (it2.next()) |entry| {
            if (lowest == null) lowest = entry.value_ptr.*;
            if (highest == null) highest = entry.value_ptr.*;

            if (entry.value_ptr.* > highest.?) highest = entry.value_ptr.*;
            if (entry.value_ptr.* < lowest.?) lowest = entry.value_ptr.*;
        }

        return highest.? - lowest.?;
    }

    fn applyPolymerTemplateInsertion(self: *Self, nr_of_rounds: u32) void {
        for (0..nr_of_rounds) |_| {
            var tmp_polymer_pairs = std.AutoHashMap([2]u8, u64).init(self.allocator);
            defer tmp_polymer_pairs.deinit();

            var it = self.polymer_pairs.iterator();
            while (it.next()) |polymer_pair| {
                if (polymer_pair.value_ptr.* == 0) continue;

                if (self.insertion_rules.get(polymer_pair.key_ptr.*)) |element| {
                    const count_entry = self.element_count.getOrPut(element) catch unreachable;
                    if (!count_entry.found_existing) count_entry.value_ptr.* = 0;
                    count_entry.value_ptr.* += polymer_pair.value_ptr.*;

                    const first_new = [_]u8{ polymer_pair.key_ptr[0], element };
                    const entry1 = tmp_polymer_pairs.getOrPut(first_new) catch unreachable;
                    if (!entry1.found_existing) entry1.value_ptr.* = 0;
                    entry1.value_ptr.* += polymer_pair.value_ptr.*;
                    // std.debug.print("Inserted: {s} with curr value: {}\n", .{ entry1.key_ptr.*, entry1.value_ptr.* });

                    const second_new = [_]u8{ element, polymer_pair.key_ptr[1] };
                    const entry2 = tmp_polymer_pairs.getOrPut(second_new) catch unreachable;
                    if (!entry2.found_existing) entry2.value_ptr.* = 0;
                    entry2.value_ptr.* += polymer_pair.value_ptr.*;
                    // std.debug.print("Inserted: {s} with curr value: {}\n", .{ entry2.key_ptr.*, entry2.value_ptr.* });

                    polymer_pair.value_ptr.* = 0;
                }
            }

            var it2 = tmp_polymer_pairs.iterator();
            while (it2.next()) |polymer_pair| {
                const entry = self.polymer_pairs.getOrPut(polymer_pair.key_ptr.*) catch unreachable;
                entry.value_ptr.* = polymer_pair.value_ptr.*;
            }

            // std.debug.print("******** round: {} ************\n", .{n});
            // self.print();
        }
    }
};

pub fn part1(allocator: std.mem.Allocator) void {
    const lines = util.getLinesFromFile("day14.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    var polymer_data = PolymerData.init(allocator, lines.items);
    defer polymer_data.deinit();

    polymer_data.applyPolymerTemplateInsertion(10);

    std.debug.print("Part1 solution: {}\n", .{polymer_data.getElementValue()});
}

pub fn part2(allocator: std.mem.Allocator) void {
    const lines = util.getLinesFromFile("day14.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    var polymer_data = PolymerData.init(allocator, lines.items);
    defer polymer_data.deinit();

    polymer_data.applyPolymerTemplateInsertion(40);

    std.debug.print("Part2 solution: {}\n", .{polymer_data.getElementValue()});
}
