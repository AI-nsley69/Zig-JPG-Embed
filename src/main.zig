const std = @import("std");

pub fn main() !void {
    // Setup allocators
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpa.deinit());
    const allocator = &gpa.allocator;

    const output = std.io.getStdOut().writer();
    // Process arguments
    var args = std.process.args();
    std.debug.assert(args.skip());
    const subcmd = try args.next(allocator) orelse {
        try output.writeAll("Lacking arguments!\n");
        return;
    };
    defer allocator.free(subcmd);

    const passwd = try args.next(allocator) orelse {
        try output.writeAll("Provide a password");
        return;
    };
    defer allocator.free(passwd);
    // Verify that we have the correct one and run function
    if (std.mem.eql(u8, subcmd, "encrypt")) {
        try output.writeAll("Beginning encryption..\n");
        try encrypt(allocator, passwd);
        try output.writeAll("Finished encryption\n");
    } else if (std.mem.eql(u8, subcmd, "decrypt")) {
        try output.writeAll("Beginning decryption..\n");
        try decrypt(allocator, passwd);
        try output.writeAll("Finished decryption..\n");
    } else {
        try output.writeAll("Missing valid arguments, try encrypt/decrypt\n");
    }
}

fn encrypt(allocator: *std.mem.Allocator, passwd: []const u8) !void {
    const Kdf = std.crypto.kdf.hkdf.HkdfSha512;
    const Cipher = std.crypto.aead.chacha_poly.ChaCha20Poly1305;
    // Open the photo and message file
    const photo = try std.fs.cwd().openFile("photo.jpg", .{});
    const message = try std.fs.cwd().openFile("message.txt", .{});
    defer photo.close();
    defer message.close();
    // Get the raw data for both
    const raw_photo = try photo.reader().readAllAlloc(allocator, 1024 * 1024 * 16);
    const raw_message = try message.reader().readAllAlloc(allocator, 1000 * 1000 * 8);
    defer allocator.free(raw_photo);
    defer allocator.free(raw_message);

    var encrypted_msg = try allocator.alloc(u8, raw_message.len);
    defer allocator.free(encrypted_msg);

    var nonce: [Cipher.nonce_length]u8 = undefined;
    std.crypto.random.bytes(&nonce);
    var tag: [Cipher.tag_length]u8 = undefined;
    var key: [Cipher.key_length]u8 = undefined;
    const master_key = Kdf.extract("league of legends", passwd);
    Kdf.expand(&key, "!domme key", master_key);
    Cipher.encrypt(encrypted_msg, &tag, raw_message, &.{}, nonce, key);
    // Write the message to file
    const final_photo = try std.fs.cwd().createFile("imagezero.jpg", .{});
    defer final_photo.close();
    try final_photo.writer().writeAll(raw_photo);
    try final_photo.writer().writeAll(&tag);
    try final_photo.writer().writeAll(&nonce);
    try final_photo.writer().writeAll(encrypted_msg);
    try final_photo.writer().writeIntLittle(u32, @intCast(u32, encrypted_msg.len));
}

fn decrypt(allocator: *std.mem.Allocator, passwd: []const u8) !void {
    const Kdf = std.crypto.kdf.hkdf.HkdfSha512;
    const Cipher = std.crypto.aead.chacha_poly.ChaCha20Poly1305;

    const hidden_message = try std.fs.cwd().openFile("imagezero.jpg", .{});
    defer hidden_message.close();

    try hidden_message.seekFromEnd(-4);
    const string_len = try hidden_message.reader().readIntLittle(u32);

    try hidden_message.seekFromEnd(-4 - @intCast(i32, string_len) - Cipher.nonce_length - Cipher.tag_length);
    // Get the tag, nonce and key
    var tag: [Cipher.tag_length]u8 = undefined;
    try hidden_message.reader().readNoEof(&tag);
    var nonce: [Cipher.nonce_length]u8 = undefined;
    try hidden_message.reader().readNoEof(&nonce);
    var key: [Cipher.key_length]u8 = undefined;
    const master_key = Kdf.extract("league of legends", passwd);
    Kdf.expand(&key, "!domme key", master_key);
    // Create a buffer for decrypted message and the (encrypted) msg content
    var decrypted_msg = try allocator.alloc(u8, string_len);
    defer allocator.free(decrypted_msg);
    const message_content = try allocator.alloc(u8, string_len);
    defer allocator.free(message_content);
    try hidden_message.reader().readNoEof(message_content);
    try Cipher.decrypt(decrypted_msg, message_content, tag, &.{}, nonce, key);

    try std.fs.cwd().writeFile("message.txt", decrypted_msg);
}
