const resend_types = @import("resend_types.zig");
const std = @import("std");
const httpz = @import("httpz");
const zlog = @import("zlog");
const uuid = @import("uuid");

const registerEndpoints = @import("emails.zig").registerEndpoints;
const log = &zlog.json_logger;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

pub fn main() !void {
    const allocator = gpa.allocator();
    defer {
        if (gpa.deinit() == .leak) {
            std.log.err("Error deinitializing the allocator", .{});
        }
    }

    var server = try httpz.Server().init(allocator, .{ .port = 8900 });
    defer {
        server.stop();
        server.deinit();
    }

    const router = server.router();
    registerEndpoints(router);

    const banner = @embedFile("banner.txt");

    _ = try std.io.getStdOut().write(banner);

    try server.listen();
}
