import Foundation
import Testing

@testable import URLPattern

func areEqual(_ a: Any, _ b: Any) -> Bool {
    guard type(of: a) == type(of: b) else { return false }
    
    switch (a, b) {
    case let (a as String, b as String):
        return a == b
    case let (a as Int, b as Int):
        return a == b
    case let (a as Double, b as Double):
        return a == b
    case let (a as Bool, b as Bool):
        return a == b
    default:
        return false
    }
}

func dictEqual(_ dict1: [String: Any]?, _ dict2: [String: Any]?) -> Bool {
  guard let dict1, let dict2 else { return false }
  if dict1.keys.count != dict2.keys.count { return false }
  
  for (key, value) in dict1 {
    if let v = dict2[key] {
      if let a = v as? [Any], let b = value as? [Any] {
        if !a.elementsEqual(b, by: areEqual) { return false }
      }
      else if !areEqual(v, value) {
        return false
      }
    } else {
      return false
    }
  }
  
  return true
}

struct HelpersTests {
  @Test
  func escapeForRegexTest() throws {
    let expected = "\\[\\-\\/\\\\\\^\\$\\*\\+\\?\\.\\(\\)\\|\\[\\]\\{\\}\\]"
    let actual = escapeForRegex(#"[-/\^$*+?.()|[]{}]"#)
    #expect(actual == expected)

    #expect(escapeForRegex("a$98kdjf(kdj)") == "a\\$98kdjf\\(kdj\\)")
    #expect(escapeForRegex("a") == "a")
    #expect(escapeForRegex("!") == "!")
    #expect(escapeForRegex(".") == "\\.")
    #expect(escapeForRegex("/") == "\\/")
    #expect(escapeForRegex("-") == "\\-")
    #expect(escapeForRegex("-") == "\\-")
    #expect(escapeForRegex("[") == "\\[")
    #expect(escapeForRegex("]") == "\\]")
    #expect(escapeForRegex("(") == "\\(")
    #expect(escapeForRegex(")") == "\\)")
  }

  @Test
  func concatMapTest() throws {
    #expect(concatMap([], { _ in [] }).isEmpty)
    #expect(concatMap([1]) { [$0] } == [1])
    #expect(concatMap([1, 2, 3]) { Array(repeating: $0, count: 3) } == [1, 1, 1, 2, 2, 2, 3, 3, 3])
  }

  @Test
  func stringConcatMapTest() throws {
    #expect(stringConcatMap([]) { _ in "" } == "")
    #expect(stringConcatMap([1]) { "\($0)" } == "1")
    #expect(stringConcatMap([1, 2, 3]) { "\($0)" } == "123")
    #expect(stringConcatMap([1, 2, 3]) { "\($0)a" } == "1a2a3a")
  }

  @Test
  func regexGroupCountTest() throws {
    #expect(regexGroupCount(#"foo"#) == 0)
    #expect(regexGroupCount(#"(foo)"#) == 1)
    #expect(regexGroupCount(#"((foo))"#) == 2)
    #expect(regexGroupCount(#"(fo(o))"#) == 2)
    #expect(regexGroupCount(#"f(o)(o)"#) == 2)
    #expect(regexGroupCount(#"f(o)o()"#) == 2)
    #expect(regexGroupCount(#"f(o)o()()(())"#) == 5)
  }

  @Test
  func keysAndValuesToObjectTest() throws {
    #expect(keysAndValuesToObject(keys: [], values: []).isEmpty)

    #expect(dictEqual(keysAndValuesToObject(keys: ["one"], values: ["1"]), ["one": ["1"]]))

    #expect(dictEqual(keysAndValuesToObject(keys: ["one", "two"], values: ["1"]), ["one": ["1"]]))

    #expect(
      dictEqual(keysAndValuesToObject(keys: ["one", "two", "two"], values: ["1", "2", "3"]), [
        "one": ["1"],
        "two": ["2", "3"],
      ])
    )

    #expect(
      dictEqual(keysAndValuesToObject(keys: ["one", "two", "two", "two"], values: ["1", "2", "3", nil]), [
        "one": ["1"],
        "two": ["2", "3"],
      ])
    )

    #expect(
      dictEqual(keysAndValuesToObject(keys: ["one", "two", "two", "two"], values: ["1", "2", "3", "4"]), [
        "one": ["1"],
        "two": ["2", "3", "4"],
      ])
    )

    #expect(
      dictEqual(keysAndValuesToObject(
        keys: ["one", "two", "two", "two", "three"],
        values: ["1", "2", "3", "4", nil]
      ), [
        "one": ["1"],
        "two": ["2", "3", "4"],
      ])
    )

    #expect(
      dictEqual(keysAndValuesToObject(
        keys: ["one", "two", "two", "two", "three"],
        values: ["1", "2", "3", "4", "5"]
      ), [
        "one": ["1"],
        "two": ["2", "3", "4"],
        "three": ["5"],
      ])
    )

    #expect(
      dictEqual(keysAndValuesToObject(
        keys: ["one", "two", "two", "two", "three"],
        values: [nil, "2", "3", "4", "5"]
      ), [
        "two": ["2", "3", "4"],
        "three": ["5"],
      ])
    )
  }
}
