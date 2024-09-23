pub const Attachment = struct {
    /// Content of an attached file.
    content: []const u8,
    /// Name of attached file.
    filename: []const u8,
    // Path where the attachment is hosted.
    path: []const u8,
    /// Optional content type for the attachment, if not set it will be derived from the filename property.
    content_type: ?[]const u8,
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
};
