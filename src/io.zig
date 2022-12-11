pub fn readLine(reader: anytype, buffer: []u8) ?[]const u8 {
    return reader.readUntilDelimiterOrEof(buffer, '\n') catch blk: {
        reader.skipUntilDelimiterOrEof('\n') catch {};
        break :blk undefined;
    };
}
