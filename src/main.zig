const std = @import("std");
const parser = @import("parser.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const leaked = gpa.deinit();
        if (leaked) {
            std.debug.print("Leaked: {}", .{leaked});
        }
    }

    const path = "sample.rbn";
    const file_text = try std.fs.cwd().readFileAlloc(allocator, path, 10000 * 1024); // 10MB
    defer allocator.free(file_text);

    var tokens = try parser.parse(allocator, file_text);
    defer allocator.free(tokens);
    for (tokens) |t| {
        std.debug.print("{any}: {c}\n", .{ t.kind, file_text[t.start .. t.end + 1] });
    }
}
