import Testing

@testable import URLPattern

struct UsageExample {
  @Test
  func simplePattern() throws {
    let pattern = try! URLPattern("/api/users/:id")
    #expect(dictEqual(pattern.match("/api/users/10"), ["id": "10"]))
    #expect(pattern.match("/api/products/5") == nil)
  }

  @Test
  func apiVersioning() throws {
    let pattern = try! URLPattern("/v:major(.:minor)/*")
    #expect(dictEqual(pattern.match("/v1.2/"), ["major": "1", "minor": "2", "_": ""]))
    #expect(dictEqual(pattern.match("/v2/users"), ["major": "2", "_": "users"]))
    #expect(pattern.match("/v/") == nil)
  }

  @Test
  func domainPatterns() throws {
    let pattern = try! URLPattern("(http(s)\\://)(:subdomain.):domain.:tld(\\::port)(/*)")

    #expect(
      dictEqual(
        pattern.match("google.de"),
        [
          "domain": "google",
          "tld": "de",
        ]
      )
    )

    #expect(
      dictEqual(
        pattern.match("https://www.google.com"),
        [
          "subdomain": "www",
          "domain": "google",
          "tld": "com",
        ]
      )
    )

    #expect(
      dictEqual(
        pattern.match("http://mail.google.com/mail"),
        [
          "subdomain": "mail",
          "domain": "google",
          "tld": "com",
          "_": "mail",
        ]
      )
    )

    #expect(
      dictEqual(
        pattern.match("http://mail.google.com:80/mail"),
        [
          "subdomain": "mail",
          "domain": "google",
          "tld": "com",
          "port": "80",
          "_": "mail",
        ]
      )
    )

    #expect(pattern.match("google") == nil)
    #expect(
      dictEqual(
        pattern.match("www.google.com"),
        [
          "subdomain": "www",
          "domain": "google",
          "tld": "com",
        ]
      )
    )

    #expect(pattern.match("httpp://mail.google.com/mail") == nil)

    #expect(
      dictEqual(
        pattern.match("google.de/search"),
        [
          "domain": "google",
          "tld": "de",
          "_": "search",
        ]
      )
    )
  }

  @Test
  func repeatedNamedSegments() throws {
    let pattern = try! URLPattern("/api/users/:ids/posts/:ids")
    #expect(
      dictEqual(
        pattern.matchAll("/api/users/10/posts/5"),
        [
          "ids": ["10", "5"]
        ]
      )
    )
  }

  @Test
  func regexPatterns() throws {
    let pattern = try! URLPattern(regex: #"^\/api\/(.*)$"#)
    #expect(dictEqual(pattern.match("/api/users"), ["1": "users"]))
    #expect(pattern.match("/apiii/users") == nil)
  }

  @Test
  func regexWithGroupNames() throws {
    let pattern = try! URLPattern(regex: #"^\/api\/([^\/]+)(?:\/(\d+))?$"#, ["resource", "id"])
    #expect(
      dictEqual(
        pattern.match("/api/users"),
        [
          "resource": "users"
        ]
      )
    )
    #expect(pattern.match("/api/users/") == nil)
    #expect(
      dictEqual(
        pattern.match("/api/users/5"),
        [
          "resource": "users",
          "id": "5",
        ]
      )
    )
    #expect(pattern.match("/api/users/foo") == nil)
  }

  @Test
  func stringifyPatterns() throws {
    var pattern = try! URLPattern("/api/users/:id")
    #expect(pattern.stringify(["id": 10]) == "/api/users/10")

    pattern = try! URLPattern("/api/users(/:id)")
    #expect(pattern.stringify() == "/api/users")
    #expect(pattern.stringify(["id": 10]) == "/api/users/10")
  }

  @Test
  func customPatternOptions() throws {
    let options = ParserOptions(
      escapeChar: "!",
      segmentNameStartChar: "$",
      segmentValueCharset: "a-zA-Z0-9",
      segmentNameCharset: "a-zA-Z0-9_-",
      optionalSegmentStartChar: "[",
      optionalSegmentEndChar: "]",
      wildcardChar: "?"
    )

    let pattern = try! URLPattern(
      "[http[s]!://][$sub_domain.]$domain.$toplevel-domain[/?]",
      options
    )

    #expect(
      dictEqual(
        pattern.match("google.de"),
        [
          "domain": "google",
          "toplevel-domain": "de",
        ]
      )
    )

    #expect(
      dictEqual(
        pattern.match("http://mail.google.com/mail"),
        [
          "sub_domain": "mail",
          "domain": "google",
          "toplevel-domain": "com",
          "_": "mail",
        ]
      )
    )

    #expect(pattern.match("http://mail.this-should-not-match.com/mail") == nil)
    #expect(pattern.match("google") == nil)

    #expect(
      dictEqual(
        pattern.match("www.google.com"),
        [
          "sub_domain": "www",
          "domain": "google",
          "toplevel-domain": "com",
        ]
      )
    )

    #expect(
      dictEqual(
        pattern.match("https://www.google.com"),
        [
          "sub_domain": "www",
          "domain": "google",
          "toplevel-domain": "com",
        ]
      )
    )

    #expect(pattern.match("httpp://mail.google.com/mail") == nil)

    #expect(
      dictEqual(
        pattern.match("google.de/search"),
        [
          "domain": "google",
          "toplevel-domain": "de",
          "_": "search",
        ]
      )
    )
  }
}
