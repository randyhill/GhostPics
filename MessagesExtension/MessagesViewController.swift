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
    var blindsSize : CGFloat = 0.2

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

    func setBlindsSize(selectedSegment : Int) {
        switch selectedSegment {
        case 0:
            blindsSize = 0.4
        case 1:
            blindsSize = 0.2
        case 2:
            blindsSize = 0.1
        default:
            blindsSize = 0.1
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
    @IBOutlet var blindsTitle : UILabel!
    @IBOutlet var blinds : OptionsButton!
    @IBOutlet var repeatOption : UISegmentedControl!
    var fullScreenButton = UIButton()

    var globals = Shared.sharedInstance
    var store = StoreManager.sharedInstance
    var inPreviewMode = false
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
        filterType.addOptions(titles: ["None", "Flash", "Blinds", "Fade"])
        filterType.delegate = self
        speed.addOptions(titles: ["Fastest", "Fast", "Medium", "Slow"])
        speed.delegate = self
        blinds.addOptions(titles: ["Thin", "Medium", "Thick"])
        blinds.delegate = self

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
        let fsWidth : CGFloat = 90.0
        let inset : CGFloat = 4.0
        fullScreenButton.frame = CGRect(x: self.view.frame.width - fsWidth - inset, y: inset, width: fsWidth, height: 30.0)
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
        self.showAlert(title: "GhostPics Activated", message: "Your purchase was successful!")
    }
    func restoreFailed(notification: NSNotification) {
        self.showAlert(title: "Purchase Error", message: "Your purchase was unable to be completed")
    }
    func purchaseFailed(notification: NSNotification) {
        self.showAlert(title: "GhostPics Activated", message: "Your purchase was unable to be completed!")
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
        print("opening image")

        // Use this method to trigger UI updates in response to the message.
        if let url = message.url, conversation.localParticipantIdentifier != message.senderParticipantIdentifier  {
            self.setUIMode(completion: {
                self.previewView.startActivityFeedback(completed: nil)
                ServerManager.sharedInstance.fileExists(url: url, completion: { (success) in
                    if success {
                        let path = url.absoluteString
                        ServerManager.sharedInstance.downloadFile(path: path,
                            progress: { (percent) in
                                self.previewView.setProgress(percent: percent)
                            }, completion: { (imageDataOpt, errorText) in
                                self.inPreviewMode = true
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

//    func openImage(message: MSMessage) {
//        if let layout = message.layout {
//            if let template = layout as? MSMessageTemplateLayout {
//                if let image = template.image {
//                    self.previewView.decodeImage(image: image)
//                }
//            }
//        } else {
//            let session = MSSession(message.session)
//
//        }
//    }

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

                // Hide aboutscreen if it was open
                if let about = self.aboutScreen {
                    about.dismiss(animated: true, completion: {

                    })
                }
            } else {
                // Let's open the image if it was sent to us while we were already open.
                if let conversation = self.activeConversation, let message = conversation.selectedMessage, !self.inPreviewMode {
                    self.openReceivedImage(message: message, conversation: conversation)
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
        if globals.activated || !globals.isExpired() {
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

    func makeFullScreen(button: UIButton) {
        requestPresentationStyle(.expanded)
        button.removeFromSuperview()
        getPicButton.backgroundColor = Shared.attentionColor(alpha: 1.0)
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

    // MARK: Image Pickers -------------------------------------------------------------------------------------------------

    var picker = UIImagePickerController()

    @IBAction func pickPhoto(button : UIButton) {
        picker.mediaTypes = [kUTTypeImage as String]//, kUTTypeMovie as String]
        picker.delegate = self
        fullScreenButton.removeFromSuperview()
        self.present(picker, animated: true, completion: {
        })
    }

    var cameraOverlay : CameraOverlay?
    @IBAction func pickFromCamera(button : UIButton) {
       // let picker = UIImagePickerController()
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

    // MARK: Filters -------------------------------------------------------------------------------------------------

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
            speed.selectedSegmentIndex = 1
        case .Blinds:
            speed.selectedSegmentIndex = 3
        case .Fade:
            speed.selectedSegmentIndex = 2
        default:
            break
        }
    }

    // MARK: Settings/UI -------------------------------------------------------------------------------------------------

    func getSettings() -> SettingsObject {
        let settings = SettingsObject()
        settings.filterType = ImageFilterType.fromInt(filterIndex: self.filterType.selectedSegmentIndex)
        settings.setDuration(selectedSegment: speed.selectedSegmentIndex)
        settings.doRepeat = (repeatOption.selectedSegmentIndex == 1)
        settings.setBlindsSize(selectedSegment: blinds.selectedSegmentIndex)
        return settings
    }

    func updateSettings(button: OptionsButton) {
        switch button.tag {
        case 1:
            setFilterTo(filterType: ImageFilterType.fromInt(filterIndex: self.filterType.selectedSegmentIndex))
        default:
            break
        }
        self.previewView.filterImage(settings: getSettings())
        setUIMode(completion: nil)
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
            let hideFilterSettings = inCompactStyle || (curFilterType == .None) || previewStyle
            self.speedTitle.isHidden = hideFilterSettings
            self.speed.isHidden = hideFilterSettings
            self.repeatOption.isHidden = hideFilterSettings

            // Blinds filter settings
            let hideBlinds = inCompactStyle || (curFilterType != .Blinds)
            self.blindsTitle.isHidden = hideBlinds
            self.blinds.isHidden = hideBlinds

            // Send button
            self.sendButton.isHidden = self.inPreviewMode || !self.previewView.hasImage()
            completion?()
        }
    }

}
