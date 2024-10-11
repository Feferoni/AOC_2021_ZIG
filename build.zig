const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "AOC_2021_ZIG",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const test_step = b.step("test", "Run unit tests");
    const src_dir = std.fs.cwd().openDir("src", .{ .iterate = true }) catch |err| {
        std.debug.print("Error opening src directory: {}\n", .{err});
        return;
    };

    var iter = src_dir.iterate();
    while (iter.next() catch |err| {
        std.debug.print("Error iterating directory: {}\n", .{err});
        return;
    }) |entry| {
        if (std.mem.startsWith(u8, entry.name, "day") and std.mem.endsWith(u8, entry.name, ".zig")) {
            const prefix_path = "src";
            var path_buffer: [std.fs.max_path_bytes]u8 = undefined;
            const full_path = std.fmt.bufPrint(&path_buffer, "{s}/{s}", .{ prefix_path, entry.name }) catch |err| {
                std.debug.print("Error concatinating src with file: {}\n", .{err});
                continue;
            };

            const test_artifact = b.addTest(.{
                .root_source_file = b.path(full_path),
                .target = target,
                .optimize = optimize,
            });
            const run_test = b.addRunArtifact(test_artifact);
            test_step.dependOn(&run_test.step);
        }
    }

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    test_step.dependOn(&run_exe_unit_tests.step);
}
