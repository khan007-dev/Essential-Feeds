//
//  FeedItem.swift
//  Essential Feeds
//
//  Created by Khan on 06.03.2024.
//

import Foundation
public struct FeedItem: Equatable {
    let id: UUID
    let description: String?
    let location: String?
    let imageURL: URL
}
