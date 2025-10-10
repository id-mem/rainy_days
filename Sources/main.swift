import Darwin
import Foundation

let escape: String = "\u{001B}["
let resetColor: String = "\(escape)0m"
let hideCursor: String = "\(escape)?25l"
let showCursor: String = "\(escape)?25h"
let clearScreen: String = "\(escape)2J"
let homeCursor: String = "\(escape)H"

let rainOptions: String = "|    "
let animationInterval: TimeInterval = 0.05

let rainColors: [String] = [
    "38;5;21m", "38;5;27m",
    "38;5;33m", "38;5;39m",
    "38;5;63m", "38;5;201m",
    "38;5;90m", "38;5;92m",
    "38;5;93m", "38;5;99m",
    "38;5;129m", "38;5;163m",
    "38;5;198m", "38;5;200m",
    "38;5;205m", "38;5;206m",
]

let asciiArtColor: String = "38;2;77;140;231m"
let asciiArt: String = """
            ════════
         ════      ═══
       ═══       ══   
      ═         ══    
     ══        ═        ═════
    ══       ══       ═══   ══
    ═       ═══       ═══  ═══
    ═      ══  ═══       ═══  
    ══     ═     ════  ══════ 
     ═══  ═          ═══     ═══
       ════           ═       ═══
         ══           ══      ═ ═
                       ══     ═  
                        ═      ═ 
                        ═      ═  
    """

var terminalSize = getTerminalSize()
var rainDrops: [RainDrop] = initializeDrops()

func prepTerminal() {
    print(hideCursor + clearScreen + homeCursor + resetColor)
}

func restoreTerminal() {
    print(showCursor + resetColor)
}

func parseInitialFile(filePath: String) -> Configuration {
    let fileName = (filePath as NSString).lastPathComponent

    guard filePath.hasSuffix(".json") else {
        Logger.logParseError(
            ParseError.invalidFilePath("Requires JSON file: \(filePath)"))
        restoreTerminal()
        exit(EXIT_FAILURE)
    }

    do {
        let fileURL = URL(fileURLWithPath: filePath)
        let fileData = try Data(contentsOf: fileURL)
        Logger.logInfo("Successfully read data from \(fileName)")
        do {
            let decoder = JSONDecoder()
            let config = try decoder.decode(Configuration.self, from: fileData)
            Logger.logInfo("Successfully decoded JSON from \(fileName)")
            return config
        } catch {
            Logger.logParseError(
                ParseError.jsonParsingError(
                    "Failed to decode JSON from \(fileName): \(error.localizedDescription)"))
            restoreTerminal()
            exit(EXIT_FAILURE)
        }
    } catch {
        Logger.logParseError(
            ParseError.fileNotFound("File not found at path: \(filePath)"))
        restoreTerminal()
        exit(EXIT_FAILURE)
    }
}

func getTerminalSize() -> (width: Int, height: Int) {
    var size: winsize = winsize()

    if ioctl(STDOUT_FILENO, TIOCGWINSZ, &size) != 0 {
        return (80, 24)
    }

    return (Int(size.ws_col), Int(size.ws_row))
}

@MainActor func renderAsciiArt(_ config: Configuration?) {
    let color: String

    if let artColor = config?.artColor {
        color = artColor
    } else {
        color = asciiArtColor
    }

    let lines = asciiArt.components(separatedBy: .newlines)
    let longestLineLength = lines.map { $0.count }.max() ?? 0
    let xPosition = (terminalSize.width / 2) - (longestLineLength / 2) + 1

    for (index, line) in lines.enumerated() {
        let yPosition = (terminalSize.height - lines.count + (index))

        if yPosition < 0 { continue }

        print(
            "\(escape)\(color)\(escape)\(yPosition);\(xPosition)H\(line)\(resetColor)")
        print(
            "\(escape)\(color)\(escape)\(getTerminalSize().height);\(xPosition)H                    ═      ═ ",
            terminator: "")
    }
}

@MainActor func initializeDrops() -> [RainDrop] {
    var drops = Array(
        repeating: RainDrop(x: 0, y: 0, speed: 0, character: " "),
        count: terminalSize.width)
    for i: Int in 0..<drops.count {
        drops[i] = RainDrop(
            x: Int.random(in: 0..<terminalSize.width),
            y: 0,
            speed: Int.random(in: 1...3),
            character: rainOptions.randomElement() ?? " ")
    }

    return drops
}

@MainActor func renderRainDrop(rainDrop: RainDrop, color: String) {
    if rainDrop.x < 0 || rainDrop.x >= terminalSize.width || rainDrop.y < 0
        || rainDrop.y >= terminalSize.height
    {
        return
    }

    print(
        "\(escape)\(color)\(escape)\(rainDrop.y + 1);\(rainDrop.x + 1)H\(rainDrop.character)\(resetColor)",
        terminator: "")

}

@MainActor func animateFrame(_ config: Configuration?) {
    for i: Int in 0..<rainDrops.count {

        if let color = config?.rainColors.randomElement() {
            renderRainDrop(
                rainDrop: rainDrops[i],
                color: "\(color)")
        } else {
            renderRainDrop(
                rainDrop: rainDrops[i],
                color: "\(rainColors.randomElement() ?? "")")
        }

        rainDrops[i].y += rainDrops[i].speed
        if rainDrops[i].y >= terminalSize.height {
            let newCharacter = rainOptions.randomElement() ?? " "
            rainDrops[i] = RainDrop(
                x: newCharacter == " " ? rainDrops[i].x : Int.random(in: 0..<terminalSize.width),
                y: 0,
                speed: newCharacter == " " ? 1 : Int.random(in: 1...3),
                character: newCharacter
            )
        }
    }
}

@MainActor func beginRain() {
    var config: Configuration?
    if CommandLine.arguments.contains("-config") {
        guard let configIndex = CommandLine.arguments.firstIndex(of: "-config"),
            CommandLine.arguments.count > configIndex + 1,
            CommandLine.arguments[configIndex + 1] != "-ascii"
        else {
            Logger.logParseError(
                ParseError.invalidFilePath("No valid file path provided after -config"))
            restoreTerminal()
            exit(EXIT_FAILURE)
        }
        let configFilePath = CommandLine.arguments[configIndex + 1]
        config = parseInitialFile(filePath: configFilePath)
    }

    prepTerminal()

    Timer.scheduledTimer(
        withTimeInterval: config?.animationInterval ?? animationInterval, repeats: true
    ) { _ in
        DispatchQueue.main.async {
            animateFrame(config)
            if CommandLine.arguments.contains("-ascii") {
                renderAsciiArt(config)
            }
        }
    }

    RunLoop.current.run()
}

signal(
    SIGWINCH,
    { _ in
        terminalSize = getTerminalSize()
    })

signal(
    SIGINT,
    { _ in
        restoreTerminal()
        exit(0)
    })

beginRain()
