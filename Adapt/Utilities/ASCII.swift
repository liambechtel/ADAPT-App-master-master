extension String {
    func asciiValueOfString() -> [UInt32] {
        
        var retVal = [UInt32]()
        for val in self.unicodeScalars {
            retVal.append(UInt32(val))
        }
        return retVal
    }
    }
