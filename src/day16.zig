const std = @import("std");
const util = @import("util.zig");

const DecodedPacket = struct {
    packet: *Packet,
    position_increment: usize,
};

const Packet = struct {
    version_number: u64,
    type_id: u64,
    number: ?u64 = null,
    sub_packages: std.ArrayList(*Packet),
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator, version_number: u64, type_id: u64, number: ?u64) Packet {
        return Packet{
            .version_number = version_number,
            .type_id = type_id,
            .number = number,
            .sub_packages = std.ArrayList(*Packet).init(allocator),
            .allocator = allocator,
        };
    }

    fn deinit(self: *Packet) void {
        for (self.sub_packages.items) |sub_package| {
            sub_package.deinit();
        }
        self.allocator.destroy(self);
    }

    fn print(self: *const Packet, indent: *std.ArrayList(u8)) void {
        if (self.type_id == 4) {
            std.debug.print("{s}Version: {} TypeId: {} Number: {} \n", .{ indent.items, self.version_number, self.type_id, self.number.? });
        } else {
            std.debug.print("{s}Version: {} TypeId: {} Sub_packets: \n", .{ indent.items, self.version_number, self.type_id });
        }
        for (self.sub_packages.items) |packet| {
            const new_indent = "    ";
            indent.appendSlice(new_indent) catch unreachable;
            packet.print(indent);
            indent.shrinkAndFree(indent.items.len - 4);
        }
    }

    fn getSumOfVersionNumbers(self: *const Packet) u64 {
        var sum_of_version_number: u64 = self.version_number;
        for (self.sub_packages.items) |sub_package| {
            sum_of_version_number += sub_package.getSumOfVersionNumbers();
        }
        return sum_of_version_number;
    }

    fn sumPackets(self: *const Packet) u64 {
        if (self.number) |number| return number;
        var result: u64 = 0;
        for (self.sub_packages.items) |sub_package| {
            result += sub_package.getValue();
        }
        return result;
    }

    fn multiplyPackets(self: *const Packet) u64 {
        if (self.number) |number| return number;

        var result: u64 = 1;
        for (self.sub_packages.items) |sub_package| {
            result *= sub_package.getValue();
        }
        return result;
    }

    fn getAllValues(self: *const Packet, values: *std.ArrayList(u64)) void {
        if (self.number) |number| {
            values.append(number) catch unreachable;
            return;
        }

        for (self.sub_packages.items) |sub_package| {
            sub_package.getAllValues(values);
        }
    }

    fn lessThan(self: *const Packet) u64 {
        std.debug.assert(self.sub_packages.items.len == 2);

        const sub_packet_1_value = self.sub_packages.items[0].getValue();
        const sub_packet_2_value = self.sub_packages.items[1].getValue();

        return if (sub_packet_1_value < sub_packet_2_value) 1 else 0;
    }

    fn greaterThan(self: *const Packet) u64 {
        std.debug.assert(self.sub_packages.items.len == 2);

        const sub_packet_1_value = self.sub_packages.items[0].getValue();
        const sub_packet_2_value = self.sub_packages.items[1].getValue();

        return if (sub_packet_1_value > sub_packet_2_value) 1 else 0;
    }

    fn equalTo(self: *const Packet) u64 {
        std.debug.assert(self.sub_packages.items.len == 2);

        const sub_packet_1_value = self.sub_packages.items[0].getValue();
        const sub_packet_2_value = self.sub_packages.items[1].getValue();

        return if (sub_packet_1_value == sub_packet_2_value) 1 else 0;
    }

    fn getValue(self: *const Packet) u64 {
        switch (self.type_id) {
            0 => return self.sumPackets(),
            1 => return self.multiplyPackets(),
            2 => {
                var values = std.ArrayList(u64).init(self.allocator);
                defer values.deinit();
                self.getAllValues(&values);
                std.sort.block(u64, values.items, {}, std.sort.asc(u64));
                return values.items[0];
            },
            3 => {
                var values = std.ArrayList(u64).init(self.allocator);
                defer values.deinit();
                self.getAllValues(&values);
                std.sort.block(u64, values.items, {}, std.sort.desc(u64));
                return values.items[0];
            },
            4 => return self.number.?,
            5 => return self.greaterThan(),
            6 => return self.lessThan(),
            7 => return self.equalTo(),
            else => unreachable,
        }
    }
};

fn asciiToHex(c: u8) [4]u1 {
    const hex_value: u4 = switch (c) {
        '0'...'9' => @as(u4, @intCast(c - '0')),
        'A'...'F' => @as(u4, @intCast(c - 'A' + 10)),
        'a'...'f' => @as(u4, @intCast(c - 'a' + 10)),
        else => unreachable,
    };

    return .{
        @intCast((hex_value >> 3) & 1),
        @intCast((hex_value >> 2) & 1),
        @intCast((hex_value >> 1) & 1),
        @intCast(hex_value & 1),
    };
}

fn getBinaryArray(allocator: std.mem.Allocator, line: []const u8) []u1 {
    var result = std.ArrayList(u1).init(allocator);
    for (line) |char| {
        result.appendSlice(&asciiToHex(char)) catch unreachable;
    }
    return result.toOwnedSlice() catch unreachable;
}

fn decodeBits(bits: []const u1) u64 {
    var result: u64 = 0;

    for (bits) |bit| {
        result = (result << 1) | bit;
    }

    return result;
}

fn decodeTypeIdFour(allocator: std.mem.Allocator, version_number: u64, type_id: u64, bits: []const u1) DecodedPacket {
    var number_bits = std.ArrayList(u1).init(allocator);
    defer number_bits.deinit();

    var bit_counter: usize = 0;

    var found_last_group: bool = false;
    for (bits, 0..) |bit, n| {
        if (n % 5 == 0) {
            if (found_last_group) {
                break;
            } else {
                bit_counter += 1;
                if (bit == 0b0) found_last_group = true;
                continue;
            }
        }

        bit_counter += 1;
        number_bits.append(bit) catch unreachable;
    }

    const number: u64 = decodeBits(number_bits.items);

    const packet = allocator.create(Packet) catch unreachable;
    packet.* = Packet.init(allocator, version_number, type_id, number);

    return DecodedPacket{ .packet = packet, .position_increment = bit_counter };
}

fn decodePacketOther(allocator: std.mem.Allocator, version_number: u64, type_id: u64, bits: []const u1) DecodedPacket {
    const lengt_type_id = @as(u1, @intCast(decodeBits(bits[0..1])));

    const packet = allocator.create(Packet) catch unreachable;
    packet.* = Packet.init(allocator, version_number, type_id, null);
    var position: usize = 1;
    switch (lengt_type_id) {
        0 => {
            const length_of_sub_packages = decodeBits(bits[1..16]);
            position = 16;
            while (position < length_of_sub_packages + 16) {
                const sub_package = decodePacket(allocator, bits[position..]);
                packet.sub_packages.append(sub_package.packet) catch unreachable;
                position += sub_package.position_increment;
            }
        },
        1 => {
            const nr_of_sub_packages = decodeBits(bits[1..12]);
            position = 12;
            for (0..nr_of_sub_packages) |_| {
                const sub_package = decodePacket(allocator, bits[position..]);
                packet.sub_packages.append(sub_package.packet) catch unreachable;
                position += sub_package.position_increment;
            }
        },
    }

    return DecodedPacket{ .packet = packet, .position_increment = position };
}

fn decodePacket(allocator: std.mem.Allocator, bits: []const u1) DecodedPacket {
    var indent = std.ArrayList(u8).init(allocator);
    indent.deinit();

    const version_number = decodeBits(bits[0..3]);
    const type_id = decodeBits(bits[3..6]);

    return switch (type_id) {
        4 => return {
            var packet = decodeTypeIdFour(allocator, version_number, type_id, bits[6..]);
            packet.position_increment += 6;
            return packet;
        },
        else => {
            var packet = decodePacketOther(allocator, version_number, type_id, bits[6..]);
            packet.position_increment += 6;
            return packet;
        },
    };
}

pub fn part1(allocator: std.mem.Allocator) void {
    const lines = util.getLinesFromFile("day16.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }

    const binary_array = getBinaryArray(allocator, lines.items[0]);
    defer allocator.free(binary_array);

    const packet = decodePacket(allocator, binary_array);
    defer packet.packet.deinit();

    std.debug.print("Part1 result: {}\n", .{packet.packet.getSumOfVersionNumbers()});
}

pub fn part2(allocator: std.mem.Allocator) void {
    const lines = util.getLinesFromFile("day16.txt", allocator);
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit();
    }
    const binary_array = getBinaryArray(allocator, lines.items[0]);
    defer allocator.free(binary_array);

    const packet = decodePacket(allocator, binary_array);
    defer packet.packet.deinit();

    std.debug.print("Part2 result: {}\n", .{packet.packet.getValue()});
}

fn convertStringToBinaryArray(allocator: std.mem.Allocator, str: []const u8) []u1 {
    var arr = std.ArrayList(u1).init(allocator);
    for (str) |c| {
        std.debug.assert(c == '1' or c == '0');
        arr.append(@as(u1, @intCast(c - '0'))) catch unreachable;
    }
    return arr.toOwnedSlice() catch unreachable;
}

test "AsciToHexEncodedU4Array" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const binary_array1 = getBinaryArray(allocator, "D2FE28");
    const expected_binary1 = convertStringToBinaryArray(allocator, "110100101111111000101000");
    try std.testing.expectEqualSlices(u1, expected_binary1, binary_array1);

    const binary_array2 = getBinaryArray(allocator, "38006F45291200");
    const expected_binary2 = convertStringToBinaryArray(allocator, "00111000000000000110111101000101001010010001001000000000");
    try std.testing.expectEqualSlices(u1, expected_binary2, binary_array2);

    const binary_array3 = getBinaryArray(allocator, "EE00D40C823060");
    const expected_binary3 = convertStringToBinaryArray(allocator, "11101110000000001101010000001100100000100011000001100000");
    try std.testing.expectEqualSlices(u1, expected_binary3, binary_array3);
}

fn test_bits_decoding(allocator: std.mem.Allocator, str: []const u8, expected_value: u64) !void {
    const binary_arr = convertStringToBinaryArray(allocator, str);
    const value = decodeBits(binary_arr);
    try std.testing.expectEqual(expected_value, value);
}
