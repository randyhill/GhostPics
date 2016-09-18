//
//  OptionsButton
//  GhostPics
//
//  Created by CRH on 9/10/16.
//  Copyright © 2016 CRH. All rights reserved.
//

import UIKit


class OptionsButton : UIButton {
    var delegate : SettingsProtocol?
    private var selectedOption = 0
    var options = [String]()

    var selectedSegmentIndex : Int {
        get {
            return selectedOption
        }
        set(newSelection) {
            selectedOption = newSelection
            setTitleFromIndex()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        self.addTarget(self, action: #selector(tapButton), for: .touchDown)
        self.layer.cornerRadius = 8.0
    }

    func addOptions(titles : [String]) {
        options = titles
    }

    func setTitleFromIndex() {
        let optionText = options[selectedOption]
        self.setTitle(optionText, for: .normal)
    }

    // MARK: Actions  -------------------------------------------------------------------------------------------------
    func tapButton() {
        let optionsMenu = OptionsMenu.sharedInstance
        if optionsMenu.menu != nil {
            OptionsMenu.sharedInstance.destroyMenu()
           if optionsMenu.button != self {
                 OptionsMenu.sharedInstance.createMenu(options: options, delegate: delegate, button: self, topLeft: CGPoint(x: self.frame.origin.x, y: self.frame.origin.y + self.frame.height) )
            }
        } else {
            OptionsMenu.sharedInstance.createMenu(options: options, delegate: delegate, button: self, topLeft: CGPoint(x: self.frame.origin.x, y: self.frame.origin.y + self.frame.height) )
        }
    }

 }

// MARK: Menu -------------------------------------------------------------------------------------------------
class OptionsMenu {
    static let sharedInstance = OptionsMenu()

    var menu : UISegmentedControl?
    var options = [String]()
    var delegate : SettingsProtocol?
    var button : OptionsButton?

    @objc func menuItemSelected() {
        button?.selectedSegmentIndex = menu!.selectedSegmentIndex
        destroyMenu()
        delegate?.updateSettings(button: self.button!)
    }

    func addOptions(titles : [String]) {
        options = titles
    }

    func width(font: UIFont) -> CGFloat {
        var width : CGFloat = 0
        let textAttributes = [NSFontAttributeName: font]
        for option in options {
            let cg = (option as NSString).size(attributes: textAttributes)
            width += (cg.width + 28)
        }
        return width
    }

    func createMenu(options : [String], delegate : SettingsProtocol?, button: OptionsButton, topLeft: CGPoint) {
        self.options = options
        self.delegate = delegate
        self.button = button

        menu = UISegmentedControl()
        let font = UIFont.systemFont(ofSize: 18.0)
        let width = self.width(font: font)

        // Stay on screen
        var adjustedX = topLeft.x
        if adjustedX + width > button.superview!.frame.width {
            adjustedX = button.superview!.frame.width - width
        }
        menu?.frame = CGRect(x: adjustedX, y: topLeft.y, width: width, height: 48.0)
        menu?.tintColor = UIColor.black
        menu?.backgroundColor = UIColor.white
        menu?.setTitleTextAttributes([NSFontAttributeName: font], for: .normal)
        for option in options {
            menu?.insertSegment(withTitle: option, at: menu!.numberOfSegments, animated: false)
        }
        menu?.addTarget(self, action: #selector(menuItemSelected), for: .valueChanged)
        button.superview!.addSubview(menu!)
    }

    func destroyMenu() {
        menu?.removeFromSuperview()
        menu = nil
    }

}
