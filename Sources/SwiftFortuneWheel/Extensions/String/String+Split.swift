//
//  String+Split.swift
//  SwiftFortuneWheel-iOS
//
//  Created by Sherzod Khashimov on 6/26/20.
//  Modified by Hyunjoon Ko on 7/11/23.
//  Copyright © 2020 SwiftFortuneWheel. All rights reserved.
//

import Foundation

#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension String {
    
    /// Splits String to lines
    /// - Parameters:
    ///   - font: Font
    ///   - lineWidths: Each line width
    ///   - lineBreak: Line break type
    ///   - splitCharacter: Split by the specified character
    /// - Returns: List of split strings to lines
    func split(font: SFWFont, lineWidths: [CGFloat], lineBreak: TextPreferences.LineBreakMode, splitCharacter: String = " ") -> [String] {
        
        /// List of split strings to lines
        var linedStrings: [String] = []
        
        /// Split character width
        let splitCharacterWidth = splitCharacter.width(by: font)
        
        /// Available words for String
        var words = self.components(separatedBy: splitCharacter) // self.split(separator: splitCharacter.first!)
        
        /// The minimum size of the last word
        var lastWordMinimumSize = CGFloat.greatestFiniteMagnitude
        
        if let lastWord = words.last {
            lastWordMinimumSize = String(lastWord.suffix(4)).width(by: font)
        }
        
        /// Latest added word to the lines
        var latestAddedWord = 0
        
        var isNewLine = false
        
        /// Splits String to lines, up to last word
        for index in stride(from: 0, to: lineWidths.count, by: 1) {
            
            /// String at the line
            var linedString = ""
            
            /// Available width in line
            var availableWidthInLine = lineWidths[index]
            
            /// Adds each word to line
            for wordIndex in latestAddedWord..<words.count {
                
                /// Check for although there are lines available, no more words are left.
                guard latestAddedWord != words.count else { break }
                
                /// Is word first in the line
                let isFirstWordInLine = linedString.count < 1
                
                /// Current word
                var word = String(words[wordIndex])
                if splitCharacter != "\n" {
                    if word.contains("\n") {
                        let items = word.components(separatedBy: "\n")
                        for i in 0..<items.count {
                            if i == 0 {
                                isNewLine = true
                                word = items[i]
                                words[wordIndex] = items[i]
                            } else {
                                words.insert(items[i], at: wordIndex + i)
                            }
                        }
                        if let lastWord = words.last {
                            lastWordMinimumSize = String(lastWord.suffix(4)).width(by: font)
                        }
                    } else if isNewLine, availableWidthInLine != lineWidths[index], lineWidths.count - 1 != index {
                        let range = (self as NSString).range(of: word)
                        if range.location != NSNotFound, range.length != NSNotFound, range.length != 0, range.location != 0,
                           (self as NSString).substring(with: NSRange(location: range.location - 1, length: 1)) == "\n" {
                            break // added to the next line
                        }
                    }
                }
                
                /// Word width, if it's not first in the line, adds the space before the word
                let wordWidth = isFirstWordInLine ? word.width(by: font) : word.width(by: font) + splitCharacterWidth
                
                /// Is word fit in the line
                let isWordFit = availableWidthInLine > wordWidth
                
                /// If word fit in the line, adds the word and calculates available width in the line for next word.
                if isWordFit {
                    linedString = isFirstWordInLine ? linedString + word : linedString + splitCharacter + word
                    availableWidthInLine -= wordWidth
                    latestAddedWord = wordIndex + 1
                } else {
                    /// Сhecks if lineBreak == .wordWrap then the current word should not be added to the line
                    guard lineBreak != .wordWrap else { continue }
                    
                    /// Split by character
                    if lineBreak == .characterWrap {
                        /// Cropped word
                        let croppedWord = word.crop(by: isFirstWordInLine ? availableWidthInLine : availableWidthInLine - splitCharacterWidth, font: font)
                        
                        /// Second part of cropped word
                        let wordSecondPart = word.dropFirst(croppedWord.count)
                        
                        // if word first in the line, crops the word and adds it to the line
                        if isFirstWordInLine {
                            linedString = linedString + croppedWord
                        } else {
                            linedString = linedString + splitCharacter + croppedWord
                        }
                        /// Insert second word part to iteration
                        words.insert(String(wordSecondPart), at: wordIndex + 1)
                        
                        availableWidthInLine = 0
                        latestAddedWord = wordIndex + 1
                    } else {
                        /// if word first in the line, crops the word and adds it to the line
                        if isFirstWordInLine {
                            /// Cropped word
                            var croppedWord = word.crop(by: availableWidthInLine, font: font)
                            if lineBreak == .truncateTail {
                                croppedWord.replaceLastCharactersWithDots()
                            }
                            linedString += croppedWord
                            availableWidthInLine = 0
                            latestAddedWord = wordIndex + 1
                        } else {
                            /// Is the latest line
                            let isLatestLine = lineWidths.count - 1 == index
                            /// If the line is not latest, the current word most likely will be added to the next line
                            guard isLatestLine else { break }
                            /// Checks available width in the line for the cropped word, the word won't be added if available width is less then for 5 character
                            guard availableWidthInLine >= splitCharacterWidth + lastWordMinimumSize else { continue }
                            /// Cropped word
                            var croppedWord = word.crop(by: availableWidthInLine, font: font)
                            /// Checks are cropped word more than 3 character
                            guard croppedWord.count > 3 else { continue }
                            if lineBreak == .truncateTail {
                                croppedWord.replaceLastCharactersWithDots()
                            }
                            linedString += splitCharacter + croppedWord
                            availableWidthInLine = 0
                            latestAddedWord = wordIndex + 1
                        }
                    }
                }
            }
            /// If no words are available for the line, then line won't be added
            guard linedString.count > 0 else { continue }
            linedStrings.append(linedString)
        }
        
        return linedStrings
    }
}
