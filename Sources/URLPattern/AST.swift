//
//  AST.swift
//  URLPattern
//
//  Created by timi on 2025/6/18.
//

import Foundation

func baseAstNodeToRegexString(_ astNode: TagValueType, _ segmentValueCharset: String) -> String {
  switch astNode {
  case .array(let arr):
    return stringConcatMap(arr) { v in
      baseAstNodeToRegexString(v, segmentValueCharset)
    }
  case .tag(let t):
    switch t.tag {
    case .normal:
      return baseAstNodeToRegexString(t.value, segmentValueCharset)
    case .named:
      return "([\(segmentValueCharset)]+)"
    case .optional:
      return "(?:" + baseAstNodeToRegexString(t.value, segmentValueCharset) + ")?"
    case .wildcard:
      return "(.*?)"
    }
  case .string(let s):
    return escapeForRegex(s)
  }
}

func astNodeToRegexString(
  _ astNode: TagValueType,
  _ segmentValueCharset: String = ParserOptions().segmentValueCharset
) -> String {
  return "^" + baseAstNodeToRegexString(astNode, segmentValueCharset) + "$"
}

func astNodeToNames(_ astNode: TagValueType) -> [String] {
  switch astNode {
  case .array(let arr):
    return arr.flatMap { astNodeToNames($0) }
  case .string(let s):
    return [s]
  case .tag(let t):
    switch t.tag {
    case .normal:
      return []
    case .named:
      return astNodeToNames(t.value)
    case .optional:
      return astNodeToNames(t.value)
    case .wildcard:
      return ["_"]
    }
  }
}

func getParam(
  _ params: [String: Any],
  _ key: String,
  _ nextIndexes: inout [String: Int],
  _ sideEffects: Bool = false
) throws -> Any? {
  guard let value = params[key] else {
    if sideEffects {
      throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "no values provided for key `\(key)`"])
    }
    return nil
  }

  let index = nextIndexes[key] ?? 0

  let maxIndex: Int
  if let array = value as? [Any] {
    maxIndex = array.count - 1
  } else {
    maxIndex = 0
  }

  if index > maxIndex {
    if sideEffects {
      throw NSError(
        domain: "",
        code: 0,
        userInfo: [NSLocalizedDescriptionKey: "too few values provided for key `\(key)`"]
      )
    }
    return nil
  }

  let result: Any
  if let array = value as? [Any] {
    result = array[index]
  } else {
    result = value
  }

  if sideEffects {
    nextIndexes[key] = index + 1
  }

  return result
}

func astNodeContainsSegmentsForProvidedParams(
  _ astNode: TagValueType,
  _ params: [String: Any],
  _ nextIndexes: [String: Int]
) -> Bool {
  switch astNode {
  case .array(let nodes):
    return nodes.contains { node in
      astNodeContainsSegmentsForProvidedParams(node, params, nextIndexes)
    }
  case .string(let s):
    var mutableIndexes = nextIndexes
    return (try? getParam(params, s, &mutableIndexes)) != nil
  case .tag(let t):
    switch t.tag {
    case .normal:
      return false
    case .named, .optional:
      return astNodeContainsSegmentsForProvidedParams(t.value, params, nextIndexes)
    case .wildcard:
      var mutableIndexes = nextIndexes
      return (try? getParam(params, "_", &mutableIndexes)) != nil
    }
  }
}

func stringifyAST(
  _ astNode: TagValueType,
  _ params: [String: Any],
  _ nextIndexes: inout [String: Int]
) throws -> String {
  switch astNode {
  case .array(let nodes):
    return try nodes.map { node in
      try stringifyAST(node, params, &nextIndexes)
    }.joined()
  case .string(let s):
    return s
  case .tag(let t):
    switch t.tag {
    case .normal:
      return try stringifyAST(t.value, params, &nextIndexes)
    case .named:
      if case .string(let key) = t.value {
        return try String(describing: getParam(params, key, &nextIndexes, true) ?? "")
      } else {
        return try stringifyAST(t.value, params, &nextIndexes)
      }
    case .optional:
      if astNodeContainsSegmentsForProvidedParams(t.value, params, nextIndexes) {
        return try stringifyAST(t.value, params, &nextIndexes)
      } else {
        return ""
      }
    case .wildcard:
      return try String(describing: getParam(params, "_", &nextIndexes, true) ?? "")
    }
  }
}
