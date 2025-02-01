public extension Array {
    subscript(safetyDance index: Int) -> Element? {
        get {
            guard index >= startIndex && index < endIndex else {
                return nil
            }
            return self[index]
        }
        set {
            guard index >= startIndex && index < endIndex, let newValue else {
                return
            }
            self[index] = newValue
        }
    }
}
