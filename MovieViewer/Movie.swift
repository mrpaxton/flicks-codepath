//
//  Movie.swift
//  MovieViewer
//
//  Created by Sarn Wattanasri on 1/10/16.
//  Copyright © 2016 Sarn. All rights reserved.
//

import Foundation

struct Movie {
    let id: Int?
    let title: String?
    let overview: String?
    let posterPath: String?
    let voteAverage: Float?
    let releaseDate: NSDate?
}

struct TVShow {
    let id: Int?
    let title: String?
    let overview: String?
    let posterPath: String?
    let voteAverage: Float?
    let firstAirDate: NSDate?
}