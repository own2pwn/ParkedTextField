//
//  ConstantPlaceholderTextField.swift
//  TextField
//
//  Created by Gunay Mert Karadogan on 13/7/15.
//  Copyright (c) 2015 Gunay Mert Karadogan. All rights reserved.
//

import UIKit

public class ParkedTextField: UITextField {

    
    // MARK: Properties

    /// Constant part of the text. Defaults to "".
    @IBInspectable public var parkedText: String = "" {
        didSet {
            // Force update placeholder to get the new value of constantText
            if let holder = placeholder {
                placeholder = holder + ""
            } else {
                placeholder = ""
            }
        }
    }

    /// Constant part of the text. Defaults to the text field's font.
    public var parkedTextFont: UIFont! {
        didSet {
            textChanged(self)
        }
    }

    /// Constant part of the text. Defaults to the text field's textColor.
    @IBInspectable public var parkedTextColor: UIColor! {
        didSet {
            textChanged(self)
        }
    }

    /// Attributes wrapper for font and color of parkedText
    var parkedTextAttributes: [String: NSObject] {
        return [
            NSFontAttributeName: parkedTextFont,
            NSForegroundColorAttributeName: parkedTextColor ?? textColor
        ]
    }

    // TODO: Investigate if we really need @IBInspectable. Maybe super.placeholder in the storyboard is enough.
    @IBInspectable public override var placeholder: String? {
        didSet {
            if let holder = placeholder {
                super.placeholder = holder + parkedText
            } else {
                super.placeholder = parkedText
            }

            let constantTextStartIndex = count(placeholder!) - count(parkedText)
            let attributedString = NSMutableAttributedString(string: placeholder!)
            attributedString.addAttributes(parkedTextAttributes, range: NSMakeRange(constantTextStartIndex, count(parkedText)))
            attributedPlaceholder = attributedString
        }
    }

    enum TypingState {
        case Start, Typed, TypedEmpty
    }

    var typingState = TypingState.Start

    var beginningOfConstantText: UITextPosition? {
        get {
            return positionFromPosition(endOfDocument, offset: -count(parkedText))
        }
    }

    var prevText = ""


    // MARK: Initialization

    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    func commonInit() {
        if let boldFont = bold(font) {
            parkedTextFont = boldFont
        } else {
            parkedTextFont = font
        }

        parkedTextColor = textColor

        addTarget(self, action: "textChanged:", forControlEvents: .EditingChanged)

        text = ""
        prevText = text

        typingState = .Start
    }


    // MARK: EditingChanged handler

    func textChanged(sender: UITextField) {
        switch typingState {
        case .Start where count(text) > 0:

            let attributedString = NSMutableAttributedString(string: text + parkedText)
            attributedString.addAttributes(parkedTextAttributes, range: NSMakeRange(count(text), count(parkedText)))
            attributedText = attributedString

            prevText = text
            goToBeginningOfConstantText()

            typingState = .Typed

        case .Typed:

            if text == parkedText {
                typingState = .Start
                text = ""
                return
            }

            var endIndexOfText = count(text)
            var startIndexOfConstantText = endIndexOfText - count(parkedText)
            var shouldBeConstantText = text[startIndexOfConstantText..<endIndexOfText]

            // If change occured in constantText don't accept it. Reset to prevText.
            if shouldBeConstantText != parkedText {
                let attributedString = NSMutableAttributedString(string: prevText)
                attributedString.addAttributes(parkedTextAttributes, range: NSMakeRange(count(prevText)-count(parkedText), count(parkedText)))
                attributedText = attributedString

                goToBeginningOfConstantText()
            } else {
                prevText = text
            }

        default:
            break

        }
    }

    // MARK: Utilites

    func goToBeginningOfConstantText() {
        if let position = beginningOfConstantText {
            goToTextPosition(position)
        }
    }

    func goToTextPosition(textPosition: UITextPosition!) {
        selectedTextRange = textRangeFromPosition(textPosition, toPosition: textPosition)
    }

    func bold(font: UIFont) -> UIFont? {
        let descriptor = font.fontDescriptor().fontDescriptorWithSymbolicTraits(UIFontDescriptorSymbolicTraits.TraitBold)

        if let descriptor = descriptor {
            return UIFont(descriptor: descriptor, size: 0)
        } else {
            return nil
        }
    }
}

extension String {
    subscript (i: Int) -> Character {
        return self[advance(self.startIndex, i)]
    }

    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }

    subscript (r: Range<Int>) -> String {
        return substringWithRange(Range(start: advance(startIndex, r.startIndex), end: advance(startIndex, r.endIndex)))
    }
}