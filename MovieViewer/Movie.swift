//
//  Movie.swift
//  MovieViewer
//
//  Created by Sarn Wattanasri on 1/10/16.
//  Copyright © 2016 Sarn. All rights reserved.
//

import Foundation

struct Movie {
    var id: Int?
    let title: String?
    let overview: String?
    let posterPath: String?
    let voteAverage: Float?
    let releaseDate: NSDate?    
    let isAdult: Bool?
    let revenue: Float?
    let duration: Int?
    let budget: Float?
    let genres: [String]?
    
    var casts: [Celeb]?
}

struct Celeb {
    let name: String?
    let character: String?
    let profilePath: String?
}