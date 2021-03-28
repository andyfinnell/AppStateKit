import Foundation

public protocol Extractable {
    func extract<T>(_ c: (T) -> Self) -> T?
    static func extractor<T>(_ c: @escaping (T) -> Self) -> (Self) -> T?
}

public extension Extractable {
    func extract<T>(_ c: (T) -> Self) -> T? {
        AppStateKit.extract(c, from: self)
    }
    
    static func extractor<T>(_ c: @escaping (T) -> Self) -> (Self) -> T? {
        { $0.extract(c) }
    }
}

fileprivate func extractCase<Enum, T>(_ e: Enum, as type: T.Type) -> (String, T)? {
    let enumMirror = Mirror(reflecting: e)
    guard enumMirror.children.count > 0 else {
        return nil
    }
    let valueChild = enumMirror.children.first
    guard let value = valueChild?.value as? T, let label = valueChild?.label else {
        return nil
    }
    return (label, value)
}

fileprivate func extract<Enum, T>(_ c: (T) -> Enum, from e: Enum) -> T? {
    guard let (label, value) = extractCase(e, as: T.self) else {
        return nil
    }
    // Apply the enum constructor and see if it matches
    guard let (caseLabel, _) = extractCase(c(value), as: T.self),
          caseLabel == label else {
        return nil
    }
    
    return value
}
