//
//  Globals.swift
//  GhostPics
//
//  Created by CRH on 9/6/16.
//  Copyright © 2016 CRH. All rights reserved.
//

import UIKit

extension UIViewController {
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    func showQuestionAlert(title: String, question: String, okTitle: String, cancelTitle: String, completion: @escaping (Bool)->()) {
        let alert = UIAlertController(title: title, message: question, preferredStyle: .alert)
        let ok = UIAlertAction(title: okTitle, style: .default) { (action) in
            completion(true)
        }
        alert.addAction(ok)
        let cancel = UIAlertAction(title: cancelTitle, style: .default) { (action) in
            completion(false)
        }
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: {
        })
    }
}

class Shared {
    let kMessageCount = "kMessageCount"
    let kPurchaseActivated = "kActivated"
    static let sharedInstance = Shared()

    var imagesSentCount = 0
    var evaluationImageLimit = 10
    var activated = false

    class func postNotification(name : String, userInfo: [String: Any]?, object: AnyObject?) {
        let notificationQ = NotificationCenter.default
        let theNotification = NSNotification(name: NSNotification.Name(rawValue: name), object: object, userInfo: userInfo)
        notificationQ.post(theNotification as Notification)
    }

    class func postTransactions(name : String, productKeys: [String]) {
        let notificationQ = NotificationCenter.default
        let theNotification = NSNotification(name: NSNotification.Name(rawValue: name), object: productKeys, userInfo: nil)
        notificationQ.post(theNotification as Notification)
    }

    init() {
        self.load()
    }

    func save() {
        let defaults = UserDefaults.standard
        defaults.set(imagesSentCount, forKey: kMessageCount)
        defaults.set(activated, forKey: kPurchaseActivated)
    }

    func load() {
        let defaults = UserDefaults.standard
        imagesSentCount = defaults.integer(forKey: kMessageCount)
        activated = defaults.bool(forKey: kPurchaseActivated)
    }

}
