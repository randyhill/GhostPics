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
let cUploadURL = "https://ghostpics.herokuapp.com/upload"
let cDownloadURL = "https://ghostpics.herokuapp.com/download/"
let cFileExistsURL = "https://ghostpics.herokuapp.com/exists/"
#endif

class ServerManager {
    static let sharedInstance = ServerManager()
    let defaultSession = URLSession(configuration: URLSessionConfiguration.default)

    init() {

    }

    func uploadFile(_ imageData: NSData, progress : @escaping (Float)->(), completion : @escaping (_ fileName: String?)->()) {
        let startTime = Date()
        if var fileId = Just.post(cUploadURL, files: ["image" : .data("image.jpg", imageData as Data, nil)], asyncProgressHandler: {(p) in
            print("Bytes: \(p.bytesProcessed) Expected: \(p.bytesExpectedToProcess) Percent: \(p.percent) Seconds: \(Date().timeIntervalSince(startTime))")
           // progress(p.percent)
        }).text {
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

    func downloadFile(path : String, progress : @escaping (Float)->(), completion : @escaping (_ data : Data?, _ error: String?)->()) {
        let startTime = Date()
       _ = Just.get(path, params: [:], asyncProgressHandler: {(p) in
            print("Bytes: \(p.bytesProcessed) Expected: \(p.bytesExpectedToProcess) Percent: \(p.percent) Seconds: \(Date().timeIntervalSince(startTime))")
            progress(p.percent)
        }) { (result) in
            print("dowwnload file returned")
            if let code = result?.statusCode, code == 200   {
                if let data = result?.content {
                    return completion(data, nil)
                } else {
                    return completion(nil, "That image has vanished")
                }
            } else {
                if let error = result?.error {
                    return completion(nil, error.description)
                } else {
                    return completion(nil, "That image has vanished")
                }
            }
        }
    }
}
