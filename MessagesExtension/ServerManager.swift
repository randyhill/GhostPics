//
//  ServerManager
//  FieldTasksApp
//
//  Created by CRH on 8/19/16.
//  Copyright © 2016 CRH. All rights reserved.
//

import Foundation
import UIKit

#if LOCAL
let cUploadURL = "http://localhost:8080/upload"
let cDownloadURL = "http://localhost:8080/download/"
#else
let cUploadURL = "https://protected-ridge-16932.herokuapp.com/upload"
let cDownloadURL = "https://protected-ridge-16932.herokuapp.com/download/"
#endif

class ServerManager {
    static let sharedInstance = ServerManager()
    let defaultSession = URLSession(configuration: URLSessionConfiguration.default)

    init() {

    }

    func saveFile(_ image: UIImage, completion : @escaping (_ fileName: String?)->()) {
        if let imageData = UIImageJPEGRepresentation(image, 1) {
            if var fileId = Just.post(cUploadURL, files: ["image" : .data("image.jpg", imageData, nil)]).text {
                // fileId string should be 12 characters, plus quotes
                if fileId.characters.count > 12 {
                    // Remove quotes
                    fileId.remove(at: fileId.index(before: fileId.endIndex))
                    fileId.remove(at: fileId.startIndex)
                    print(fileId)
                    completion(fileId)
                } else {
                    completion(nil)
                }
            }
        }
    }
}

//
//extension NSMutableData {
//    func appendString(_ string : String) {
//        string.withCString {
//            self.append($0, length: Int(strlen($0)) + 1)
//        }
//    }
//}
