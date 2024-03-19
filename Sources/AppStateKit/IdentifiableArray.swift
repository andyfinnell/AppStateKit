
public typealias IdentifiableArray<Element> = Array<Element> where Element: Identifiable

public extension IdentifiableArray {
    subscript(byID id: Element.ID) -> Element? {
        get {
            first(where: { $0.id == id })
        }
        set {
            guard let i = firstIndex(where: { $0.id == id }), let newValue else {
                return
            }
            self[i] = newValue
        }
    }
}
