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

class MessagesViewController: MSMessagesAppViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet var sendButton : UIButton!
    @IBOutlet var previewView : PreviewView!
    @IBOutlet var filters : UISegmentedControl!
    @IBOutlet var filterTitle : UILabel!
    @IBOutlet var filterValue : UISlider!
    @IBOutlet var valueTitle : UILabel!

    var globals = Shared.sharedInstance
    var store = StoreManager.sharedInstance

    // MARK: View Methods -------------------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        store.loadStore()

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(restoreSucceeded), name: NSNotification.Name(rawValue: kInAppRestoreCompleted), object: nil)
        notificationCenter.addObserver(self, selector: #selector(restoreFailed), name: NSNotification.Name(rawValue: kInAppRestoreFailed), object: nil)
        notificationCenter.addObserver(self, selector: #selector(purchaseFailed), name: NSNotification.Name(rawValue: kInAppPurchaseFailed), object: nil)
    }
    let kInAppRestoreCompleted = "kInAppRestoreCompleted"
    let kInAppRestoreFailed = "kInAppRestoreFailed"
    let kInAppPurchaseFailed = "kInAppPurchaseFailed"

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
            if let url = message.url, message.senderParticipantIdentifier != activeConversation?.localParticipantIdentifier {
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
                                self.enableDisableControls(enableThem: false)
                            } else {
                                self.previewView.setText(message: errorText!)
                            }
                        })
                    } else {
                        self.previewView.setText(message: "That picture has expired, thanks to GhostPics!\n\nUse GhostPics to send your own expiring photos to protect your own secrets.")
                        self.enableDisableControls(enableThem: true)
                    }
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

    func updateView(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after the extension transitions to a new presentation style.
        if presentationStyle == .compact {
            filterTitle.isHidden = true
            filters.isHidden = true
            filterValue.isHidden = true
            valueTitle.isHidden = true

            previewView.frame.origin.y = sendButton.frame.origin.y + sendButton.frame.height + 8
            previewView.frame.size.height = self.view.frame.height - previewView.frame.origin.y - 8
        } else {
            filterTitle.isHidden = false
            filterValue.isHidden = false
            filters.isHidden = false
            valueTitle.isHidden = false
        }

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

        self.previewView.startActivityFeedback(
            completed: {
            let _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { (timer) in
                DispatchQueue.main.async {
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
                }
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
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            print("dismissed")
        }
    }

    @IBAction func changeFilter(segs : UISegmentedControl) {
         if segs.selectedSegmentIndex == 0 {
            filterValue.isHidden = true
            valueTitle.isHidden = true
        } else {
            filterValue.isHidden = false
            valueTitle.isHidden = false
            switch segs.selectedSegmentIndex {
            case 1:
                valueTitle.text = "Speed"
                filterValue.value = 4
            case 2:
                valueTitle.text = "Count"
                filterValue.value = 8
            default:
                break
            }
        }
        self.previewView.filterImage(filterIndex: segs.selectedSegmentIndex, value: Int(filterValue.value))
   }

    @IBAction func changeFilterValue(slider : UISlider) {
        self.previewView.filterImage(filterIndex: filters.selectedSegmentIndex, value: Int(filterValue.value))
    }

    // MARK: Convenience Methods -------------------------------------------------------------------------------------------------

    func enableDisableControls(enableThem : Bool) {
        filters.isHidden = !enableThem
        filterValue.isHidden = !enableThem
        filterTitle.isHidden = !enableThem
        valueTitle.isHidden = !enableThem
    }

}
