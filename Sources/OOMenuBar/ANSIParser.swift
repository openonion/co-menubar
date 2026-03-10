import AppKit

/// ANSI Escape Code Parser
///
/// Converts terminal output with ANSI escape codes into NSAttributedString with colors and formatting.
/// This allows displaying Rich-formatted console output (from `co ai`) with proper colors in macOS UI.
///
/// ## ANSI Escape Code Format
/// ANSI codes use the format: `\033[<code>m` or `\u{1B}[<code>m`
/// Examples:
/// - `\033[31m` - Red text
/// - `\033[1m` - Bold text
/// - `\033[0m` - Reset formatting
///
/// ## Supported Features
/// - Standard colors (30-37): Black, Red, Green, Yellow, Blue, Magenta, Cyan, White
/// - Bright colors (90-97): Bright variants of standard colors
/// - Bold text (1) and bold reset (22)
/// - Color reset (0, 39)
///
/// ## Usage
/// ```swift
/// let parser = ANSIParser(defaultTextColor: .white, defaultFont: .monospacedSystemFont)
/// let coloredText = parser.parse("\u{1B}[31mError:\u{1B}[0m Something went wrong")
/// textView.textStorage?.append(coloredText)
/// ```
///
/// ## Implementation Notes
/// - Uses regex to split text by escape sequences
/// - Maintains state (current color, bold) while parsing
/// - Falls back to plain text if regex fails
/// - Does not support 256-color or RGB codes yet (future enhancement)
class ANSIParser {
    /// ANSI color code to NSColor mappings
    ///
    /// Maps ANSI color codes (30-37 for standard, 90-97 for bright) to macOS NSColor.
    /// Colors are calibrated for dark theme (matching terminal appearance).
    private static let colors: [Int: NSColor] = [
        // Standard colors (30-37)
        30: NSColor(calibratedRed: 0.0, green: 0.0, blue: 0.0, alpha: 1.0),      // Black
        31: NSColor(calibratedRed: 0.8, green: 0.0, blue: 0.0, alpha: 1.0),      // Red
        32: NSColor(calibratedRed: 0.0, green: 0.8, blue: 0.0, alpha: 1.0),      // Green
        33: NSColor(calibratedRed: 0.8, green: 0.8, blue: 0.0, alpha: 1.0),      // Yellow
        34: NSColor(calibratedRed: 0.0, green: 0.0, blue: 0.8, alpha: 1.0),      // Blue
        35: NSColor(calibratedRed: 0.8, green: 0.0, blue: 0.8, alpha: 1.0),      // Magenta
        36: NSColor(calibratedRed: 0.0, green: 0.8, blue: 0.8, alpha: 1.0),      // Cyan
        37: NSColor(calibratedRed: 0.8, green: 0.8, blue: 0.8, alpha: 1.0),      // White

        // Bright colors (90-97)
        90: NSColor(calibratedRed: 0.5, green: 0.5, blue: 0.5, alpha: 1.0),      // Bright Black (Gray)
        91: NSColor(calibratedRed: 1.0, green: 0.3, blue: 0.3, alpha: 1.0),      // Bright Red
        92: NSColor(calibratedRed: 0.31, green: 0.87, blue: 0.47, alpha: 1.0),   // Bright Green
        93: NSColor(calibratedRed: 1.0, green: 1.0, blue: 0.3, alpha: 1.0),      // Bright Yellow
        94: NSColor(calibratedRed: 0.3, green: 0.6, blue: 1.0, alpha: 1.0),      // Bright Blue
        95: NSColor(calibratedRed: 1.0, green: 0.3, blue: 1.0, alpha: 1.0),      // Bright Magenta
        96: NSColor(calibratedRed: 0.3, green: 1.0, blue: 1.0, alpha: 1.0),      // Bright Cyan
        97: NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),      // Bright White
    ]

    /// Default text color (used when no ANSI color is active)
    private let defaultTextColor: NSColor

    /// Default font (used for regular text, not bold)
    private let defaultFont: NSFont

    /// Initialize the ANSI parser
    ///
    /// - Parameters:
    ///   - defaultTextColor: Color to use for text without ANSI color codes
    ///   - defaultFont: Font to use for regular (non-bold) text
    init(defaultTextColor: NSColor, defaultFont: NSFont) {
        self.defaultTextColor = defaultTextColor
        self.defaultFont = defaultFont
    }

    /// Parse ANSI-encoded text and convert to attributed string with colors
    ///
    /// This method:
    /// 1. Splits text by ANSI escape sequences using regex
    /// 2. Tracks current formatting state (color, bold)
    /// 3. Applies formatting to each text segment
    /// 4. Returns combined NSAttributedString with colors
    ///
    /// - Parameter text: Raw text with ANSI escape codes (e.g., from terminal output)
    /// - Returns: NSAttributedString with colors and formatting applied
    ///
    /// ## Example
    /// Input: `"\u{1B}[31mError\u{1B}[0m: File not found"`
    /// Output: "Error" (in red) + ": File not found" (default color)
    func parse(_ text: String) -> NSAttributedString {
        let result = NSMutableAttributedString()

        // Current formatting state
        var currentColor = defaultTextColor
        var currentFont = defaultFont
        var isBold = false

        // Split by ANSI escape sequences: \033[ or \u{1B}[
        let pattern = "\\u{1B}\\[[0-9;]*m"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            // Fallback: return plain text
            return NSAttributedString(string: text, attributes: [
                .foregroundColor: defaultTextColor,
                .font: defaultFont
            ])
        }

        let nsText = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))

        var lastIndex = 0

        for match in matches {
            // Add text before this escape code
            if match.range.location > lastIndex {
                let textRange = NSRange(location: lastIndex, length: match.range.location - lastIndex)
                let textSegment = nsText.substring(with: textRange)

                let attrs: [NSAttributedString.Key: Any] = [
                    .foregroundColor: currentColor,
                    .font: currentFont
                ]
                result.append(NSAttributedString(string: textSegment, attributes: attrs))
            }

            // Parse escape code
            let escapeCode = nsText.substring(with: match.range)
            let (newColor, newBold) = parseEscapeCode(escapeCode, currentColor: currentColor, currentBold: isBold)
            currentColor = newColor
            isBold = newBold
            currentFont = isBold ? NSFont.monospacedSystemFont(ofSize: defaultFont.pointSize, weight: .bold) : defaultFont

            lastIndex = match.range.location + match.range.length
        }

        // Add remaining text
        if lastIndex < nsText.length {
            let textRange = NSRange(location: lastIndex, length: nsText.length - lastIndex)
            let textSegment = nsText.substring(with: textRange)

            let attrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: currentColor,
                .font: currentFont
            ]
            result.append(NSAttributedString(string: textSegment, attributes: attrs))
        }

        return result
    }

    /// Parse a single ANSI escape code and return new formatting state
    ///
    /// Extracts the numeric codes from escape sequences and updates color/bold state.
    ///
    /// - Parameters:
    ///   - code: ANSI escape sequence (e.g., "\u{1B}[31m")
    ///   - currentColor: Current text color
    ///   - currentBold: Current bold state
    /// - Returns: Tuple of (new color, new bold state)
    ///
    /// ## Supported Codes
    /// - 0: Reset all formatting
    /// - 1: Enable bold
    /// - 22: Disable bold
    /// - 30-37: Standard foreground colors
    /// - 39: Default foreground color
    /// - 90-97: Bright foreground colors
    private func parseEscapeCode(_ code: String, currentColor: NSColor, currentBold: Bool) -> (NSColor, Bool) {
        // Extract numbers from escape code: \033[31m -> [31]
        let codeStr = code.replacingOccurrences(of: "\u{1B}[", with: "").replacingOccurrences(of: "m", with: "")
        let codes = codeStr.split(separator: ";").compactMap { Int($0) }

        var newColor = currentColor
        var newBold = currentBold

        for code in codes {
            switch code {
            case 0:
                // Reset
                newColor = defaultTextColor
                newBold = false
            case 1:
                // Bold
                newBold = true
            case 22:
                // Not bold
                newBold = false
            case 30...37, 90...97:
                // Foreground color
                if let color = ANSIParser.colors[code] {
                    newColor = color
                }
            case 38:
                // 256-color or RGB (skip for now, use default)
                break
            case 39:
                // Default foreground
                newColor = defaultTextColor
            default:
                break
            }
        }

        return (newColor, newBold)
    }
}
