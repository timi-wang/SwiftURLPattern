import Foundation
import Testing

@testable import URLPattern

struct MiscTests {
  @Test
  func newFromURLPattern() throws {
    let pattern = try! URLPattern("/user/:userId/task/:taskId")
    let copy = URLPattern(pattern)
    #expect(dictEqual(copy.match("/user/10/task/52"), ["userId": "10", "taskId": "52"]))
  }
  
  @Test
  func testSegmentValue() throws {
    let pattern = try! URLPattern("/api/v1/user/:id/", ParserOptions(segmentValueCharset: "a-zA-Z0-9-_ %."))
    #expect(dictEqual(pattern.match("/api/v1/user/test.name/"), ["id": "test.name"]))
  }
  
  @Test
  func regexGroupNames() throws {
    let pattern = try! URLPattern(regex: #"^\/api\/([a-zA-Z0-9-_~ %]+)(?:\/(\d+))?$"#, ["resource", "id"])
    #expect(dictEqual(pattern.match("/api/users"), ["resource": "users"]))
    #expect(pattern.match("/apiii/users") == nil)
    #expect(pattern.match("/api/users/foo") == nil)
    #expect(dictEqual(pattern.match("/api/users/10"), ["resource": "users", "id": "10"]))
    #expect(pattern.match("/api/projects/10/") == nil)
  }
}
