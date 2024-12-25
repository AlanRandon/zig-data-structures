const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "zig-data-structures",
        .root_source_file = .{ .cwd_relative = "src/lib.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(lib);

    {
        const bench_exe = b.addExecutable(.{
            .name = "bench",
            .root_source_file = .{ .cwd_relative = "src/bench.zig" },
            .target = target,
            .optimize = .ReleaseFast,
        });
        b.installArtifact(bench_exe);

        const run_cmd = b.addRunArtifact(bench_exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        const run_step = b.step("bench", "Run benchmarks");
        run_step.dependOn(&run_cmd.step);
    }

    {
        const huffman_exe = b.addExecutable(.{
            .name = "huffman",
            .root_source_file = .{ .cwd_relative = "src/huffman.zig" },
            .target = target,
            .optimize = optimize,
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

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .cwd_relative = "src/lib.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
