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
let cFileExistsURL = "http://localhost:8080/exists/"
#else
let cUploadURL = "https://protected-ridge-16932.herokuapp.com/upload"
let cDownloadURL = "https://protected-ridge-16932.herokuapp.com/download/"
let cFileExistsURL = "https://protected-ridge-16932.herokuapp.com/exists/"
#endif

class ServerManager {
    static let sharedInstance = ServerManager()
    let defaultSession = URLSession(configuration: URLSessionConfiguration.default)

    init() {

    }

    func uploadFile(_ image: UIImage, completion : @escaping (_ fileName: String?)->()) {
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

    func fileExists(url : URL, completion : @escaping (_ success : Bool)->()) {
        let path = cFileExistsURL + url.lastPathComponent
        _ = Just.get(path, params: [:]) { (result) in
            print("file exists returned: \(result!.statusCode)")
            if let code = result?.statusCode, code == 200   {
                return completion(true)
            } else {
                return completion(false)
            }
        }
    }

    func downloadFile(path : String, completion : @escaping (_ image : UIImage?, _ error: String?)->()) {
        _ = Just.get(path, params: [:]) { (result) in
            print("dowwnload file returned")
            if let code = result?.statusCode, code == 200   {
                if let data = result?.content, let image = UIImage(data: data)  {
                    return completion(image, nil)
                } else {
                    return completion(nil, "That image appears to have expired")
                }
            } else {
                if let error = result?.error {
                    return completion(nil, error.description)
                } else {
                    return completion(nil, "That image appears to have expired")
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
