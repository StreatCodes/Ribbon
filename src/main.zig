const std = @import("std");
const parser = @import("parser.zig");
// const ast = @import("ast.zig");
const AST = @import("ast.zig").AST;

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

    var tokenIter = try parser.parse(allocator, file_text);
    defer tokenIter.deinit(allocator);
    while (tokenIter.next()) |t| {
        std.debug.print("{any}: {c}\n", .{ t.kind, file_text[t.start .. t.end + 1] });
    }
    tokenIter.reset();

    var ast = AST.init(allocator, file_text, &tokenIter);
    defer ast.deinit();

    // _ = ast.generateModule() catch |err| {
    //     std.debug.print("Error {any} - \"{s}\"", .{ err, tokenIter.current().value(file_text) });
    // };
    _ = try ast.generateModule();
}
