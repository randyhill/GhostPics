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

    let aboutHeader = "Use GhostPics to securely send private pictures to other iOS 10 users, and they vanish after viewing!\n\n" +
        "Simply\n\n" +
        "1) Select a picture with the Pick Photo button or take a new one with Camera button\n\n" +
        "2) Choose any effect you want recipient to see it with.\n\n" +
        "3) Send!\n\nIt's that simple. Your recipient will only be able to open and view the picture only once. It vanishes immediately after viewing!\n\n"
//    let faqTitle = "Questions:\n"
//    let faqText =  "Do recipients need iOS 10 to view my picture?\nYes, GhostPics is iOS 10 only for the moment, and this ensures the security of your photos are maintained.\n"

    var delegate : MessagesViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Prepare text for scroll view
        let bodyText = NSMutableAttributedString()
        let bodyFont = UIFont.systemFont(ofSize: 14)
        bodyText.append(textWithFontAttribute(text: aboutHeader, font: bodyFont))
        bodyTextView.attributedText = bodyText

        // Round corners
        bodyTextView.layer.cornerRadius = 8.0
        doneButton.layer.cornerRadius = 8.0
        emailButton.layer.cornerRadius = 8.0
        restoreButton.layer.cornerRadius = 8.0

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Fit to content
        let fixedWidth = bodyTextView.frame.size.width
        bodyTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        let newSize = bodyTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        var newFrame = bodyTextView.frame
        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        bodyTextView.frame = newFrame;
        bodyTextView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
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
            //self.addChildViewController(mailComposeViewController)
            //self.view.addSubview(mailComposeViewController.view)

//            mailComposeViewController.view.translatesAutoresizingMaskIntoConstraints = false
//
//            mailComposeViewController.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
//            mailComposeViewController.view.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
//            mailComposeViewController.view.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant: 80).isActive = true
//            mailComposeViewController.view.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor, constant: -40).isActive = true

            //mailComposeViewController.didMove(toParentViewController: self)
            self.present(mailComposeViewController, animated: true, completion: {
                mailComposeViewController.view.frame.size.height -= 100
                mailComposeViewController.view.frame.origin.y += 100
            })
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
