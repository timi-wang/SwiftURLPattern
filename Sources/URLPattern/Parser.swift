import RegexBuilder
import Foundation

struct Res: Equatable {
  static func == (lhs: Res, rhs: Res) -> Bool {
    return lhs.rest == rhs.rest && P.valueEqual(lhs.value, rhs.value)
  }
  
  var rest: String
  var value: TagValueType
  
  init(_ rest: String, _ value: TagValueType) {
    self.rest = rest
    self.value = value
  }
}

struct Tag: Equatable {
  static func == (lhs: Tag, rhs: Tag) -> Bool {
    return lhs.tag == rhs.tag && P.valueEqual(lhs.value, rhs.value)
  }
  
  var tag: TagType
  var value: TagValueType
  
  init(_ tag: TagType, _ value: TagValueType) {
    self.tag = tag
    self.value = value
  }
}

enum TagType: String {
  case normal = "normal"
  case named = "named"
  case optional = "optional"
  case wildcard = "wildcard"
}

indirect enum TagValueType {
  case string(String)
  case tag(Tag)
  case array([TagValueType])
}

typealias ParserFunc = (String) -> Res?

enum P {
  static func valueEqual(_ v1: TagValueType, _ v2: TagValueType) -> Bool {
    switch (v1, v2) {
    case (.string(let a), .string(let b)):
      if a == b { return true }
    case (.tag(let a), .tag(let b)):
      if a == b { return true }
    case (.array(let a), .array(let b)):
      if a.elementsEqual(b, by: P.valueEqual) { return true }
    default:
      return false
    }
    return false
  }
  
  // 给解析结果打标签
  static func tag(_ tag: TagType, _ parser: @escaping ParserFunc) -> ParserFunc {
    return { input in
      guard let result = parser(input) else { return nil }
      return Res(result.rest, .tag(Tag(tag, result.value)))
    }
  }
  
  // 用正则匹配
  static func regex(_ pattern: String) -> ParserFunc {
    return { input in
      guard let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)) else {
        return nil
      }
              
      let matchEnd = match.range.location + match.range.length
      let remainingStartIndex = String.Index(utf16Offset: matchEnd, in: input)
      let rest = String(input[remainingStartIndex...])
      let str = (input as NSString).substring(with: match.range)
      return Res(rest, .string(str))
    }
  }
  
  // 用字符串匹配
  static func string(_ str: String) -> ParserFunc {
    return { input in
      guard input.hasPrefix(str) else { return nil }
      return Res(String(input.dropFirst(str.count)), .string(str))
    }
  }
  
  // 延迟解析（用于递归结构）
  static func lazy(_ fn: @escaping () -> ParserFunc) -> ParserFunc {
    var cached: ParserFunc?
    return { input in
      if cached == nil {
        cached = fn()
      }
      return cached?(input)
    }
  }
  
  // 按顺序解析多个部分
  static func sequence(_ parsers: [ParserFunc]) -> ParserFunc {
    return { input in
      var values: [TagValueType] = []
      var rest = input
      for parser in parsers {
        guard let result = parser(rest) else { return nil }
        values.append(result.value)
        rest = result.rest
      }
      return Res(rest, .array(values))
    }
  }
  
  // 返回sequence的指定index的结果
  static func pick(_ index: Int, _ parsers: [ParserFunc]) -> ParserFunc {
    return { input in
      guard let result = P.sequence(parsers)(input) else { return nil }
      guard case .array(let array) = result.value, array.indices.contains(index) else { return nil }
      return Res(result.rest, array[index])
    }
  }
  
  static func baseMany(
    _ parser: @escaping ParserFunc,
    end: ParserFunc? = nil,
    input: String
  ) -> Res? {
    var rest = input
    var results: [TagValueType] = []
    while true {
      if end?(rest) != nil {
        break
      }
      
      guard let parserResult = parser(rest) else {
        break
      }
      
      results.append(parserResult.value)
      rest = parserResult.rest
    }
    if results.isEmpty {
      return nil
    }
    return Res(rest, .array(results))
  }
  
  // 匹配一次或多次
  static func many1(_ parser: @escaping ParserFunc) -> ParserFunc {
    return { input in
      return P.baseMany(parser, input: input)
    }
  }
  
  // 匹配一次或多次直到end
  static func concatMany1Till(_ parser: @escaping ParserFunc, _ end: @escaping ParserFunc) -> ParserFunc {
    return { input in
      guard let res = P.baseMany(parser, end: end, input: input) else { return nil }
      guard case .array(let results) = res.value else { return nil }
      var value = ""
      for r in results {
        guard case .string(let string) = r else { return nil }
        value += string
      }
      return Res(res.rest, .string(value))
    }
  }
  
  // 尝试多个解析器，返回第一个成功的
  static func firstChoice(_ parsers: [ParserFunc]) -> ParserFunc {
    return { input in
      for parser in parsers {
        if let result = parser(input) {
          return result
        }
      }
      return nil
    }
  }
}

public struct ParserOptions {
  public var escapeChar: String
  public var segmentNameStartChar: String
  public var segmentValueCharset: String
  public var segmentNameCharset: String
  public var optionalSegmentStartChar: String
  public var optionalSegmentEndChar: String
  public var wildcardChar: String
  
  public init(
    escapeChar: String = "\\",
    segmentNameStartChar: String = ":",
//    segmentValueCharset: String = "a-zA-Z0-9-_~ %@\\.:",
    segmentValueCharset: String = "a-zA-Z0-9-_~ %",
    segmentNameCharset: String = "a-zA-Z0-9",
    optionalSegmentStartChar: String = "(",
    optionalSegmentEndChar: String = ")",
    wildcardChar: String = "*"
  ) {
    self.escapeChar = escapeChar // 转义字符
    self.segmentNameStartChar = segmentNameStartChar // 命名参数start
    self.segmentValueCharset = segmentValueCharset // 普通文本
    self.segmentNameCharset = segmentNameCharset // 命名参数名
    self.optionalSegmentStartChar = optionalSegmentStartChar // 可选片段start
    self.optionalSegmentEndChar = optionalSegmentEndChar // 可选片段end
    self.wildcardChar = wildcardChar // 通配符
  }
}

public class Parser {
  var pattern: ParserFunc
  var wildcard: ParserFunc
  var optional: ParserFunc
  var name: ParserFunc
  var named: ParserFunc
  var escapedChar: ParserFunc
  var normal: ParserFunc
  var token: ParserFunc
  
  public init(_ options: ParserOptions = ParserOptions()) {
    var pattern: ParserFunc = { input in return nil }
    
    let wildcard = P.tag(.wildcard, P.string(options.wildcardChar));
    
    let optional = P.tag(
      .optional,
      P.pick(1, [
        P.string(options.optionalSegmentStartChar),
        P.lazy({ pattern }),
        P.string(options.optionalSegmentEndChar)
      ]))
    
    let name = P.regex("^[\(options.segmentNameCharset)]+")
    let named = P.tag(
      .named,
      P.pick(1, [
        P.string(options.segmentNameStartChar),
        P.lazy({ name })
      ])
    )
    
    let escapedChar = P.pick(1, [
      P.string(options.escapeChar),
      P.regex("^.")
    ])
    
    let normal = P.tag(
      .normal,
      P.concatMany1Till(
        P.firstChoice([
          P.lazy({ escapedChar }),
          P.regex("^.")
        ]),
        P.firstChoice([
          P.string(options.segmentNameStartChar),
          P.string(options.optionalSegmentStartChar),
          P.string(options.optionalSegmentEndChar),
          wildcard
        ])
      )
    )
    
    let token = P.lazy({ P.firstChoice([
      wildcard,
      optional,
      named,
      normal
    ]) })
    
    pattern = P.many1(P.lazy({ token }))
    
    self.pattern = pattern
    self.wildcard = wildcard
    self.optional = optional
    self.name = name
    self.named = named
    self.escapedChar = escapedChar
    self.normal = normal
    self.token = token
  }
}
