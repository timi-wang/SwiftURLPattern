import RegexBuilder
import Foundation

public class URLPattern {
  let ast: TagValueType?
  let regex: NSRegularExpression
  let names: [String]
  
  public init(_ pattern: URLPattern) {
    self.names = pattern.names
    self.regex = pattern.regex
    self.ast = pattern.ast
  }
  
  public init(regex pattern: String, _ names: [String] = []) throws {
    self.ast = nil
    self.regex = try NSRegularExpression(pattern: pattern)
    let groupCount = regexGroupCount(pattern);
    if !names.isEmpty {
      if names.count != groupCount {
        throw NSError(
          domain: "",
          code: 0,
          userInfo: [NSLocalizedDescriptionKey: "regex contains \(groupCount) groups but array of group names contains \(names.count)"]
        )
      }
      self.names = names
    } else {
      self.names = groupCount >= 1 ? (1...groupCount).map { "\($0)" } : []
    }
  }
  
  public init(_ pattern: String, _ options: ParserOptions = ParserOptions()) throws {
    if pattern.isEmpty {
      throw NSError(
        domain: "",
        code: 0,
        userInfo: [NSLocalizedDescriptionKey: "argument must not be the empty string"]
      )
    }
    
    let patternTrim = pattern.replacingOccurrences(of: " ", with: "")
    if patternTrim != pattern {
      throw NSError(
        domain: "",
        code: 0,
        userInfo: [NSLocalizedDescriptionKey: "argument must not contain whitespace"]
      )
    }
    
    let parser = Parser(options)
    guard let parsed = parser.pattern(patternTrim) else {
      throw NSError(
        domain: "",
        code: 0,
        userInfo: [NSLocalizedDescriptionKey: "couldn't parse pattern"]
      )
    }
    if !parsed.rest.isEmpty {
      throw NSError(
        domain: "",
        code: 0,
        userInfo: [NSLocalizedDescriptionKey: "could only partially parse pattern"]
      )
    }
    
    self.ast = parsed.value
    self.regex = try NSRegularExpression(pattern: astNodeToRegexString(parsed.value, options.segmentValueCharset))
    self.names = astNodeToNames(parsed.value)
  }
  
  public func matchAll(_ url: String) -> [String: [String]]? {
    guard let match = self.regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)) else { return nil }
    var values: [String?] = []
    for i in 1..<match.numberOfRanges {
      if let groupRange = Range(match.range(at: i), in: url) {
        values.append(String(url[groupRange]))
      } else {
        values.append(nil)
      }
    }
    return keysAndValuesToObject(keys: self.names, values: values)
  }
  
  public func match(_ url: String) -> [String: String]? {
    guard let matches = self.matchAll(url) else { return nil }
    var res: [String: String] = [:]
    for (k, v) in matches {
      if !v.isEmpty, let first = v.first {
        res[k] = first
      }
    }
    return res
  }
  
  public func stringify(_ params: [String: Any] = [:]) -> String? {
    guard let ast else { return nil }
    
    var next: [String: Int] = [:]
    do {
      return try stringifyAST(ast, params, &next)
    } catch {
      print(error.localizedDescription)
    }
    return nil
  }
}
