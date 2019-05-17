//
//  ReactionViewStyle.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 09/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

public struct ReactionViewStyle: Hashable {
    
    public let alignment: MessageViewStyle.Alignment
    public let font: UIFont
    public let textColor: UIColor
    public let backgroundColor: UIColor
    public let chatBackgroundColor: UIColor
    public private(set) var tailImage: UIImage

    init(alignment: MessageViewStyle.Alignment = .left,
         font: UIFont = .chatSmall,
         textColor: UIColor = .white,
         backgroundColor: UIColor = .chatDarkGray,
         chatBackgroundColor: UIColor = .white,
         cornerRadius: CGFloat = .reactionsCornerRadius,
         messageCornerRadius: CGFloat = .messageCornerRadius) {
        self.alignment = alignment
        self.font = font
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.chatBackgroundColor = chatBackgroundColor
        
        tailImage = .renderTailImage(smallRadius: round(cornerRadius * 0.8), bigRadius: messageCornerRadius, alignment: alignment)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(alignment)
        hasher.combine(font)
        hasher.combine(textColor)
        hasher.combine(backgroundColor)
        hasher.combine(chatBackgroundColor)
        hasher.combine(tailImage)
    }
}