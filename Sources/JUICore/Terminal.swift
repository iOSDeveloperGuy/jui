import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#else
#error("jui currently supports POSIX terminals on macOS and Linux")
#endif

public enum InputEvent: Equatable {
    case enter
    case controlC
    case escape
    case arrowUp
    case arrowDown
    case backspace
    case character(UInt8)
    case unknown
}

public struct TerminalState {
    fileprivate var attributes: termios
}

public enum Terminal {
    public static func enableRawMode() throws -> TerminalState {
        var original = termios()
        guard tcgetattr(STDIN_FILENO, &original) == 0 else {
            throw JUIError.terminal("enable terminal mode: \(posixError())")
        }

        var raw = original
        raw.c_lflag &= ~tcflag_t(ICANON | ECHO)
        withUnsafeMutableBytes(of: &raw.c_cc) { bytes in
            bytes[Int(VMIN)] = 1
            bytes[Int(VTIME)] = 0
        }

        guard tcsetattr(STDIN_FILENO, TCSANOW, &raw) == 0 else {
            throw JUIError.terminal("enable terminal mode: \(posixError())")
        }
        return TerminalState(attributes: original)
    }

    public static func restore(_ state: TerminalState) {
        var attributes = state.attributes
        _ = tcsetattr(STDIN_FILENO, TCSANOW, &attributes)
    }

    public static func dimensions() -> (rows: Int, columns: Int) {
        var size = winsize(ws_row: 0, ws_col: 0, ws_xpixel: 0, ws_ypixel: 0)
        #if canImport(Darwin)
        let result = ioctl(STDOUT_FILENO, TIOCGWINSZ, &size)
        #else
        let result = ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &size)
        #endif

        guard result == 0, size.ws_row > 0, size.ws_col > 0 else {
            return (24, Renderer.selectedRowWidth + 1)
        }
        return (Int(size.ws_row), Int(size.ws_col))
    }

    public static func readEvent() throws -> InputEvent {
        let first = try readByte()
        switch first {
        case 3: return .controlC
        case 10, 13: return .enter
        case 8, 127: return .backspace
        case 27:
            guard inputAvailable(timeoutMilliseconds: 12) else {
                return .escape
            }
            let second = try readByte()
            guard second == 91, inputAvailable(timeoutMilliseconds: 12) else {
                return .escape
            }
            switch try readByte() {
            case 65: return .arrowUp
            case 66: return .arrowDown
            default: return .unknown
            }
        case 32...126:
            return .character(first)
        default:
            return .unknown
        }
    }

    public static func enterAlternateScreen() {
        write("\u{001B}[?1049h\u{001B}[?25l\u{001B}[2J\u{001B}[H")
    }

    public static func leaveAlternateScreen() {
        write("\u{001B}[?25h\u{001B}[?1049l")
    }

    public static func showCursor() {
        write("\u{001B}[?25h")
    }

    public static func write(_ value: String) {
        FileHandle.standardOutput.write(Data(value.utf8))
    }

    private static func readByte() throws -> UInt8 {
        var byte: UInt8 = 0
        let count = read(STDIN_FILENO, &byte, 1)
        guard count == 1 else {
            throw JUIError.terminal("read terminal input: \(posixError())")
        }
        return byte
    }

    private static func inputAvailable(timeoutMilliseconds: Int32) -> Bool {
        var descriptor = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN), revents: 0)
        return poll(&descriptor, 1, timeoutMilliseconds) > 0
    }

    private static func posixError() -> String {
        String(cString: strerror(errno))
    }
}
