const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const request_mod = b.createModule(.{
        .root_source_file = b.path("src/request.zig"),
        .target = target,
        .optimize = optimize,
    });

    const response_mod = b.createModule(.{
        .root_source_file = b.path("src/response.zig"),
        .target = target,
        .optimize = optimize,
    });

    const config_mod = b.addModule("socker_config", .{
        .root_source_file = b.path("src/config.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe_mod.addImport("socket_request", request_mod);

    const response_lib = b.addLibrary(.{
        .linkage = .static,
        .name = "http_server",
        .root_module = response_mod,
    });

    b.installArtifact(response_lib);

    exe_mod.addImport("socket_response", response_mod);

    const request_lib = b.addLibrary(.{
        .linkage = .static,
        .name = "http_server",
        .root_module = request_mod,
    });

    b.installArtifact(request_lib);

    exe_mod.addImport("socket_config", config_mod);

    const config_lib = b.addLibrary(.{
        .linkage = .static,
        .name = "http_server",
        .root_module = config_mod,
    });

    b.installArtifact(config_lib);

    const exe = b.addExecutable(.{
        .name = "http_server",
        .root_module = exe_mod,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
