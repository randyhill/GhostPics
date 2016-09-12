//
//  OptionsButton
//  GhostPics
//
//  Created by CRH on 9/10/16.
//  Copyright © 2016 CRH. All rights reserved.
//

import UIKit


class OptionsButton : UIButton {
    var options = [String]()
    var menu : UISegmentedControl?
    private var selectedOption = 0
    var delegate : SettingsProtocol?

    var selectedSegmentIndex : Int {
        get {
            return selectedOption
        }
        set(newSelection) {
            if let segmentControl = menu {
                selectedOption = newSelection
                segmentControl.selectedSegmentIndex = newSelection
                self.setTitleFromIndex()
            }
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

    // MARK: Actions  -------------------------------------------------------------------------------------------------
    func tapButton() {
        if menu != nil {
            destroyMenu()
        } else {
            createMenu()
        }
    }

    func menuItemSelected() {
        selectedOption = menu!.selectedSegmentIndex
        self.setTitleFromIndex()
        destroyMenu()
        delegate?.updateSettings()
    }

    // MARK: Menu -------------------------------------------------------------------------------------------------
    func addOption(title : String) {
        options.append(title)
    }

    func addOptions(titles : [String]) {
        options = titles
    }

    func setTitleFromIndex() {
        let optionText = options[selectedOption]
        self.setTitle(optionText, for: .normal)
    }

    func width() -> CGFloat {
        let font = UIFont.systemFont(ofSize: 16.0)
        var width : CGFloat = 0
        let textAttributes = [NSFontAttributeName: font]
        for option in options {
            let cg = (option as NSString).size(attributes: textAttributes)
            width += (cg.width + 12)
        }
        return width
    }

    func createMenu() {
        menu = UISegmentedControl()
        let width = self.width()
        let xOffset = self.frame.origin.x + width < self.superview!.frame.width ? self.frame.origin.x : self.superview!.frame.width - width
        menu?.frame = CGRect(x: xOffset, y: self.frame.origin.y + self.frame.size.height, width: width, height: 28)
        menu?.tintColor = UIColor.black
        menu?.backgroundColor = Shared.backgroundColor(alpha: 1.0)//UIColor.black
       // menu?.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.white], for: .normal)
        for option in options {
            menu?.insertSegment(withTitle: option, at: menu!.numberOfSegments, animated: false)
        }
        menu?.addTarget(self, action: #selector(menuItemSelected), for: .valueChanged)
        self.superview!.addSubview(menu!)
    }

    func destroyMenu() {
        menu?.removeFromSuperview()
        menu = nil
    }

}
