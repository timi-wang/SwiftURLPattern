import Testing
@testable import URLPattern

func tagRes(_ tag: TagType, _ value: String, _ rest: String) -> Res {
  Res(rest, .tag(Tag(tag, .string(value))))
}

@Suite
struct ParserTests {
  let parser = Parser()

  @Test("Wildcard parsing")
  func testWildcard() throws {
    #expect(parser.wildcard("*") == tagRes(.wildcard, "*", ""))
    #expect(parser.wildcard("*/") == tagRes(.wildcard, "*", "/"))
    #expect(parser.wildcard(" *") == nil)
    #expect(parser.wildcard("()") == nil)
    #expect(parser.wildcard("foo(100)") == nil)
    #expect(parser.wildcard("(100foo)") == nil)
    #expect(parser.wildcard("(foo100)") == nil)
    #expect(parser.wildcard("(foobar)") == nil)
    #expect(parser.wildcard("foobar") == nil)
    #expect(parser.wildcard("_aa") == nil)
    #expect(parser.wildcard("$foobar") == nil)
    #expect(parser.wildcard("$") == nil)
    #expect(parser.wildcard("") == nil)
  }

  @Test("Named parsing")
  func testNamed() throws {
    #expect(parser.named(":a") == tagRes(.named, "a", ""))
    #expect(parser.named(":ab96c") == tagRes(.named, "ab96c", ""))
    #expect(parser.named(":ab96c.") == tagRes(.named, "ab96c", "."))
    #expect(parser.named(":96c-:ab") == tagRes(.named, "96c", "-:ab"))
    #expect(parser.named(":") == nil)
    #expect(parser.named("") == nil)
    #expect(parser.named("a") == nil)
    #expect(parser.named("abc") == nil)
  }

  @Test("normal parsing")
  func testNormal() throws {
    #expect(parser.normal("a") == tagRes(.normal, "a", ""))
    #expect(parser.normal("abc:d") == tagRes(.normal, "abc", ":d"))
    #expect(parser.normal(":ab96c") == nil)
    #expect(parser.normal(":") == nil)
    #expect(parser.normal("(") == nil)
    #expect(parser.normal(")") == nil)
    #expect(parser.normal("*") == nil)
    #expect(parser.normal("") == nil)
  }

  @Test("Pattern fixtures")
  func testFixtures() throws {
    let parse = parser.pattern

    #expect(parse("") == nil)
    #expect(parse("(") == nil)
    #expect(parse(")") == nil)
    #expect(parse("()") == nil)
    #expect(parse(":") == nil)
    #expect(parse("((foo)") == nil)
    #expect(parse("(((foo)bar(boo)far)") == nil)

    #expect(parse("(foo))") == Res(
      ")",
      .array([
        .tag(Tag(.optional, .array([.tag(Tag(.normal, .string("foo")))])))
      ])
    ))
    
    #expect(parse("((foo)))bar") == Res(
      ")bar",
      .array([
        .tag(Tag(.optional, .array([
          .tag(Tag(.optional, .array([.tag(Tag(.normal, .string("foo")))])))
        ])))
      ])
    ))
    
    #expect(parse("foo:*") == Res(
        ":*",
        .array([
            .tag(Tag(.normal, .string("foo")))
        ])
    ))

    #expect(parse(":foo:bar") == Res(
        "",
        .array([
            .tag(Tag(.named, .string("foo"))),
            .tag(Tag(.named, .string("bar")))
        ])
    ))

    #expect(parse("a") == Res(
        "",
        .array([
            .tag(Tag(.normal, .string("a")))
        ])
    ))

    #expect(parse("user42") == Res(
        "",
        .array([
            .tag(Tag(.normal, .string("user42")))
        ])
    ))

    #expect(parse(":a") == Res(
        "",
        .array([
            .tag(Tag(.named, .string("a")))
        ])
    ))

    #expect(parse("*") == Res(
        "",
        .array([
            .tag(Tag(.wildcard, .string("*")))
        ])
    ))

    #expect(parse("(foo)") == Res(
        "",
        .array([
            .tag(Tag(.optional, .array([
                .tag(Tag(.normal, .string("foo")))
            ])))
        ])
    ))

    #expect(parse("(:foo)") == Res(
        "",
        .array([
            .tag(Tag(.optional, .array([
                .tag(Tag(.named, .string("foo")))
            ])))
        ])
    ))

    #expect(parse("(*)") == Res(
        "",
        .array([
            .tag(Tag(.optional, .array([
                .tag(Tag(.wildcard, .string("*")))
            ])))
        ])
    ))

    #expect(parse("/api/users/:id") == Res(
        "",
        .array([
            .tag(Tag(.normal, .string("/api/users/"))),
            .tag(Tag(.named, .string("id")))
        ])
    ))

    #expect(parse("/v:major(.:minor)/*") == Res(
        "",
        .array([
            .tag(Tag(.normal, .string("/v"))),
            .tag(Tag(.named, .string("major"))),
            .tag(Tag(.optional, .array([
                .tag(Tag(.normal, .string("."))),
                .tag(Tag(.named, .string("minor")))
            ]))),
            .tag(Tag(.normal, .string("/"))),
            .tag(Tag(.wildcard, .string("*")))
        ])
    ))

    #expect(parse("(http(s)\\://)(:subdomain.):domain.:tld(/*)") == Res(
        "",
        .array([
            .tag(Tag(.optional, .array([
                .tag(Tag(.normal, .string("http"))),
                .tag(Tag(.optional, .array([
                    .tag(Tag(.normal, .string("s")))
                ]))),
                .tag(Tag(.normal, .string("://")))
            ]))),
            .tag(Tag(.optional, .array([
                .tag(Tag(.named, .string("subdomain"))),
                .tag(Tag(.normal, .string(".")))
            ]))),
            .tag(Tag(.named, .string("domain"))),
            .tag(Tag(.normal, .string("."))),
            .tag(Tag(.named, .string("tld"))),
            .tag(Tag(.optional, .array([
                .tag(Tag(.normal, .string("/"))),
                .tag(Tag(.wildcard, .string("*")))
            ])))
        ])
    ))

    #expect(parse("/api/users/:ids/posts/:ids") == Res(
        "",
        .array([
            .tag(Tag(.normal, .string("/api/users/"))),
            .tag(Tag(.named, .string("ids"))),
            .tag(Tag(.normal, .string("/posts/"))),
            .tag(Tag(.named, .string("ids")))
        ])
    ))

    #expect(parse("/user/:userId/task/:taskId") == Res(
        "",
        .array([
            .tag(Tag(.normal, .string("/user/"))),
            .tag(Tag(.named, .string("userId"))),
            .tag(Tag(.normal, .string("/task/"))),
            .tag(Tag(.named, .string("taskId")))
        ])
    ))

    #expect(parse(".user.:userId.task.:taskId") == Res(
        "",
        .array([
            .tag(Tag(.normal, .string(".user."))),
            .tag(Tag(.named, .string("userId"))),
            .tag(Tag(.normal, .string(".task."))),
            .tag(Tag(.named, .string("taskId")))
        ])
    ))

    #expect(parse("*/user/:userId") == Res(
        "",
        .array([
            .tag(Tag(.wildcard, .string("*"))),
            .tag(Tag(.normal, .string("/user/"))),
            .tag(Tag(.named, .string("userId")))
        ])
    ))

    #expect(parse("*-user-:userId") == Res(
        "",
        .array([
            .tag(Tag(.wildcard, .string("*"))),
            .tag(Tag(.normal, .string("-user-"))),
            .tag(Tag(.named, .string("userId")))
        ])
    ))

    #expect(parse("/admin*") == Res(
        "",
        .array([
            .tag(Tag(.normal, .string("/admin"))),
            .tag(Tag(.wildcard, .string("*")))
        ])
    ))

    #expect(parse("#admin*") == Res(
        "",
        .array([
            .tag(Tag(.normal, .string("#admin"))),
            .tag(Tag(.wildcard, .string("*")))
        ])
    ))

    #expect(parse("/admin/*/user/:userId") == Res(
        "",
        .array([
            .tag(Tag(.normal, .string("/admin/"))),
            .tag(Tag(.wildcard, .string("*"))),
            .tag(Tag(.normal, .string("/user/"))),
            .tag(Tag(.named, .string("userId")))
        ])
    ))

    #expect(parse("$admin$*$user$:userId") == Res(
        "",
        .array([
            .tag(Tag(.normal, .string("$admin$"))),
            .tag(Tag(.wildcard, .string("*"))),
            .tag(Tag(.normal, .string("$user$"))),
            .tag(Tag(.named, .string("userId")))
        ])
    ))

    #expect(parse("/admin/*/user/*/tail") == Res(
        "",
        .array([
            .tag(Tag(.normal, .string("/admin/"))),
            .tag(Tag(.wildcard, .string("*"))),
            .tag(Tag(.normal, .string("/user/"))),
            .tag(Tag(.wildcard, .string("*"))),
            .tag(Tag(.normal, .string("/tail")))
        ])
    ))

    #expect(parse("/admin/*/user/:id/*/tail") == Res(
        "",
        .array([
            .tag(Tag(.normal, .string("/admin/"))),
            .tag(Tag(.wildcard, .string("*"))),
            .tag(Tag(.normal, .string("/user/"))),
            .tag(Tag(.named, .string("id"))),
            .tag(Tag(.normal, .string("/"))),
            .tag(Tag(.wildcard, .string("*"))),
            .tag(Tag(.normal, .string("/tail")))
        ])
    ))

    #expect(parse("^admin^*^user^:id^*^tail") == Res(
        "",
        .array([
            .tag(Tag(.normal, .string("^admin^"))),
            .tag(Tag(.wildcard, .string("*"))),
            .tag(Tag(.normal, .string("^user^"))),
            .tag(Tag(.named, .string("id"))),
            .tag(Tag(.normal, .string("^"))),
            .tag(Tag(.wildcard, .string("*"))),
            .tag(Tag(.normal, .string("^tail")))
        ])
    ))

    #expect(parse("/*/admin(/:path)") == Res(
        "",
        .array([
            .tag(Tag(.normal, .string("/"))),
            .tag(Tag(.wildcard, .string("*"))),
            .tag(Tag(.normal, .string("/admin"))),
            .tag(Tag(.optional, .array([
                .tag(Tag(.normal, .string("/"))),
                .tag(Tag(.named, .string("path")))
            ])))
        ])
    ))

    #expect(parse("/") == Res(
        "",
        .array([
            .tag(Tag(.normal, .string("/")))
        ])
    ))

    #expect(parse("(/)") == Res(
        "",
        .array([
            .tag(Tag(.optional, .array([
                .tag(Tag(.normal, .string("/")))
            ])))
        ])
    ))

    #expect(parse("/admin(/:foo)/bar") == Res(
        "",
        .array([
            .tag(Tag(.normal, .string("/admin"))),
            .tag(Tag(.optional, .array([
                .tag(Tag(.normal, .string("/"))),
                .tag(Tag(.named, .string("foo")))
            ]))),
            .tag(Tag(.normal, .string("/bar")))
        ])
    ))

    #expect(parse("/admin(*/)foo") == Res(
        "",
        .array([
            .tag(Tag(.normal, .string("/admin"))),
            .tag(Tag(.optional, .array([
                .tag(Tag(.wildcard, .string("*"))),
                .tag(Tag(.normal, .string("/")))
            ]))),
            .tag(Tag(.normal, .string("foo")))
        ])
    ))

    #expect(parse("/v:major.:minor/*") == Res(
        "",
        .array([
            .tag(Tag(.normal, .string("/v"))),
            .tag(Tag(.named, .string("major"))),
            .tag(Tag(.normal, .string("."))),
            .tag(Tag(.named, .string("minor"))),
            .tag(Tag(.normal, .string("/"))),
            .tag(Tag(.wildcard, .string("*")))
        ])
    ))

    #expect(parse("/v:v.:v/*") == Res(
        "",
        .array([
            .tag(Tag(.normal, .string("/v"))),
            .tag(Tag(.named, .string("v"))),
            .tag(Tag(.normal, .string("."))),
            .tag(Tag(.named, .string("v"))),
            .tag(Tag(.normal, .string("/"))),
            .tag(Tag(.wildcard, .string("*")))
        ])
    ))

    #expect(parse("/:foo_bar") == Res(
        "",
        .array([
            .tag(Tag(.normal, .string("/"))),
            .tag(Tag(.named, .string("foo"))),
            .tag(Tag(.normal, .string("_bar")))
        ])
    ))

    #expect(parse("((((a)b)c)d)") == Res(
        "",
        .array([
            .tag(Tag(.optional, .array([
                .tag(Tag(.optional, .array([
                    .tag(Tag(.optional, .array([
                        .tag(Tag(.optional, .array([
                            .tag(Tag(.normal, .string("a")))
                        ]))),
                        .tag(Tag(.normal, .string("b")))
                    ]))),
                    .tag(Tag(.normal, .string("c")))
                ]))),
                .tag(Tag(.normal, .string("d")))
            ])))
        ])
    ))

    #expect(parse("/vvv:version/*") == Res(
        "",
        .array([
            .tag(Tag(.normal, .string("/vvv"))),
            .tag(Tag(.named, .string("version"))),
            .tag(Tag(.normal, .string("/"))),
            .tag(Tag(.wildcard, .string("*")))
        ])
    ))
  }
}
