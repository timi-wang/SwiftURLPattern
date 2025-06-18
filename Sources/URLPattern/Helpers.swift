//
//  Helpers.swift
//  URLPattern
//
//  Created by timi on 2025/6/16.
//
import Foundation

// helpers

func escapeForRegex(_ string: String) -> String {
  let specialCharacters = ["\\", "/", "^", "$", "*", "+", "?", ".", "(", ")", "[", "]", "{", "}", "|", "-"]
      var result = ""
      
      for char in string {
          if specialCharacters.contains(String(char)) {
              result.append("\\\(char)")
          } else {
              result.append(char)
          }
      }
      
      return result
}

func concatMap<T, U>(_ array: [T], _ f: (T) -> [U]) -> [U] {
  return array.flatMap(f)
}

func stringConcatMap<T>(_ array: [T], _ transform: (T) -> String) -> String {
  return array.map(transform).joined()
}

func regexGroupCount(_ pattern: String) -> Int {
  do {
    let regex = try NSRegularExpression(pattern: pattern)
    return regex.numberOfCaptureGroups
  } catch {
    print("Invalid regex pattern: \(pattern)")
    return 0
  }
}

func keysAndValuesToObject(keys: [String], values: [String?]) -> [String: [String]] {
  var object: [String: [String]] = [:]
  
  for i in 0..<keys.count {
    let key = keys[i]
    
    if values.indices.contains(i), let v = values[i] {
      if object[key] == nil {
        object[key] = []
      }
      object[key]?.append(v)
    }
  }
  
  return object
//  var res: [String: Any] = [:]
//  for (key, value) in object {
//    if value.isEmpty { continue }
//    if value.count == 1 {
//      res[key] = value[0]
//    } else {
//      res[key] = value
//    }
//  }
//  
//  return res
}
