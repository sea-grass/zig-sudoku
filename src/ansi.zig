// ansi escape codes
const DEBUG = true;

const esc = "\x1B";
const csi = esc ++ "[";

pub const screen_clear = if (DEBUG) "" else csi ++ "2J";
pub const bold = csi ++ "1m";
pub const normal = csi ++ "0m";
