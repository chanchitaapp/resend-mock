const std = @import("std");
const httpz = @import("httpz");

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

    try server.listen();
}

fn sendEmail(_: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
    try res.json(.{ .id = "5", .name = "Teg" }, .{});
}

// const json_content = "{\"from\":\"test@example.com\",\"to\":[\"test@example.com\"],\"subject\":\"Test email\", \"cc\": 20}";

// const allocator = std.heap.page_allocator;

// const parse_options = std.json.ParseOptions{
//     .ignore_unknown_fields = true,
// };

// const parsed = std.json.parseFromSlice(resend_types.SendEmailRequest, allocator, json_content, parse_options) catch |err| {
//     std.debug.print("Error: {any}\n", .{err});
//     return;
// };

// defer parsed.deinit();

// const request = parsed.value;

// std.debug.print("From: {s}, To: {s}, Subject: {s}, More... {any}\n", .{ request.from, request.to, request.subject, request.cc });
