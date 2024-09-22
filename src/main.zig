const std = @import("std");

const ResendEmailRequest = struct {
    from: []const u8,
    to: [][]const u8,
    subject: []const u8,
};

// 	From        string            `json:"from"`
// 	To          []string          `json:"to"`
// 	Subject     string            `json:"subject"`
// 	Bcc         []string          `json:"bcc,omitempty"`
// 	Cc          []string          `json:"cc,omitempty"`
// 	ReplyTo     string            `json:"reply_to,omitempty"`
// 	Html        string            `json:"html,omitempty"`
// 	Text        string            `json:"text,omitempty"`
// 	Tags        []Tag             `json:"tags,omitempty"`
// 	Attachments []*Attachment     `json:"attachments,omitempty"`
// 	Headers     map[string]string `json:"headers,omitempty"`
// 	ScheduledAt string            `json:"scheduled_at,omitempty"`
// }

pub fn main() !void {
    const json_content = "{\"from\":\"test@example.com\",\"to\":[\"test@example.com\"],\"subject\":\"Test email\"}";

    const allocator = std.heap.page_allocator;

    const parsed = try std.json.parseFromSlice(ResendEmailRequest, allocator, json_content, .{});
    defer parsed.deinit();

    const request = parsed.value;

    std.debug.print("From: {s}, To: {s}, Subject: {s}\n", .{ request.from, request.to, request.subject });
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
