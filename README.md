# SwiftURLPattern

[![CI](https://github.com/timi-wang/SwiftURLPattern/actions/workflows/swift.yml/badge.svg)](https://github.com/timi-wang/SwiftURLPattern/actions/workflows/swift.yml)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ftimi-wang%2FSwiftURLPattern%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/timi-wang/SwiftURLPattern)
[![Versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ftimi-wang%2FSwiftURLPattern%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/timi-wang/SwiftURLPattern)

The pure swift version of url-pattern, easy way to match urls and other strings.

## Simple usage

``` swift
// create pattern with string
let pattern = try URLPattern("/api/users(/:id)")

// match pattern against string and extract values
pattern.match("/api/users/10") // ["id": "10"]
pattern.match("/api/users") // [:]
pattern.match("/api/products/5") // nil

// generate string from pattern and values
pattern.stringify() // "/api/users"
pattern.stringify(["id": 20]) // "/api/users/20"
```

More complecate usages can check the **UsageExample** test file

## Make pattern from string

```swift
let pattern = try URLPattern("/api/users/:id");
```

a `pattern` is immutable after construction.
none of its methods changes its state.
that makes it easier to reason about.
if the pattern cannot be parsed, an error will be thrown

## Match pattern against string

match returns the extracted segments:

```swift
pattern.match("/api/users/10"); // ["id": "10"]
```

or `nil` if there was no match:

``` swift
pattern.match("/api/products/5"); // nil
```

patterns are compiled into regexes which makes `.match()` superfast.

## Named segments

`:id` (in the example above) is a named segment:

a named segment starts with `:` followed by the **name**.
the **name** must be at least one character in the regex character set `a-zA-Z0-9`.

when matching, a named segment consumes all characters in the regex character set
`a-zA-Z0-9-_~ %`.
a named segment match stops at `/`, `.`, ... but not at `_`, `-`, ` `, `%`...

[you can change these character sets. click here to see how.](#Customize-the-pattern-syntax)

if a named segment **name** occurs more than once in the pattern string,
and you want to match them all, you can use the `pattern.matchAll` function,
it will return an array with all matched results.
    
```swift
let pattern = try URLPattern("/api/users/:ids/posts/:ids")
pattern.matchAll("/api/users/10/posts/5") // ["ids": ["10", "5"]]
```

## Optional segments, wildcards and escaping

to make part of a pattern optional just wrap it in `(` and `)`:

```swift
let pattern = try URLPattern(
  "(http(s)\\://)(:subdomain.):domain.:tld(/*)"
)
```

note that `\\` escapes the `:` in `http(s)\\://`.
you can use `\\` to escape `(`, `)`, `:` and `*` which have special meaning within
URLPattern.

optional named segments are stored in the corresponding property only if they are present in the source string:

```swift
pattern.match("google.de")
// ["domain": "google", "tld": "de"]
```

```swift
pattern.match("https://www.google.com")
// ["subdomain": "www", "domain": "google", "tld": "com"]
```

`*` in patterns are wildcards and match anything.
wildcard matches are collected in the `_` property:

```swift
pattern.match("http://mail.google.com/mail");
// ["subdomain": "mail", "domain": "google", "tld": "com", "_": "mail"]
```

if there is more than one wildcard use matchAll to make `_` contains an array of matching strings.

[look at the tests for additional examples of `.match`](Tests/URLPatternTests/MatchFixtures.swift)

## Make pattern from regex

```swift
let pattern = try URLPattern(regex: "^\/api\/(.*)$");
```

if the pattern was created from a regex, a dict of the captured groups is returned with a key of the group index starts from "1"

```swift
pattern.match("/api/users") // ["1": "users"]
pattern.match("/apiii/test") // nil
```

when making a pattern from a regex
you can pass an array of keys as the second argument.
returns dict on match with each key mapped to a captured value:

```swift
let pattern = try URLPattern(
  regex: "^\/api\/([^\/]+)(?:\/(\d+))?$",
  ["resource", "id"]
)

pattern.match("/api/users") // ["resource": "users"]
pattern.match("/api/users/5") // ["resource": "users", "id": "5"]
pattern.match("/api/users/foo") // nil
```

## Stringify patterns

```swift
let pattern = try URLPattern("/api/users/:id")

pattern.stringify(["id": 10])
// "/api/users/10"
```

optional segments are only included in the output if they contain named segments
and/or wildcards and values for those are provided:

```swift
let pattern = try URLPattern("/api/users(/:id)")

pattern.stringify() // "/api/users"
pattern.stringify(["id": 10]) // "/api/users/10"

```

wildcards (key = `_`), deeply nested optional groups and multiple value arrays should stringify as expected.

if a value that is not in an optional group is not provided stringify will return nil

if an optional segment contains multiple params and not all of them are provided stringify will return nil
*one provided value for an optional segment makes all values in that optional segment required.*

[look at the tests for additional examples of `.stringify`](Tests/URLPatternTests/StringifyFixtures.swift)

## Customize the pattern syntax

of cause you can completely change pattern-parsing and regex-compilation to suit your needs:

```swift
var options = ParserOptions();
```

let's change the char used for escaping (default `\\`):

```swift
options.escapeChar = "!"
```

let's change the char used to start a named segment (default `:`):

```swift
options.segmentNameStartChar = "$"
```

let's change the set of chars allowed in named segment names (default `a-zA-Z0-9`)
to also include `_` and `-`:

```swift
options.segmentNameCharset = "a-zA-Z0-9_-"
```

let's change the set of chars allowed in named segment values
(default `a-zA-Z0-9-_~ %`) to not allow non-alphanumeric chars:

```swift
options.segmentValueCharset = "a-zA-Z0-9"
```

let's change the chars used to surround an optional segment (default `(` and `)`):

```swift
options.optionalSegmentStartChar = "["
options.optionalSegmentEndChar = "]"
```

let's change the char used to denote a wildcard (default `*`):

```swift
options.wildcardChar = "?"
```

pass options as the second argument to the constructor:

```swift
let pattern = try URLPattern(
  "[http[s]!://][$sub_domain.]$domain.$toplevel-domain[/?]",
  options
)
```

then match:

```swift
pattern.match("http://mail.google.com/mail")
/*
[
  "sub_domain": "mail",
  "domain": "google",
  "toplevel-domain": "com",
  "_": "mail"
]
 */
```

## [license: MIT](LICENSE)
