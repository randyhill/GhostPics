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
    var blindSize : CGFloat = 0.6

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
            duration = 0.3
        case 1:
            duration = 1.0
        case 2:
            duration = 2.0
        default:
            duration = 4.0
        }
    }
}

protocol SettingsProtocol {
    func getSettings() -> SettingsObject
    func updateSettings(button: OptionsButton)
}

class MessagesViewController: MSMessagesAppViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, SettingsProtocol {
    @IBOutlet var gpIcon : UIImageView!
    @IBOutlet var sendButton : UIButton!
    @IBOutlet var getPicButton : UIButton!
    @IBOutlet var cameraButton : UIButton!
    @IBOutlet var previewView : PreviewView!
    @IBOutlet var filterTitle : UILabel!
    @IBOutlet var filterType : OptionsButton!
    @IBOutlet var speedTitle: UILabel!
    @IBOutlet var speed : OptionsButton!
    @IBOutlet var smallTitle : UILabel!
    @IBOutlet var bigTitle : UILabel!
    @IBOutlet var width : UISlider!
    @IBOutlet var facesControl : FacesControl!
    var fullScreenButton = UIButton()

    var globals = Shared.sharedInstance
    var store = StoreManager.sharedInstance
    var inPreviewMode = false   // We are showing a sent image
    var inFileDownload = false
    var viewStyle = MSMessagesAppPresentationStyle.compact

    // MARK: View Methods -------------------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        store.loadStore()

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(restoreSucceeded), name: NSNotification.Name(rawValue: kInAppRestoreNotification), object: nil)
        notificationCenter.addObserver(self, selector: #selector(restoreFailed), name: NSNotification.Name(rawValue: kInAppRestoreFailNotification), object: nil)
        notificationCenter.addObserver(self, selector: #selector(purchaseFailed), name: NSNotification.Name(rawValue: kInAppPurchaseFailNotification), object: nil)

        sendButton?.layer.cornerRadius = 8.0
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            cameraButton?.layer.cornerRadius = 8.0
        } else {
            cameraButton?.isHidden = true
        }

        getPicButton?.layer.cornerRadius = 8.0
        previewView.delegate = self
        filterType.addOptions(titles: ["None", "Flash", "Blinds", "Fade", "Faces"])
        filterType.delegate = self
        speed.addOptions(titles: ["Fastest", "Fast", "Medium", "Slow"])
        speed.delegate = self

        // Get started button and walkthrough
        if !Shared.sharedInstance.didWalkthrough {
            fullScreenButton.backgroundColor = Shared.attentionColor(alpha: 1.0)
            fullScreenButton.layer.cornerRadius = 8.0
            fullScreenButton.setTitle("Get Started", for: .normal)
            fullScreenButton.setTitleColor(UIColor.white, for: .normal)
            fullScreenButton.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
            fullScreenButton.addTarget(self, action: #selector(self.makeFullScreen), for: .touchDown)
            self.view.addSubview(fullScreenButton)
        }

        facesControl.isHidden = true
        facesControl.delegate = self

        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        self.view.addGestureRecognizer(tap)

        let iconTap = UITapGestureRecognizer(target: self, action: #selector(iconTapped))
        gpIcon.addGestureRecognizer(iconTap)
        gpIcon.layer.cornerRadius = 8.0
        gpIcon.layer.masksToBounds = true
        gpIcon.isUserInteractionEnabled = true
   }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Size dynamic controls just before we appear so we get correct sizes
        let fsWidth : CGFloat = 120.0
        fullScreenButton.frame = CGRect(x: (self.view.frame.width - fsWidth)/2, y: (self.view.frame.height - 40.0)/2, width: fsWidth, height: 40.0)
        facesControl.sizeIcons()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
         updateView(to: self.presentationStyle)
   }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: IAP Methods -------------------------------------------------------------------------------------------------
    func restoreSucceeded(notification: NSNotification) {
        globals.activated = true
        globals.save()
        DispatchQueue.main.async {
            self.showAlert(title: "GhostPics Activated", message: "Your purchase was successful!")
       }
    }
    func restoreFailed(notification: NSNotification) {
        DispatchQueue.main.async {
            self.showAlert(title: "Purchase Error", message: "Your purchase was unable to be completed")
        }
    }
    func purchaseFailed(notification: NSNotification) {
        DispatchQueue.main.async {
            self.showAlert(title: "GhostPics Activated", message: "Your purchase was unable to be completed!")
        }
    }

    // MARK: Conversation Methods -------------------------------------------------------------------------------------------------

    // Called when the extension is about to move from the inactive to active state.
    // This will happen when the extension is about to present UI.
    // Use this method to configure the extension and restore previously stored state.
    override func willBecomeActive(with conversation: MSConversation) {
        if let message = conversation.selectedMessage {
            self.openReceivedImage(message: message, conversation: conversation)
        }
    }

    func openReceivedImage(message : MSMessage, conversation: MSConversation) {
        // We are never in preview mode unless we get an image that we didn't send
        inPreviewMode = false
        inFileDownload = true

        // Use this method to trigger UI updates in response to the message.
        if let url = message.url, conversation.localParticipantIdentifier != message.senderParticipantIdentifier  {
            self.setUIMode(completion: {
                self.previewView.startActivityFeedback(completed: nil)
                ServerManager.sharedInstance.fileExists(url: url, completion: { (success) in
                    self.inPreviewMode = true
                    if success {
                        let path = url.absoluteString
                        ServerManager.sharedInstance.downloadFile(path: path,
                            progress: { (percent) in
                                self.previewView.setProgress(percent: percent)
                            }, completion: { (imageDataOpt, errorText) in
                                self.inFileDownload = false
                                if let imageData = imageDataOpt {
                                    self.previewView.initFromData(data: imageData as NSData)
                                } else {
                                    self.previewView.setText(message: errorText!)
                                }
                        })
                    } else {
                        self.inFileDownload = false
                        self.previewView.setText(message: "That picture has expired, thanks to GhostPics!\n\nUse GhostPics's expiring photos to protect your secrets!")
                    }
                })
            })
        }
    }

    // Called when the extension is about to move from the active to inactive state.
    // This will happen when the user dissmises the extension, changes to a different
    // conversation or quits Messages.
    // Use this method to release shared resources, save user data, invalidate timers,
    // and store enough state information to restore your extension to its current state
    // in case it is terminated later.
   override func didResignActive(with conversation: MSConversation) {
        globals.save()
    }

    // Called when a message arrives that was generated by another instance of this
    // extension on a remote device.
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
    }

    // Called when the user taps the send button.
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
    }

    // Called when the user deletes the message without sending it.
    // Use this to clean up state related to the deleted message.
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
    }

    // Called before the extension transitions to a new presentation style.
    // Use this method to prepare for the change in presentation style.
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
    }

    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        updateView(to: presentationStyle)
    }

    func updateView(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after the extension transitions to a new presentation style.
        DispatchQueue.main.async {
            self.viewStyle = presentationStyle
            if presentationStyle == .compact {
                self.previewView.frame.origin.y = self.sendButton.frame.origin.y + self.sendButton.frame.height + 8
                self.previewView.frame.size.height = self.view.frame.height - self.previewView.frame.origin.y - 8

                // Image picker needs to be adjsuted so cancel button is visiable. Camera is done with it's own overlay.
                if self.cameraOverlay == nil {
                    self.picker.view.frame.origin.y -= 80
                    self.picker.view.frame.size.height += 80

                }
                // Hide aboutscreen if it was open
                if let about = self.aboutScreen {
                    about.dismiss(animated: true, completion: {

                    })
                }
            } else {
                // Let's open the image if it was sent to us while we were already open.
                if let conversation = self.activeConversation, let message = conversation.selectedMessage, !self.inFileDownload {
                    self.openReceivedImage(message: message, conversation: conversation)
                }

                // Image picker needs to be adjsuted so cancel button is visiable. Camera is done with it's own overlay.
               if self.cameraOverlay == nil {
                    self.picker.view.frame.origin.y += 80
                    self.picker.view.frame.size.height -= 80
                }

                self.fullScreenButton.removeFromSuperview()
                if !Shared.sharedInstance.didWalkthrough {
                    Shared.sharedInstance.didWalkthrough = true
                    Shared.sharedInstance.save()
                    self.showAboutView()
                }
            }
            self.sizeCameraControls()
            self.setUIMode(completion: nil)

            // Use this method to finalize any behaviors associated with the change in presentation style.
            self.previewView.sizeImageView()
        }
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
        layout.caption = "I sent you a GhostPic! Tap to see it before it vanishes!"
        //layout.image = image
        message.layout = layout
        return message
    }

    // MARK: Actions -------------------------------------------------------------------------------------------------
    @IBAction func sendButton(_ sender : UIButton) {
        sendGhost()
     }

    func sendGhost() {
        guard let conversation = activeConversation else { fatalError("Expected a conversation") }

        setUIMode(completion: {
            self.previewView.startActivityFeedback( completed: {
                let _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { (timer) in
                    ServerManager.sharedInstance.uploadFile(self.previewView.asData()!,
                    progress: { (percent) in
                          self.previewView.setProgress(percent: percent)
                    },
                    completion: { (fileName) in
                        if let imageId = fileName {
                            if let message = self.composeMessage(conversation, image: self.previewView.image, idString: imageId) {
                                // Add the message to the conversation.
                                conversation.insert(message) { error in
                                    if let error = error {
                                        print(error)
                                    }
                                }
                                self.dismiss()
                                self.globals.imagesSentCount += 1
                                self.globals.save()
                            } else {
                                self.previewView.setText(message: "Could not send image, try again")
                            }
                        } else {
                            self.previewView.setText(message: "Could not prepare image, try again")
                        }
                    })
                })
            })
        })
    }

    @IBAction func makeFullScreen(button: UIButton) {
        requestPresentationStyle(.expanded)
        fullScreenButton.removeFromSuperview()
    }

    func viewTapped(tap : UITapGestureRecognizer) {
        OptionsMenu.sharedInstance.destroyMenu()
    }

    func iconTapped(tap : UITapGestureRecognizer) {
        if viewStyle == MSMessagesAppPresentationStyle.compact {
            requestPresentationStyle(.expanded)
        }
        showAboutView()
    }

    @IBAction func openAboutView() {
        if viewStyle == MSMessagesAppPresentationStyle.compact {
        requestPresentationStyle(.expanded)
        }
        showAboutView()
    }

    var aboutScreen : AboutController?
    func showAboutView() {
        guard let about = self.storyboard?.instantiateViewController(withIdentifier: "AboutController") as? AboutController else {
            return
        }
        aboutScreen = about
        self.aboutScreen?.delegate = self
        self.present(about, animated: true, completion: {
        })
    }

    func faceTapped(name: String) {
        previewView.addFace(name: name)
    }

    // MARK: Image Pickers -------------------------------------------------------------------------------------------------

    var picker = UIImagePickerController()

    @IBAction func pickPhoto(button : UIButton) {
        picker.mediaTypes = [kUTTypeImage as String]//, kUTTypeMovie as String]
        picker.delegate = self
        fullScreenButton.removeFromSuperview()
        self.present(picker, animated: true, completion: {
            if self.viewStyle != MSMessagesAppPresentationStyle.compact {
                self.picker.view.frame.origin.y += 80
                self.picker.view.frame.size.height -= 80
            }
        })
    }

    var cameraOverlay : CameraOverlay?
    @IBAction func pickFromCamera(button : UIButton) {
         picker.mediaTypes = [kUTTypeImage as String]//, kUTTypeMovie as String]
        picker.sourceType = .camera
        picker.delegate = self
        picker.showsCameraControls = false
        picker.cameraOverlayView = createCameraControls()
        fullScreenButton.removeFromSuperview()

        self.present(picker, animated: false, completion: {
        })
    }

    func createCameraControls() -> CameraOverlay {
        let isCompact = self.viewStyle == MSMessagesAppPresentationStyle.compact
        cameraOverlay = CameraOverlay(frame: cameraControlsRect(isCompact: isCompact), isCompact: isCompact)
        cameraOverlay?.cameraControls.addTarget(self, action: #selector(cameraControlTapped), for: .valueChanged)
        return cameraOverlay!
    }

    func sizeCameraControls() {
        if cameraOverlay != nil {
            let isCompact = self.viewStyle == MSMessagesAppPresentationStyle.compact
            let overlayFrame = cameraControlsRect(isCompact: isCompact)
            self.cameraOverlay?.sizeControls(frame: overlayFrame, isCompact: isCompact)
       }
    }

    func cameraControlsRect(isCompact: Bool) -> CGRect {
        var cameraFrame = self.view.frame
        if  isCompact {
            cameraFrame.size.width /= 2
            cameraFrame.origin.x = cameraFrame.size.width
        } else {
            cameraFrame.origin.y += 120
            cameraFrame.size.height -= 120
        }
        return cameraFrame
    }

    func cameraControlTapped(cameraControls : UISegmentedControl) {
        switch cameraControls.selectedSegmentIndex {
        case 0:
            if picker.cameraDevice == .rear {
                picker.cameraDevice = .front
            } else {
                picker.cameraDevice = .rear
            }
        case 1:
            picker.takePicture()
        case 2:
            if picker.sourceType == .camera {
                picker.sourceType = .savedPhotosAlbum
            } else if picker.sourceType == .photoLibrary {
                picker.sourceType = .savedPhotosAlbum
            } else {
                picker.sourceType = .camera
            }
        default:
            break;
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            if presentationStyle == .compact {
                previewView.frame.origin.y = sendButton.frame.origin.y + sendButton.frame.height + 8
                previewView.frame.size.height = self.view.frame.height - previewView.frame.origin.y - 8
            }
            self.previewView.setImage(newImage: image)
            filterType.selectedSegmentIndex = 0
        }
        picker.dismiss(animated: true) {
            self.cameraOverlay = nil
        }
        self.inPreviewMode = false
        self.setUIMode(completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            self.cameraOverlay = nil
        }
        self.setUIMode(completion: nil)
    }

    func setFilterTo(type : ImageFilterType) {
        switch type {
        case .Flash:
            speed.selectedSegmentIndex = 1
        case .Blinds:
            speed.selectedSegmentIndex = 3
        case .Fade:
            speed.selectedSegmentIndex = 2
        default:
            break
        }
        if type == .Faces {
            facesControl.isHidden = false
        } else {
            facesControl.isHidden = true
        }
    }

    @IBAction func widthChanged(slider : UISlider) {
        let settings = self.getSettings()
        settings.blindSize = CGFloat(slider.value)
        self.previewView.filterImage(settings: settings)
    }

    // MARK: Settings/UI -------------------------------------------------------------------------------------------------

    func getSettings() -> SettingsObject {
        let settings = SettingsObject()
        settings.filterType = ImageFilterType.fromInt(filterIndex: self.filterType.selectedSegmentIndex)
        settings.setDuration(selectedSegment: speed.selectedSegmentIndex)
        return settings
    }

    func updateSettings(button: OptionsButton) {
        DispatchQueue.main.async {
           switch button.tag {
            case 1: // Effects button
                let shared = Shared.sharedInstance
                if shared.isExpired() && self.filterType.selectedSegmentIndex > 0 {
                    self.showQuestionAlert(title: "Evaluation Limit", question: "We hope you've enjoyed using the effects. Their evaluation use limit has been reached. Do you want to continue using effects on your GhostPics (and support our development)?", okTitle: "Yes", cancelTitle: "No", completion: { (accepted) in
                        if accepted {
                            _ = self.store.startPurchase(productIDs: [kActivationKey])
                        }
                    })
                    self.filterType.selectedSegmentIndex = 0
                } else {
                    if self.filterType.selectedSegmentIndex > 0 {
                        shared.effectsUsedCount += 1
                    }
                    self.setFilterTo(type: ImageFilterType.fromInt(filterIndex: self.filterType.selectedSegmentIndex))
                }
            default:
                break
            }
            self.previewView.filterImage(settings: self.getSettings())
            self.setUIMode(completion: nil)
        }
    }

    // Hide controls when in preview mode, or when copact size
    func setUIMode(completion: (()->())?) {
        DispatchQueue.main.async {
            let inCompactStyle = (self.viewStyle == .compact)
            let previewStyle = !self.previewView.hasImage() || self.inPreviewMode
            let curFilterType = self.getSettings().filterType

            // Filter type
            self.filterType.isHidden = previewStyle || inCompactStyle
            self.filterTitle.isHidden = previewStyle || inCompactStyle

            // Filter settings
            let hideFilterSettings = inCompactStyle || (curFilterType == .None) || previewStyle || (curFilterType == .Faces)
            self.speedTitle.isHidden = hideFilterSettings
            self.speed.isHidden = hideFilterSettings

            let blindsStyle = curFilterType != .Blinds
            self.width.isHidden = blindsStyle
            self.smallTitle.isHidden = blindsStyle
            self.bigTitle.isHidden = blindsStyle

            // Send button
            self.sendButton.isHidden = self.inPreviewMode || !self.previewView.hasImage()
            completion?()
        }
    }

}
