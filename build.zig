const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("dsa", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addStaticLibrary(.{
        .name = "dsa",
        .root_module = mod,
    });

    b.installArtifact(lib);

    const unit_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);

    var bench_dir = try std.fs.cwd().openDir(b.path("src/bench").getPath(b), .{ .iterate = true });
    defer bench_dir.close();

    var bench_dir_it = bench_dir.iterate();
    while (try bench_dir_it.next()) |entry| {
        const extension = std.fs.path.extension(entry.name);
        if (!std.mem.eql(u8, extension, ".zig")) {
            continue;
        }

        const name = std.fs.path.stem(entry.name);
        const bench_name = try std.fmt.allocPrint(b.allocator, "bench-{s}", .{name});
        const bench_mod = b.addModule(bench_name, .{
            .root_source_file = b.path(try std.fs.path.join(b.allocator, &.{ "src", "bench", entry.name })),
            .target = target,
            .optimize = .ReleaseFast,
        });

        bench_mod.addImport("dsa", mod);

        const bench_exe = b.addExecutable(.{
            .name = bench_name,
            .root_module = bench_mod,
        });
        bench_exe.linkLibC();

        b.installArtifact(bench_exe);
    }

    {
        const huffman_mod = b.addModule("huffman", .{
            .root_source_file = b.path("src/huffman.zig"),
            .target = target,
            .optimize = optimize,
        });

        const huffman_exe = b.addExecutable(.{
            .name = "huffman",
            .root_module = huffman_mod,
        });

        b.installArtifact(huffman_exe);

        const run_cmd = b.addRunArtifact(huffman_exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run-huffman", "Run the huffman executable");
        run_step.dependOn(&run_cmd.step);
    }
}
