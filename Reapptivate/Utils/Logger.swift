import OSLog

enum Log {
    private static let subsystem = "com.reapptivate.ios"

    static let auth = Logger(subsystem: subsystem, category: "auth")
    static let api = Logger(subsystem: subsystem, category: "api")
    static let sync = Logger(subsystem: subsystem, category: "sync")
    static let exercise = Logger(subsystem: subsystem, category: "exercise")
    static let notification = Logger(subsystem: subsystem, category: "notification")
    static let audio = Logger(subsystem: subsystem, category: "audio")
    static let general = Logger(subsystem: subsystem, category: "general")
}
