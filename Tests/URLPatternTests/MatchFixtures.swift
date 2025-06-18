import Foundation
import Testing

@testable import URLPattern

struct MatchFixturesTests {
  @Test
  func match() throws {
    var pattern = try! URLPattern("/foo")
    #expect(pattern.match("/foo") == [:])
    #expect(pattern.match("/foobar") == nil)
    #expect(pattern.match("/bar/foo") == nil)

    pattern = try! URLPattern(".foo")
    #expect(pattern.match(".foo") == [:])
    #expect(pattern.match(".foobar") == nil)
    #expect(pattern.match(".bar.foo") == nil)

    pattern = try! URLPattern(regex: "foo")
    #expect(pattern.match("foo") == [:])
    pattern = try! URLPattern(regex: #"\/foo\/(.*)"#)
    #expect(dictEqual(pattern.match("/foo/bar"), ["1": "bar"]))
    #expect(dictEqual(pattern.match("/foo/"), ["1": ""]))

    pattern = try! URLPattern("/user/:userId/task/:taskId")
    #expect(dictEqual(pattern.match("/user/10/task/52"), ["userId": "10", "taskId": "52"]))

    pattern = try! URLPattern(".user.:userId.task.:taskId")
    #expect(dictEqual(pattern.match(".user.10.task.52"), ["userId": "10", "taskId": "52"]))

    pattern = try! URLPattern("*/user/:userId")
    #expect(dictEqual(pattern.match("/school/10/user/10"), ["_": "/school/10", "userId": "10"]))

    pattern = try! URLPattern("*-user-:userId")
    #expect(dictEqual(pattern.match("-school-10-user-10"), ["_": "-school-10", "userId": "10"]))

    pattern = try! URLPattern("/admin*")
    #expect(dictEqual(pattern.match("/admin/school/10/user/10"), ["_": "/school/10/user/10"]))

    pattern = try! URLPattern("#admin*")
    #expect(dictEqual(pattern.match("#admin#school#10#user#10"), ["_": "#school#10#user#10"]))

    pattern = try! URLPattern("/admin/*/user/:userId")
    #expect(dictEqual(pattern.match("/admin/school/10/user/10"), ["_": "school/10", "userId": "10"]))

    pattern = try! URLPattern("$admin$*$user$:userId")
    #expect(dictEqual(pattern.match("$admin$school$10$user$10"), ["_": "school$10", "userId": "10"]))

    pattern = try! URLPattern("/admin/*/user/*/tail")
    #expect(dictEqual(pattern.matchAll("/admin/school/10/user/10/12/tail"), ["_": ["school/10", "10/12"]]))

    pattern = try! URLPattern("$admin$*$user$*$tail")
    #expect(dictEqual(pattern.matchAll("$admin$school$10$user$10$12$tail"), ["_": ["school$10", "10$12"]]))

    pattern = try! URLPattern("/admin/*/user/:id/*/tail")
    #expect(
      dictEqual(pattern.matchAll("/admin/school/10/user/10/12/13/tail"), ["_": ["school/10", "12/13"], "id": ["10"]])
    )

    pattern = try! URLPattern("^admin^*^user^:id^*^tail")
    #expect(
      dictEqual(pattern.matchAll("^admin^school^10^user^10^12^13^tail"), ["_": ["school^10", "12^13"], "id": ["10"]])
    )

    pattern = try! URLPattern("/*/admin(/:path)")
    #expect(dictEqual(pattern.match("/admin/admin/admin"), ["_": "admin", "path": "admin"]))

    pattern = try! URLPattern("(/)")
    #expect(dictEqual(pattern.match(""), [:]))
    #expect(dictEqual(pattern.match("/"), [:]))

    pattern = try! URLPattern("/admin(/foo)/bar")
    #expect(dictEqual(pattern.match("/admin/foo/bar"), [:]))
    #expect(dictEqual(pattern.match("/admin/bar"), [:]))

    pattern = try! URLPattern("/admin(/:foo)/bar")
    #expect(dictEqual(pattern.match("/admin/baz/bar"), ["foo": "baz"]))
    #expect(dictEqual(pattern.match("/admin/bar"), [:]))

    pattern = try! URLPattern("/admin/(*/)foo")
    #expect(dictEqual(pattern.match("/admin/foo"), [:]))
    #expect(dictEqual(pattern.match("/admin/baz/bar/biff/foo"), ["_": "baz/bar/biff"]))

    pattern = try! URLPattern("/v:major.:minor/*")
    #expect(dictEqual(pattern.match("/v1.2/resource/"), ["_": "resource/", "major": "1", "minor": "2"]))

    pattern = try! URLPattern("/v:v.:v/*")
    #expect(dictEqual(pattern.matchAll("/v1.2/resource/"), ["_": ["resource/"], "v": ["1", "2"]]))

    pattern = try! URLPattern("/:foo_bar")
    #expect(pattern.match("/_bar") == nil)
    #expect(dictEqual(pattern.match("/a_bar"), ["foo": "a"]))
    #expect(dictEqual(pattern.match("/a__bar"), ["foo": "a_"]))
    #expect(dictEqual(pattern.match("/a-b-c-d__bar"), ["foo": "a-b-c-d_"]))
    #expect(dictEqual(pattern.match("/a b%c-d__bar"), ["foo": "a b%c-d_"]))

    pattern = try! URLPattern("((((a)b)c)d)")
    #expect(dictEqual(pattern.match(""), [:]))
    #expect(pattern.match("a") == nil)
    #expect(pattern.match("ab") == nil)
    #expect(pattern.match("abc") == nil)
    #expect(dictEqual(pattern.match("abcd"), [:]))
    #expect(dictEqual(pattern.match("bcd"), [:]))
    #expect(dictEqual(pattern.match("cd"), [:]))
    #expect(dictEqual(pattern.match("d"), [:]))

    pattern = try! URLPattern("/user/:range")
    #expect(dictEqual(pattern.match("/user/10-20"), ["range": "10-20"]))

    pattern = try! URLPattern("/user/:range")
    #expect(dictEqual(pattern.match("/user/10_20"), ["range": "10_20"]))

    pattern = try! URLPattern("/user/:range")
    #expect(dictEqual(pattern.match("/user/10 20"), ["range": "10 20"]))

    pattern = try! URLPattern("/user/:range")
    #expect(dictEqual(pattern.match("/user/10%20"), ["range": "10%20"]))

    pattern = try! URLPattern("/vvv:version/*")
    #expect(pattern.match("/vvv/resource") == nil)
    #expect(dictEqual(pattern.match("/vvv1/resource"), ["_": "resource", "version": "1"]))
    #expect(pattern.match("/vvv1.1/resource") == nil)

    pattern = try! URLPattern("/api/users/:id", ParserOptions(segmentValueCharset: "a-zA-Z0-9-_~ %.@"))
    #expect(dictEqual(pattern.match("/api/users/someuser@example.com"), ["id": "someuser@example.com"]))

    pattern = try! URLPattern("/api/users?username=:username", ParserOptions(segmentValueCharset: "a-zA-Z0-9-_~ %.@"))
    #expect(dictEqual(pattern.match("/api/users?username=someone@example.com"), ["username": "someone@example.com"]))

    pattern = try! URLPattern("/api/users?param1=:param1&param2=:param2")
    #expect(dictEqual(pattern.match("/api/users?param1=foo&param2=bar"), ["param1": "foo", "param2": "bar"]))

    pattern = try! URLPattern(":scheme\\://:host(\\::port)", ParserOptions(segmentValueCharset: "a-zA-Z0-9-_~ %."))
    #expect(dictEqual(pattern.match("ftp://ftp.example.com"), ["scheme": "ftp", "host": "ftp.example.com"]))
    #expect(
      dictEqual(
        pattern.match("ftp://ftp.example.com:8080"),
        ["scheme": "ftp", "host": "ftp.example.com", "port": "8080"]
      )
    )
    #expect(
      dictEqual(pattern.match("https://example.com:80"), ["scheme": "https", "host": "example.com", "port": "80"])
    )

    pattern = try! URLPattern(
      ":scheme\\://:host(\\::port)(/api(/:resource(/:id)))",
      ParserOptions(segmentValueCharset: "a-zA-Z0-9-_~ %.@")
    )
    #expect(
      dictEqual(pattern.match("https://sss.www.localhost.com"), ["scheme": "https", "host": "sss.www.localhost.com"])
    )
    #expect(
      dictEqual(
        pattern.match("https://sss.www.localhost.com:8080"),
        ["scheme": "https", "host": "sss.www.localhost.com", "port": "8080"]
      )
    )
    #expect(
      dictEqual(
        pattern.match("https://sss.www.localhost.com/api"),
        ["scheme": "https", "host": "sss.www.localhost.com"]
      )
    )
    #expect(
      dictEqual(
        pattern.match("https://sss.www.localhost.com/api/security"),
        ["scheme": "https", "host": "sss.www.localhost.com", "resource": "security"]
      )
    )
    #expect(
      dictEqual(
        pattern.match("https://sss.www.localhost.com/api/security/bob@example.com"),
        [
          "scheme": "https",
          "host": "sss.www.localhost.com",
          "resource": "security",
          "id": "bob@example.com",
        ]
      )
    )

    pattern = try! URLPattern(
      regex:
        #"\/ip\/(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"#
    )
    #expect(pattern.match("10.10.10.10") == nil)
    #expect(pattern.match("ip/10.10.10.10") == nil)
    #expect(pattern.match("/ip/10.10.10.") == nil)
    #expect(pattern.match("/ip/10.") == nil)
    #expect(pattern.match("/ip/") == nil)
    #expect(dictEqual(pattern.match("/ip/10.10.10.10"), ["1": "10", "2": "10", "3": "10", "4": "10"]))
    #expect(dictEqual(pattern.match("/ip/127.0.0.1"), ["1": "127", "2": "0", "3": "0", "4": "1"]))
    
    pattern = try! URLPattern(regex: #"\/ip\/((?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))$"#)
    #expect(dictEqual(pattern.match("/ip/10.10.10.10"), ["1": "10.10.10.10"]))
    #expect(dictEqual(pattern.match("/ip/127.0.0.1"), ["1": "127.0.0.1"]))
    
    pattern = try! URLPattern(regex: #"\/ip\/((?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))$"#, ["ip"])
    #expect(dictEqual(pattern.match("/ip/10.10.10.10"), ["ip": "10.10.10.10"]))
    #expect(dictEqual(pattern.match("/ip/127.0.0.1"), ["ip": "127.0.0.1"]))
  }

}
