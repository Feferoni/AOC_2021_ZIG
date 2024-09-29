const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "AOC_2021_ZIG",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
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

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    test_step.dependOn(&run_exe_unit_tests.step);
}
