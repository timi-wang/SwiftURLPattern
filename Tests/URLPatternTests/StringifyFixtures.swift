import Testing

@testable import URLPattern

struct StringifyFixtures {
  @Test
  func stringify() throws {
    var pattern = try! URLPattern("/foo")
    #expect(pattern.stringify() == "/foo")

    pattern = try! URLPattern("/user/:userId/task/:taskId")
    #expect(pattern.stringify(["userId": "10", "taskId": "52"]) == "/user/10/task/52")
    #expect(pattern.stringify(["userId": "10", "taskId": "52", "ignored": "ignored"]) == "/user/10/task/52")

    pattern = try! URLPattern(".user.:userId.task.:taskId")
    #expect(pattern.stringify(["userId": "10", "taskId": "52"]) == ".user.10.task.52")

    pattern = try! URLPattern("*/user/:userId")
    #expect(pattern.stringify(["_": "/school/10", "userId": "10"]) == "/school/10/user/10")

    pattern = try! URLPattern("*-user-:userId")
    #expect(pattern.stringify(["_": "-school-10", "userId": "10"]) == "-school-10-user-10")

    pattern = try! URLPattern("/admin*")
    #expect(pattern.stringify(["_": "/school/10/user/10"]) == "/admin/school/10/user/10")

    pattern = try! URLPattern("/admin/*/user/*/tail")
    #expect(pattern.stringify(["_": ["school/10", "10/12"]]) == "/admin/school/10/user/10/12/tail")

    pattern = try! URLPattern("/admin/*/user/:id/*/tail")
    #expect(pattern.stringify(["_": ["school/10", "12/13"], "id": "10"]) == "/admin/school/10/user/10/12/13/tail")

    pattern = try! URLPattern("/*/admin(/:path)")
    #expect(pattern.stringify(["_": "foo", "path": "baz"]) == "/foo/admin/baz")
    #expect(pattern.stringify(["_": "foo"]) == "/foo/admin")

    pattern = try! URLPattern("(/)")
    #expect(pattern.stringify() == "")

    pattern = try! URLPattern("/admin(/foo)/bar")
    #expect(pattern.stringify() == "/admin/bar")

    pattern = try! URLPattern("/admin(/:foo)/bar")
    #expect(pattern.stringify() == "/admin/bar")
    #expect(pattern.stringify(["foo": "baz"]) == "/admin/baz/bar")

    pattern = try! URLPattern("/admin/(*/)foo")
    #expect(pattern.stringify() == "/admin/foo")
    #expect(pattern.stringify(["_": "baz/bar/biff"]) == "/admin/baz/bar/biff/foo")

    pattern = try! URLPattern("/v:major.:minor/*")
    #expect(pattern.stringify(["_": "resource/", "major": "1", "minor": "2"]) == "/v1.2/resource/")

    pattern = try! URLPattern("/v:v.:v/*")
    #expect(pattern.stringify(["_": "resource/", "v": ["1", "2"]]) == "/v1.2/resource/")

    pattern = try! URLPattern("/:foo_bar")
    #expect(pattern.stringify(["foo": "a"]) == "/a_bar")
    #expect(pattern.stringify(["foo": "a_"]) == "/a__bar")
    #expect(pattern.stringify(["foo": "a-b-c-d_"]) == "/a-b-c-d__bar")
    #expect(pattern.stringify(["foo": "a b%c-d_"]) == "/a b%c-d__bar")

    pattern = try! URLPattern("((((a)b)c)d)")
    #expect(pattern.stringify() == "")

    pattern = try! URLPattern("(:a-)1-:b(-2-:c-3-:d(-4-*-:a))")
    #expect(pattern.stringify(["b": "B"]) == "1-B")
    #expect(pattern.stringify(["a": "A", "b": "B"]) == "A-1-B")
    #expect(pattern.stringify(["a": "A", "b": "B", "c": "C", "d": "D"]) == "A-1-B-2-C-3-D")
    #expect(pattern.stringify(["a": ["A", "F"], "b": "B", "c": "C", "d": "D", "_": "E"]) == "A-1-B-2-C-3-D-4-E-F")

    pattern = try! URLPattern("/user/:range")
    #expect(pattern.stringify(["range": "10-20"]) == "/user/10-20")
  }

  @Test
  func stringifyErrors() throws {
    let pattern = try! URLPattern("(:a-)1-:b(-2-:c-3-:d(-4-*-:a))")

    #expect(pattern.stringify([:]) == nil)
    #expect(pattern.stringify(["a": "A", "b": "B", "c": "C"]) == nil)
    #expect(pattern.stringify(["a": "A", "b": "B", "d": "D"]) == nil)
    #expect(pattern.stringify(["a": "A", "b": "B", "c": "C", "d": "D", "_": "E"]) == nil)
    #expect(pattern.stringify(["a": ["A", "F"], "b": "B", "c": "C", "d": "D"]) == nil)
  }
}
