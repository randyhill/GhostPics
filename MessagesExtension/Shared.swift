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
    static let sharedInstance = Shared()

    // userdefult keys
    let kMessageCount = "kMessageCount"
    let kPurchaseActivated = "kActivated"
    let kWalkthrough = "kWalkthrough"

    // app data
    var imagesSentCount = 0
    var evaluationImageLimit = 20
    var activated = false
    var didWalkthrough = false

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

    class func backgroundColor(alpha: CGFloat) -> UIColor {
        return UIColor(red: 230/255.0, green: 230/255.0, blue: 230/255.0, alpha: alpha)
    }

    class func ghostBlue(alpha: CGFloat) -> UIColor {
        return UIColor(red: 30/255.0, green: 177/255.0, blue: 227/255.0, alpha: alpha)
    }

    class func attentionColor(alpha: CGFloat) -> UIColor {
        return UIColor(red: 30/255.0, green: 129/255.0, blue: 249/255.0, alpha: alpha) // messages blue
    }
    // return UIColor(red: 0x34/255.0, green: 0x98/255.0, blue: 0xDB/255.0, alpha: alpha) // Peter River
    // return UIColor(red: 0x34/255.0, green: 0x49/255.0, blue: 0x5e/255.0, alpha: alpha) // wetAsphalt
    //return UIColor(red: 0x83/255.0, green: 0x44/255.0, blue: 0xAD/255.0, alpha: alpha) //amathyst
    //        return UIColor(red: 0x9B/255.0, green: 0x59/255.0, blue: 0xB6/255.0, alpha: alpha)// wisteria
    // return UIColor(red: 0x29/255.0, green: 0x80/255.0, blue: 0xB9/255.0, alpha: 1.0) // belize hole

    init() {
        self.load()
    }

    func save() {
        let defaults = UserDefaults.standard
        defaults.set(imagesSentCount, forKey: kMessageCount)
        defaults.set(activated, forKey: kPurchaseActivated)
        defaults.set(didWalkthrough, forKey: kWalkthrough)
    }

    func load() {
        let defaults = UserDefaults.standard
        imagesSentCount = defaults.integer(forKey: kMessageCount)
        activated = defaults.bool(forKey: kPurchaseActivated)
        didWalkthrough = defaults.bool(forKey: kWalkthrough)
    }

}
