//
//  AboutController
//  GhostPics
//
//  Created by CRH on 9/13/16.
//  Copyright © 2016 CRH. All rights reserved.
//

import UIKit

class AboutController : UIViewController {
    @IBOutlet var bodyTextView : UITextView!
    @IBOutlet var doneButton : UIButton!
    @IBOutlet var emailButton : UIButton!

    let aboutHeader = "GhostPics is a secure way to send pictures to other iOS 10 users, the best part is they vanish after viewing! Using GhostPics is simple\n\n" +
        "1) Select a picture with the Pick Photo button\n" +
        "2) Choose any effect you want to display it with.\n" +
        "3) Send! It's that simple. Your recipient will only be able to open and view the image in GhostPics, and only once. It vanishes immediately after viewing.\n\n"
    let faqTitle = "Questions:\n"
    let faqText =  "Do recipients need iOS 10 to view my picture?\nYes, GhostPics is iOS 10 only for the moment, and this ensures that the security of your photos is maintained.\n"


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

        // Round corners
        bodyTextView.layer.cornerRadius = 8.0
        doneButton.layer.cornerRadius = 8.0
        emailButton.layer.cornerRadius = 8.0

//        bodyTextView.backgroundColor = Shared.ghostBlue(alpha: 1.0)
//        self.view.backgroundColor = Shared.ghostBlue(alpha: 1.0)
    }

    func textWithFontAttribute(text : String, font : UIFont) -> NSAttributedString {
        let textAttributes = [NSFontAttributeName: font]
        return NSAttributedString(string: text, attributes: textAttributes)
    }

    @IBAction func done(sender: UIButton) {
        self.dismiss(animated: true) { 

        }
    }
}
