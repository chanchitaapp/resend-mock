const resend_types = @import("resend_types.zig");
const std = @import("std");
const httpz = @import("httpz");
const zlog = @import("zlog");
const uuid = @import("uuid");

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

    var router = server.router();
    router.post("/emails", sendEmail);

    const banner = @embedFile("banner.txt");

    _ = try std.io.getStdOut().write(banner);

    try server.listen();
}

const StoredSendEmailRequest = struct {
    id: []const u8,
    payload: resend_types.SendEmailRequest,
};

var sendEmailRequests = std.ArrayList(StoredSendEmailRequest).init(gpa.allocator());

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

    const allocator = gpa.allocator();

    var string = std.ArrayList(u8).init(allocator);
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

    try sendEmailRequests.append(.{
        .id = id_str,
        .payload = try payload.?.deepCopy(allocator),
    });

    res.status = 200;
    try res.json(.{ .id = id_str }, .{});
}
