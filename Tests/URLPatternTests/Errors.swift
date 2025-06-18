import Foundation
import Testing

@testable import URLPattern

struct ErrorsTests {
  @Test
  func invalidArgument() throws {
    do {
      _ = try URLPattern("")
      #expect(Bool(false))
    } catch {
      #expect(error.localizedDescription == "argument must not be the empty string")
    }

    do {
      _ = try URLPattern(" ")
      #expect(Bool(false))
    } catch {
      #expect(error.localizedDescription == "argument must not contain whitespace")
    }

    do {
      _ = try URLPattern(" fo o")
      #expect(Bool(false))
    } catch {
      #expect(error.localizedDescription == "argument must not contain whitespace")
    }
  }

  @Test
  func invalidVariableNameInPattern() throws {
    do {
      _ = try URLPattern(":")
      #expect(Bool(false))
    } catch {
      #expect(error.localizedDescription == "couldn't parse pattern")
    }

    do {
      _ = try URLPattern(":.")
      #expect(Bool(false))
    } catch {
      #expect(error.localizedDescription == "couldn't parse pattern")
    }

    do {
      _ = try URLPattern("foo:.")
      #expect(Bool(false))
    } catch {
      #expect(error.localizedDescription == "could only partially parse pattern")
    }
  }

  @Test
  func tooManyClosingParentheses() throws {
    do {
      _ = try URLPattern(")")
      #expect(Bool(false))
    } catch {
      #expect(error.localizedDescription == "couldn't parse pattern")
    }

    do {
      _ = try URLPattern("((foo)))bar")
      #expect(Bool(false))
    } catch {
      #expect(error.localizedDescription == "could only partially parse pattern")
    }
  }

  @Test
  func unclosedParentheses() throws {
    do {
      _ = try URLPattern("(")
      #expect(Bool(false))
    } catch {
      #expect(error.localizedDescription == "couldn't parse pattern")
    }

    do {
      _ = try URLPattern("(((foo)bar(boo)far")
      #expect(Bool(false))
    } catch {
      #expect(error.localizedDescription == "couldn't parse pattern")
    }
  }
  
  @Test
  func stringifyRegex() throws {
    let pattern = try! URLPattern(regex: "x")
    #expect(pattern.stringify() == nil)
  }
}
