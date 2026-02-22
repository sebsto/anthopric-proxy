#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import Testing
@testable import App

private func json(_ string: String) throws -> [String: JSONValue] {
    try JSONDecoder().decode([String: JSONValue].self, from: Data(string.utf8))
}

@Suite("XcodeTraceValidation Tests")
struct XcodeTraceValidationTests {

    @Test("Xcode trace request translated correctly end-to-end")
    func testXcodeRequestTranslation() throws {
        let request = try json("""
        {
            "model": "anthropic/claude-opus-4.6",
            "messages": [
                {"role": "system", "content": "You are a helpful coding assistant integrated into Xcode."},
                {"role": "user", "content": [{"type": "text", "text": "Explain this code."}]}
            ],
            "stream": true,
            "stream_options": {"include_usage": true},
            "tools": []
        }
        """)

        let result = try RequestTranslator().translate(request, bedrockModelId: "anthropic.claude-opus-4-6-v1:0")

        #expect(result.bedrockBody.system == "You are a helpful coding assistant integrated into Xcode.")
        #expect(result.bedrockBody.messages.count == 1)

        let userMessage = result.bedrockBody.messages[0]
        #expect(userMessage.role == "user")
        let expectedContent = AnthropicContent.blocks([.text(TextBlock(text: "Explain this code."))])
        #expect(userMessage.content == expectedContent)

        #expect(result.bedrockBody.anthropicVersion == "bedrock-2023-05-31")
        #expect(result.bedrockBody.maxTokens == 8192)
        #expect(result.bedrockBody.tools == nil)
        #expect(result.bedrockPath.contains("anthropic.claude-opus-4-6-v1:0"))
        #expect(result.isStreaming == true)
        #expect(result.bedrockPath.hasSuffix("/invoke-with-response-stream"))
        #expect(result.includeUsage == true)
        #expect(result.originalModel == "anthropic/claude-opus-4.6")
    }
}
