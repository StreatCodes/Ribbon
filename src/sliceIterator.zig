pub fn Iterator(comptime T: type) type {
    return struct {
        const Self = @This();
        data: []T,
        pos: usize = 0,

        pub fn next(self: *Self) ?T {
            const nextPos = self.pos + 1;
            if (nextPos < self.data.len) {
                self.pos = nextPos;
                return self.data[nextPos];
            }
            return null;
        }

        pub fn peek(self: *Self) ?T {
            const nextPos = self.pos + 1;
            if (nextPos < self.data.len) {
                return self.data[nextPos];
            }
            return null;
        }

        // pub fn consume(self: *Self) ?T {
        //     const nextPos = self.pos + 1;
        //     if (nextPos < self.data.len) {
        //         return self.data[nextPos];
        //     }
        //     return null;
        // }
    };
}
