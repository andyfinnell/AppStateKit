import Foundation

extension String {    
    func lowercasedFirstWord() -> String {
        var prefixCount = 0
        var i = startIndex
        while i < endIndex, self[i].isLetter, self[i].isUppercase {
            prefixCount += 1
            i = index(after: i)
        }
        
        let firstWord = self[startIndex..<i].lowercased()
        let remaining = dropFirst(prefixCount)
        return firstWord + remaining
    }
}
