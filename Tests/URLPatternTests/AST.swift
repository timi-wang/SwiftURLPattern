import Foundation
import Testing

@testable import URLPattern

struct ASTRegexAndNameTests {
  let parse = Parser().pattern

  @Test
  func justStaticAlphanumeric() throws {
    let parsed = parse("user42")
    #expect(parsed != nil)
    #expect(astNodeToRegexString(parsed!.value) == "^user42$")
    #expect(astNodeToNames(parsed!.value) == [])
  }

  @Test
  func justStaticEscaped() throws {
    let parsed = parse("/api/v1/users")
    #expect(parsed != nil)
    #expect(astNodeToRegexString(parsed!.value) == "^\\/api\\/v1\\/users$")
    #expect(astNodeToNames(parsed!.value) == [])
  }

  @Test
  func justSingleCharVariable() throws {
    let parsed = parse(":a")
    #expect(parsed != nil)
    #expect(astNodeToRegexString(parsed!.value) == "^([a-zA-Z0-9-_~ %]+)$")
    #expect(astNodeToNames(parsed!.value) == ["a"])
  }

  @Test
  func justVariable() throws {
    let parsed = parse(":variable")
    #expect(parsed != nil)
    #expect(astNodeToRegexString(parsed!.value) == "^([a-zA-Z0-9-_~ %]+)$")
    #expect(astNodeToNames(parsed!.value) == ["variable"])
  }

  @Test
  func justWildcard() throws {
    let parsed = parse("*")
    #expect(parsed != nil)
    #expect(astNodeToRegexString(parsed!.value) == "^(.*?)$")
    #expect(astNodeToNames(parsed!.value) == ["_"])
  }

  @Test
  func justOptionalStatic() throws {
    let parsed = parse("(foo)")
    #expect(parsed != nil)
    #expect(astNodeToRegexString(parsed!.value) == "^(?:foo)?$")
    #expect(astNodeToNames(parsed!.value) == [])
  }

  @Test
  func justOptionalVariable() throws {
    let parsed = parse("(:foo)")
    #expect(parsed != nil)
    #expect(astNodeToRegexString(parsed!.value) == "^(?:([a-zA-Z0-9-_~ %]+))?$")
    #expect(astNodeToNames(parsed!.value) == ["foo"])
  }

  @Test
  func justOptionalWildcard() throws {
    let parsed = parse("(*)")
    #expect(parsed != nil)
    #expect(astNodeToRegexString(parsed!.value) == "^(?:(.*?))?$")
    #expect(astNodeToNames(parsed!.value) == ["_"])
  }
}

struct ASTGetParamTests {
  let parse = Parser().pattern

  @Test
  func noSideEffects() throws {
    // Empty case
    var next: [String: Int] = [:]
    #expect(try getParam([:], "one", &next) == nil)
    #expect(next.isEmpty)

    // Value tests
    next = [:]
    #expect(try getParam(["one": 1], "one", &next) as! Int == 1)
    #expect(next.isEmpty)

    next = ["one": 0]
    #expect(try getParam(["one": 1], "one", &next) as! Int == 1)
    #expect(next == ["one": 0])

    next = ["one": 1]
    #expect(try getParam(["one": 1], "one", &next) == nil)
    #expect(next == ["one": 1])

    next = ["one": 2]
    #expect(try getParam(["one": 1], "one", &next) == nil)
    #expect(next == ["one": 2])

    // Array tests
    next = [:]
    #expect(try getParam(["one": [1]], "one", &next) as! Int == 1)
    #expect(next.isEmpty)

    next = ["one": 0]
    #expect(try getParam(["one": [1]], "one", &next) as! Int == 1)
    #expect(next == ["one": 0])

    next = ["one": 1]
    #expect(try getParam(["one": [1]], "one", &next) == nil)
    #expect(next == ["one": 1])

    next = ["one": 2]
    #expect(try getParam(["one": [1]], "one", &next) == nil)
    #expect(next == ["one": 2])

    next = ["one": 0]
    #expect(try getParam(["one": [1, 2, 3]], "one", &next) as! Int == 1)
    #expect(next == ["one": 0])

    next = ["one": 1]
    #expect(try getParam(["one": [1, 2, 3]], "one", &next) as! Int == 2)
    #expect(next == ["one": 1])

    next = ["one": 2]
    #expect(try getParam(["one": [1, 2, 3]], "one", &next) as! Int == 3)
    #expect(next == ["one": 2])

    next = ["one": 3]
    #expect(try getParam(["one": [1, 2, 3]], "one", &next) == nil)
    #expect(next == ["one": 3])
  }

  @Test
  func sideEffects() throws {
    var next: [String: Int] = [:]
    #expect(try getParam(["one": 1], "one", &next, true) as! Int == 1)
    #expect(next == ["one": 1])

    next = ["one": 0]
    #expect(try getParam(["one": 1], "one", &next, true) as! Int == 1)
    #expect(next == ["one": 1])

    // Array tests
    next = [:]
    #expect(try getParam(["one": [1]], "one", &next, true) as! Int == 1)
    #expect(next == ["one": 1])

    next = ["one": 0]
    #expect(try getParam(["one": [1]], "one", &next, true) as! Int == 1)
    #expect(next == ["one": 1])

    next = ["one": 0]
    #expect(try getParam(["one": [1, 2, 3]], "one", &next, true) as! Int == 1)
    #expect(next == ["one": 1])

    next = ["one": 1]
    #expect(try getParam(["one": [1, 2, 3]], "one", &next, true) as! Int == 2)
    #expect(next == ["one": 2])

    next = ["one": 2]
    #expect(try getParam(["one": [1, 2, 3]], "one", &next, true) as! Int == 3)
    #expect(next == ["one": 3])
  }

  @Test
  func sideEffectsErrors() throws {
    // Test 1
    var next: [String: Int] = [:]
    do {
      _ = try getParam([:], "one", &next, true)
      #expect(Bool(false))
    } catch {
      #expect(error.localizedDescription == "no values provided for key `one`")
    }
    #expect(next.isEmpty)

    // Test 2
    next = ["one": 1]
    do {
      _ = try getParam(["one": 1], "one", &next, true)
      #expect(Bool(false))
    } catch {
      #expect(error.localizedDescription == "too few values provided for key `one`")
    }
    #expect(next == ["one": 1])

    // Test 3
    next = ["one": 2]
    do {
      _ = try getParam(["one": 2], "one", &next, true)
      #expect(Bool(false))
    } catch {
      #expect(error.localizedDescription == "too few values provided for key `one`")
    }
    #expect(next == ["one": 2])

    // Test 4
    next = ["one": 1]
    do {
      _ = try getParam(["one": [1]], "one", &next, true)
      #expect(Bool(false))
    } catch {
      #expect(error.localizedDescription == "too few values provided for key `one`")
    }
    #expect(next == ["one": 1])

    // Test 5
    next = ["one": 2]
    do {
      _ = try getParam(["one": [1]], "one", &next, true)
      #expect(Bool(false))
    } catch {
      #expect(error.localizedDescription == "too few values provided for key `one`")
    }
    #expect(next == ["one": 2])

    // Test 6
    next = ["one": 3]
    do {
      _ = try getParam(["one": [1, 2, 3]], "one", &next, true)
      #expect(Bool(false))
    } catch {
      #expect(error.localizedDescription == "too few values provided for key `one`")
    }
    #expect(next == ["one": 3])
  }
}
