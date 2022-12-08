// ansi escape codes
const esc = "\x1B";
const csi = esc ++ "[";

pub const screen_clear = csi ++ "2J";
pub const bold = csi ++ "1m";
pub const normal = csi ++ "0m";
