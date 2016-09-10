//
//  MessagesViewController.swift
//  MessagesExtension
//
//  Created by CRH on 8/29/16.
//  Copyright © 2016 CRH. All rights reserved.
//

import UIKit
import Messages
import MobileCoreServices

class SettingsObject {
    var filterType : ImageFilterType = .None
    var duration : Double = 2.0
    var alpha : CGFloat = 1.0
    var doRepeat : Bool = false

    func setAlpha(selectedSegment : Int) {
        switch selectedSegment {
        case 0:
            alpha = 1.0
        case 1:
            alpha = 0.8
        case 2:
            alpha = 0.6
        default:
            alpha = 0.4
        }
    }

    func setDuration(selectedSegment : Int) {
        switch selectedSegment {
        case 0:
            duration = 1.5
        case 1:
            duration = 2.5
        case 2:
            duration = 4
        default:
            duration = 6
        }
    }
}

protocol SettingsProtocol {
    func getSettings() -> SettingsObject
}

class MessagesViewController: MSMessagesAppViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, SettingsProtocol {
    @IBOutlet var sendButton : UIButton!
    @IBOutlet var getPicButton : UIButton!
    @IBOutlet var previewView : PreviewView!
    @IBOutlet var filters : UISegmentedControl!
    @IBOutlet var filterTitle : UILabel!
    @IBOutlet var filterValue : UISegmentedControl!
    @IBOutlet var alphaTitle : UILabel!
    @IBOutlet var alphaValue : UISegmentedControl!
    @IBOutlet var repeatOption : UISegmentedControl!

    var globals = Shared.sharedInstance
    var store = StoreManager.sharedInstance

    // MARK: View Methods -------------------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        store.loadStore()

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(restoreSucceeded), name: NSNotification.Name(rawValue: kInAppRestoreNotification), object: nil)
        notificationCenter.addObserver(self, selector: #selector(restoreFailed), name: NSNotification.Name(rawValue: kInAppRestoreFailNotification), object: nil)
        notificationCenter.addObserver(self, selector: #selector(purchaseFailed), name: NSNotification.Name(rawValue: kInAppPurchaseFailNotification), object: nil)
       // notificationCenter.addObserver(self, selector: #selector(setFilterToNone), name: NSNotification.Name(rawValue: kNoneFilterNotification), object: nil)

        sendButton?.layer.cornerRadius = 8.0
        getPicButton?.layer.cornerRadius = 8.0
        previewView.delegate = self
    }

    func restoreSucceeded(notification: NSNotification) {
        print("Purchase success")
        globals.activated = true
        self.showAlert(title: "GhostPics Activated", message: "Your purchase was successful!")
    }
    func restoreFailed(notification: NSNotification) {
        self.showAlert(title: "Purchase Error", message: "Your purchase was unable to be completed")
    }
    func purchaseFailed(notification: NSNotification) {
        self.showAlert(title: "GhostPics Activated", message: "Your purchase was unable to be completed!")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //requestPresentationStyle(.expanded)
        setUIMode(previewOnly: true, completion: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateView(to: self.presentationStyle)
    }

    // MARK: Conversation Methods -------------------------------------------------------------------------------------------------
    override func willBecomeActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the inactive to active state.
        // This will happen when the extension is about to present UI.

        // Use this method to configure the extension and restore previously stored state.
        if let message = conversation.selectedMessage {
            // Use this method to trigger UI updates in response to the message.
             print(message.url)
            if let url = message.url, conversation.localParticipantIdentifier != message.senderParticipantIdentifier  {
                self.setUIMode(previewOnly: true, completion: {
                    self.previewView.startActivityFeedback(completed: nil)
                    ServerManager.sharedInstance.fileExists(url: url, completion: { (success) in
                        if success {
                            let path = url.absoluteString
                            ServerManager.sharedInstance.downloadFile(path: path,
                            progress: { (percent) in
                                self.previewView.setProgress(percent: percent)
                            }, completion: { (imageDataOpt, errorText) in
                                if let imageData = imageDataOpt {
                                    self.previewView.initFromData(data: imageData as NSData)
                                } else {
                                    self.previewView.setText(message: errorText!)
                                }
                            })
                        } else {
                            self.previewView.setText(message: "That picture has expired, thanks to GhostPics!\n\nUse GhostPics's expiring photos to protect your secrets!")
                        }
                    })
                })
            }
        }
    }

    override func didResignActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the active to inactive state.
        // This will happen when the user dissmises the extension, changes to a different
        // conversation or quits Messages.

        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough state information to restore your extension to its current state
        // in case it is terminated later.
        globals.save()
    }

    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        // Called when a message arrives that was generated by another instance of this
        // extension on a remote device.


    }

    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user taps the send button.
    }

    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user deletes the message without sending it.

        // Use this to clean up state related to the deleted message.
    }

    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called before the extension transitions to a new presentation style.

        // Use this method to prepare for the change in presentation style.
        print("will transition: \(presentationStyle)")
    }

    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        updateView(to: presentationStyle)
    }

    var viewStyle = MSMessagesAppPresentationStyle.compact
    func updateView(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after the extension transitions to a new presentation style.
        var hideExtraControls = true
        viewStyle = presentationStyle
        if presentationStyle == .compact {
            previewView.frame.origin.y = sendButton.frame.origin.y + sendButton.frame.height + 8
            previewView.frame.size.height = self.view.frame.height - previewView.frame.origin.y - 8
        } else {
            hideExtraControls = isPreview
        }
        setUIMode(previewOnly: hideExtraControls, completion: nil)

        // Use this method to finalize any behaviors associated with the change in presentation style.
        previewView.sizeImageView()
    }

    internal func composeMessage(_ conversation : MSConversation, image : UIImage, idString: String) -> MSMessage? {
        let message = MSMessage(session: conversation.selectedMessage?.session ?? MSSession())
        let urlPath = cDownloadURL + idString
        guard let components = NSURLComponents(string: urlPath) else {
            print("bad url string")
            return nil
        }
        guard let url = components.url else {
            print("bad url components")
            return nil
        }
        message.url = url
        message.shouldExpire = true

        let layout = MSMessageTemplateLayout()
        layout.caption = "I sent you a Ghost Pic! Tap to see it before it expires!"
        message.layout = layout
        return message
    }

    // MARK: Actions -------------------------------------------------------------------------------------------------
    @IBAction func sendButton(_ sender : UIButton) {
        if globals.activated || globals.imagesSentCount < globals.evaluationImageLimit {
            sendGhost()
        } else {
            self.showQuestionAlert(title: "Evaluation Complete", question: "Evaluation is limited to sending \(globals.evaluationImageLimit) GhostPics. Do you want to remove this limit ?", okTitle: "Yes", cancelTitle: "No", completion: { (accepted) in
                if accepted {
                    _ = self.store.startPurchase(productIDs: [kActivationKey])
                }
            })
        }
     }

    func sendGhost() {
        guard let conversation = activeConversation else { fatalError("Expected a conversation") }

        setUIMode(previewOnly: true, completion: {
            self.previewView.startActivityFeedback(
                completed: {
                    let _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { (timer) in
                        //DispatchQueue.main.async {
                            ServerManager.sharedInstance.uploadFile(self.previewView.asData()!,
                                progress: { (percent) in
                                    DispatchQueue.main.async {
                                        self.previewView.setProgress(percent: percent)
                                    }
                                }, completion: { (fileName) in
                                    if let imageId = fileName {
                                        if let message = self.composeMessage(conversation, image: self.previewView.image, idString: imageId) {
                                            // Add the message to the conversation.
                                            conversation.insert(message) { error in
                                                if let error = error {
                                                    print(error)
                                                }
                                            }
                                            self.dismiss()
                                        }
                                        self.globals.imagesSentCount += 1
                                        self.globals.save()
                                    } else {
                                        self.previewView.setText(message: "Could not prepare image")
                                    }
                            })
                       // }
                    })
            })
        })
    }

    @IBAction func pickPhoto(button : UIButton) {
        let picker = UIImagePickerController()
        picker.mediaTypes = [kUTTypeImage as String]//, kUTTypeMovie as String]
        picker.delegate = self
        if button.tag == 3 {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                picker.sourceType = .camera
            }
        }
        self.present(picker, animated: true, completion: {
            print("presented")
        })
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.previewView.setImage(newImage: image)
            filters.selectedSegmentIndex = 0
        }
        picker.dismiss(animated: true) {
            print("dismissed")
        }
        self.setUIMode(previewOnly: false, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            print("dismissed")
        }
        self.setUIMode(previewOnly: false, completion: nil)
    }

    @IBAction func changeFilter(segs : UISegmentedControl) {

        setFilterTo(filterType: ImageFilterType.fromInt(filterIndex: segs.selectedSegmentIndex))
   }

    @IBAction func changeFilterValue(slider : UISlider) {
        self.previewView.filterImage(settings: getSettings())
    }

    @IBAction func changeRepeatValue(repeatSwitch : UISegmentedControl) {
        self.previewView.filterImage(settings: getSettings())
    }

    @IBAction func changeOpacity(opacity : UISegmentedControl) {
         self.previewView.filterImage(settings: getSettings())
    }

    func setFilterTo(filterType : ImageFilterType) {
        switch filterType {
        case .Flash:
            filterValue.selectedSegmentIndex = 2
            alphaValue.selectedSegmentIndex = 1
        case .Blinds:
            filterValue.selectedSegmentIndex = 2
            alphaValue.selectedSegmentIndex = 1
        case .Fade:
            filterValue.selectedSegmentIndex = 2
            alphaValue.selectedSegmentIndex = 1
        default:
            break
        }
        setUIMode(previewOnly: false, completion: nil)
        self.previewView.filterImage(settings: getSettings())
    }

    func calcAlpha() -> CGFloat {
        let alpha = CGFloat(alphaValue.selectedSegmentIndex + 1)/CGFloat(alphaValue.numberOfSegments)
        return alpha
    }

    // MARK: Convenience Methods -------------------------------------------------------------------------------------------------

    func getSettings() -> SettingsObject {
        let settings = SettingsObject()
        settings.filterType = ImageFilterType.fromInt(filterIndex: self.filters.selectedSegmentIndex)
        settings.setDuration(selectedSegment: filterValue.selectedSegmentIndex)
        settings.setAlpha(selectedSegment: alphaValue.selectedSegmentIndex)
        settings.doRepeat = (repeatOption.selectedSegmentIndex == 1)
        return settings
    }

    // Hide controls when in preivew mode, or when copact size
    private var isPreview = false
    func setUIMode(previewOnly : Bool, completion: (()->())?) {
        self.isPreview = previewOnly
        let previewStyle = (viewStyle == .compact) ? true : previewOnly
        DispatchQueue.main.async {
            self.filters.isHidden = previewStyle
            self.filterTitle.isHidden = previewStyle
            let filtersHidden = (self.filters.selectedSegmentIndex == 0) ? true : previewStyle
            self.filterValue.isHidden = filtersHidden
             self.alphaValue.isHidden = filtersHidden
            self.alphaTitle.isHidden = filtersHidden
            self.repeatOption.isHidden = filtersHidden
            self.sendButton.isHidden = previewOnly
            completion?()
        }
    }

}
