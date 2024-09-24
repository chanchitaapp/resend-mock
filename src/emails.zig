const resend_types = @import("resend_types.zig");
const httpz = @import("httpz");
const zlog = @import("zlog");
const uuid = @import("uuid");
const std = @import("std");

const DateTime = @import("datetime").datetime.Datetime;
const log = &zlog.json_logger;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const allocator = gpa.allocator();

var storedEmails = std.ArrayList(*resend_types.Email).init(allocator);

pub fn registerEndpoints(router: *httpz.Router(void, void)) void {
    router.post("/emails", sendEmail);
    router.get("/emails/:email_id", getEmail);
    router.patch("/emails/:email_id", modifyEmail);
}

fn modifyEmail(_: *httpz.Request, _: *httpz.Response) !void {}

fn getEmail(req: *httpz.Request, res: *httpz.Response) !void {
    const email_id = req.param("email_id");
    if (email_id == null) {
        res.status = 400;
        try res.json(.{
            .message = "email is required",
        }, .{});

        return;
    }

    var event = try log.event(.debug);
    try event.msgf("getEmail: {s}", .{email_id.?});

    const stored_emails = storedEmails.items;

    for (stored_emails) |email| {
        if (std.mem.eql(u8, email.id, email_id.?)) {
            res.status = 200;
            try res.json(.{
                .email = email,
            }, .{});

            return;
        }
    }

    res.status = 404;
    try res.json(.{
        .message = "email not found",
    }, .{});
}

fn sendEmail(req: *httpz.Request, res: *httpz.Response) !void {
    const body = req.body() orelse "";
    if (body.len == 0) {
        var event = try log.event(.debug);
        try event.msg("request body is empty");
        res.status = 400;
        return;
    }

    const parsed = std.json.parseFromSlice(resend_types.SendEmailRequest, allocator, body, .{}) catch |err| {
        var event = try log.event(.debug);
        try event.msgf("error deserializing payload: {}", .{err});

        res.status = 400;
        return;
    };

    const payload = parsed.value;

    var event = try log.event(.debug);
    try event.str("payload", body);
    try event.send();

    const id = uuid.v4.new();
    const id_str = try std.fmt.allocPrint(allocator, "{s}", .{uuid.urn.serialize(id)});

    const now = DateTime.now();
    const created_at = try now.formatISO8601(allocator, true);

    const email = try allocator.create(resend_types.Email);
    email.* = .{
        .object = "email",
        .id = id_str,
        .to = payload.to,
        .from = payload.from,
        .created_at = created_at,
        .subject = payload.subject,
        .html = payload.html,
        .text = payload.text,
        .bcc = payload.bcc,
        .cc = payload.cc,
        .reply_to = .{ .single = payload.reply_to },
    };

    try storedEmails.append(email);

    res.status = 200;
    try res.json(.{ .id = id_str }, .{});
}
