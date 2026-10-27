import Foundation

@main
struct SafariChoiceTests {
    static func main() throws {
        let canonical = try SafariChoiceSupport.service(for: "https://example.org/a?session=private")
        precondition(canonical == "https://example.org:443 (com.apple.Safari)")
        let explicitPort = try SafariChoiceSupport.service(for: " https://EXAMPLE.org:8443/path ")
        precondition(explicitPort == "https://example.org:8443 (com.apple.Safari)")
        for invalid in ["http://example.org", "file:///tmp/a", "https://name:secret@example.org", "https://example.org:65536", "https://", "https://exam\nple.org"] {
            do { _ = try SafariChoiceSupport.service(for: invalid); fatalError("Accepted invalid origin") }
            catch is SafariChoiceSupport.InputError { }
        }
        let script = try SafariChoiceSupport.script(for: "https://example.org/path?secret=do-not-save")
        precondition(!script.contains("do-not-save") && !script.contains("/path"))
        precondition(!script.contains("delete-certificate") && !script.contains("delete-identity"))
        for literal in ["quote'within", "$(printf INJECTED)", "`printf INJECTED`", "semi;printf INJECTED", "line\nnext"] {
            let task=Process(); let pipe=Pipe()
            task.executableURL=URL(fileURLWithPath: "/bin/bash")
            task.arguments=["-c", "printf '%s' " + SafariChoiceSupport.shellQuote(literal)]
            task.standardOutput=pipe
            try task.run();task.waitUntilExit()
            let result=String(data:pipe.fileHandleForReading.readDataToEndOfFile(),encoding:.utf8)
            precondition(task.terminationStatus==0 && result==literal)
        }
        print("PASS: origin scoping, removal of URL secrets, invalid input rejection and shell-injection boundaries.")
    }
}
