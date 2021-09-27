const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpa.deinit());
    const allocator = &gpa.allocator;

    const output = std.io.getStdOut().writer();

    var args = std.process.args();
    std.debug.assert(args.skip());
    const subcmd = try args.next(allocator) orelse {
        try output.writeAll("Lacking arguments!\n");
        return;
    };
    defer allocator.free(subcmd);

    if (std.mem.eql(u8, subcmd, "encrypt")) {
        try output.writeAll("Beginning encryption..\n");
        try encrypt(allocator);
        try output.writeAll("Finished encryption\n");
    } else if (std.mem.eql(u8, subcmd, "decrypt")) {
        try output.writeAll("Beginning decryption..\n");
        decrypt(allocator);
        try output.writeAll("Finished decryption..\n");
    } else {
        try output.writeAll("Missing valid arguments, try encrypt/decrypt\n");
    }
}

fn encrypt(allocator: *std.mem.Allocator) !void {
    const photo = try std.fs.cwd().openFile("photo.jpg", .{});
    const message = try std.fs.cwd().openFile("message.txt", .{});
    defer photo.close();
    defer message.close();

    const raw_photo = try photo.reader().readAllAlloc(allocator, 1024*1024*16);
    const raw_message = try message.reader().readAllAlloc(allocator, 1000*1000*8);
    defer allocator.free(raw_photo);
    defer allocator.free(raw_message);
    
    const final_photo = try std.fs.cwd().createFile("imagezero.jpg", .{});
    defer final_photo.close();
    try final_photo.writer().writeAll(raw_photo);
    try final_photo.writer().writeAll(raw_message);
    try final_photo.writer().writeIntLittle(u32, @intCast(u32, raw_message.len));
}

fn decrypt(allocator: *std.mem.Allocator) !void {
    const hidden_message = try std.fs.cwd().openFile("imagezero.jpg", .{});
    defer hidden_message.close();

    const raw_data = try hidden_message.reader().readAllAlloc(allocator, 1000*1000*24);
    defer allocator.free(raw_data);

    const final_message = try std.fs.cwd().createFile("message.txt", .{});
    defer final_message.close();
}
