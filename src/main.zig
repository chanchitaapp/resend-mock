const std = @import("std");
const httpz = @import("httpz");
const zlog = @import("zlog");
const uuid = @import("uuid");

const log = &zlog.json_logger;

const resend_types = @import("resend_types.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var server = try httpz.Server().init(allocator, .{ .port = 8900 });
    defer {
        server.stop();
        server.deinit();
    }

    var router = server.router();
    router.post("/emails", sendEmail);

    const banner = @embedFile("banner.txt");

    _ = try std.io.getStdOut().write(banner);

    try server.listen();
}

fn sendEmail(req: *httpz.Request, res: *httpz.Response) !void {
    const payload = req.json(resend_types.SendEmailRequest) catch |err| {
        var event = try log.event(.debug);
        try event.msgf("error deserializing payload: {}", .{err});

        res.status = 400;
        return;
    };

    if (payload == null) {
        var event = try log.event(.debug);
        try event.msg("payload is empty");
        res.status = 400;
        return;
    }

    const allocator = std.heap.page_allocator;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    var string = std.ArrayList(u8).init(gpa.allocator());
    defer string.deinit();

    std.json.stringify(payload.?, .{}, string.writer()) catch |err| {
        var event = try log.event(.err);
        try event.msgf("error printing payload: {}", .{err});
    };

    var event = try log.event(.debug);
    try event.str("payload", string.items);
    try event.send();

    const id = uuid.v4.new();
    const id_str = try std.fmt.allocPrint(allocator, "{s}", .{uuid.urn.serialize(id)});
    defer allocator.free(id_str);

    res.status = 200;
    try res.json(.{ .id = id_str }, .{});
}
