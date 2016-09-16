//
//  AboutController
//  GhostPics
//
//  Created by CRH on 9/13/16.
//  Copyright © 2016 CRH. All rights reserved.
//

import UIKit
import MessageUI

class AboutController : UIViewController, MFMailComposeViewControllerDelegate {
    @IBOutlet var bodyTextView : UITextView!
    @IBOutlet var doneButton : UIButton!
    @IBOutlet var emailButton : UIButton!
    @IBOutlet var restoreButton : UIButton!

    let aboutHeader = "GhostPics is a secure way to send pictures to other iOS 10 users, the best part is they vanish after viewing! Using GhostPics is simple\n\n" +
        "1) Select a picture with the Pick Photo button\n" +
        "2) Choose any effect you want to display it with.\n" +
        "3) Send! It's that simple. Your recipient will only be able to open and view the image in GhostPics, and only once. It vanishes immediately after viewing.\n\n"
    let faqTitle = "Questions:\n"
    let faqText =  "Do recipients need iOS 10 to view my picture?\nYes, GhostPics is iOS 10 only for the moment, and this ensures that the security of your photos is maintained.\n"

    var delegate : MessagesViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Prepare text for scroll view
        let bodyText = NSMutableAttributedString()
        let bodyFont = UIFont.systemFont(ofSize: 14)
        let titleFont = UIFont.boldSystemFont(ofSize: 16)
        bodyText.append(textWithFontAttribute(text: aboutHeader, font: bodyFont))
        bodyText.append(textWithFontAttribute(text: faqTitle, font: titleFont))
        bodyText.append(textWithFontAttribute(text: faqText, font: bodyFont))
        bodyTextView.attributedText = bodyText
        bodyTextView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)

        // Round corners
        bodyTextView.layer.cornerRadius = 8.0
        doneButton.layer.cornerRadius = 8.0
        emailButton.layer.cornerRadius = 8.0
        restoreButton.layer.cornerRadius = 8.0
    }

    func textWithFontAttribute(text : String, font : UIFont) -> NSAttributedString {
        let textAttributes = [NSFontAttributeName: font]
        return NSAttributedString(string: text, attributes: textAttributes)
    }
    // MARK: Actions -------------------------------------------------------------------------------------------------

    @IBAction func done(sender: UIButton) {
        self.dismiss(animated: true) {
            self.delegate?.aboutScreen = nil
        }
    }

    @IBAction func restorePurchases(sender: UIButton) {
        self.dismiss(animated: true) {
            StoreManager.sharedInstance.restorePurchases()
        }
    }

    // MARK: Email -------------------------------------------------------------------------------------------------

    @IBAction func sendEmail(sender: UIButton) {
        let mailComposeViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }

    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property

        mailComposerVC.setToRecipients(["ghostpics@nvariance.com"])
        mailComposerVC.setSubject("Feedback on Ghost Pics")
        mailComposerVC.setMessageBody("", isHTML: false)
        return mailComposerVC
    }

    func showSendMailErrorAlert() {
        self.showAlert(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.")
    }

    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
