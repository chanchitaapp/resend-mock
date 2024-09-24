const std = @import("std");

pub const Attachment = struct {
    content: []const u8,
    filename: []const u8,
    path: []const u8,
    content_type: ?[]const u8,

    // Create a deep copy.
    pub fn deepCopy(self: Attachment, allocator: std.mem.Allocator) !Attachment {
        return Attachment{
            .content = try allocator.dupe(u8, self.content),
            .filename = try allocator.dupe(u8, self.filename),
            .path = try allocator.dupe(u8, self.path),
            .content_type = if (self.content_type) |content_type|
                try allocator.dupe(u8, content_type)
            else
                null,
        };
    }

    // Free memory allocated.
    pub fn deinit(self: Attachment, allocator: std.mem.Allocator) void {
        allocator.free(self.content);
        allocator.free(self.filename);
        allocator.free(self.path);
        if (self.content_type) |content_type| {
            allocator.free(content_type);
        }
    }
};

pub const SendEmailRequest = struct {
    from: []const u8,
    to: []const []const u8,
    subject: []const u8,
    bcc: ?[]const u8 = null,
    cc: ?[]const u8 = null,
    reply_to: ?[]const u8 = null,
    html: ?[]const u8 = null,
    text: ?[]const u8 = null,
    tags: ?[]const u8 = null,
    attachments: ?[]Attachment = null,
    headers: ?[]const u8 = null,
    scheduled_at: ?[]const u8 = null,

    // Create a deep copy.
    pub fn deepCopy(self: SendEmailRequest, allocator: std.mem.Allocator) !SendEmailRequest {
        // Copying arrays like `to`
        var copiedTo = try allocator.alloc([]const u8, self.to.len);
        for (self.to, 0..) |email, i| {
            copiedTo[i] = try allocator.dupe(u8, email);
        }

        var copiedAttachments: ?[]Attachment = null;
        if (self.attachments) |attachments| {
            copiedAttachments = try allocator.alloc(Attachment, attachments.len);
            for (attachments, 0..) |attachment, i| {
                copiedAttachments.?[i] = try attachment.deepCopy(allocator);
            }
        }

        return SendEmailRequest{
            .from = try allocator.dupe(u8, self.from),
            .to = copiedTo,
            .subject = try allocator.dupe(u8, self.subject),
            .bcc = if (self.bcc) |bcc| try allocator.dupe(u8, bcc) else null,
            .cc = if (self.cc) |cc| try allocator.dupe(u8, cc) else null,
            .reply_to = if (self.reply_to) |reply_to| try allocator.dupe(u8, reply_to) else null,
            .html = if (self.html) |html| try allocator.dupe(u8, html) else null,
            .text = if (self.text) |text| try allocator.dupe(u8, text) else null,
            .tags = if (self.tags) |tags| try allocator.dupe(u8, tags) else null,
            .attachments = copiedAttachments,
            .headers = if (self.headers) |headers| try allocator.dupe(u8, headers) else null,
            .scheduled_at = if (self.scheduled_at) |scheduled_at| try allocator.dupe(u8, scheduled_at) else null,
        };
    }

    // Free memory allocated.
    pub fn deinit(self: SendEmailRequest, allocator: std.mem.Allocator) void {
        allocator.free(self.from);
        for (self.to) |email| {
            allocator.free(email);
        }
        allocator.free(self.to);
        allocator.free(self.subject);

        if (self.bcc) |bcc| allocator.free(bcc);
        if (self.cc) |cc| allocator.free(cc);
        if (self.reply_to) |reply_to| allocator.free(reply_to);
        if (self.html) |html| allocator.free(html);
        if (self.text) |text| allocator.free(text);
        if (self.tags) |tags| allocator.free(tags);

        if (self.attachments) |attachments| {
            for (attachments) |attachment| {
                attachment.deinit(allocator);
            }
            allocator.free(attachments);
        }

        if (self.headers) |headers| allocator.free(headers);
        if (self.scheduled_at) |scheduled_at| allocator.free(scheduled_at);
    }
};

pub const Email = struct {
    object: []const u8,
    id: []const u8,
    to: []const []const u8,
    from: []const u8,
    created_at: []const u8,
    subject: ?[]const u8 = null,
    html: ?[]const u8 = null,
    text: ?[]const u8 = null,
    bcc: ?[]const u8 = null,
    cc: ?[]const u8 = null,
    reply_to: EmailReplyTo,
    last_event: ?[]const u8 = null,
};

const EmailReplyTo = union(enum) {
    single: ?[]const u8,
    multiple: ?[]const []const u8,
};
