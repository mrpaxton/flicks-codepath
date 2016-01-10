//
//  MoviesViewController.swift
//  MovieViewer
//
//  Created by Sarn Wattanasri on 1/5/16.
//  Copyright © 2016 Sarn. All rights reserved.
//

import UIKit
import AFNetworking
import SwiftLoader


class MoviesTabViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var movieSearchBar: UISearchBar!
    var movies: [NSDictionary]?
    var filteredMovies: [NSDictionary]?
    
    //UIRefreshControl - for pull to refresh
    var refreshControl: UIRefreshControl!
    
    @IBOutlet weak var networkErrorView: UIView!
    
    var movieList:  [Movie] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set delegates and datasources
        tableView.dataSource = self
        tableView.delegate = self
        movieSearchBar.delegate = self
        
        pullRefreshControl()
        setupProgressBar()
        setupMoviesData()
        
        toggleNetworkErrorView(false)
    }
    
    //private helper: pull to refresh control. Add the UIRefershControl to the table view
    func pullRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self,
            action: "onRefresh", forControlEvents: UIControlEvents.ValueChanged)
        tableView.insertSubview(refreshControl, atIndex: 0)
        
    }
    
    //private helper: setup data of movies from api call
    func setupMoviesData() {
        //network call
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = NSURL(string:"https://api.themoviedb.org/3/movie/now_playing?api_key=\(apiKey)")
        let request = NSURLRequest(URL: url!)
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate:nil,
            delegateQueue:NSOperationQueue.mainQueue()
        )
        
        //delay to see the effect on the simulator
        delay(1.0) { SwiftLoader.show(title: "Loading...", animated: true) }
        
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(request,
            completionHandler: { (dataOrNil, response, error) in
                //delay to see the effect on the simulator
                self.delay(3.0) { SwiftLoader.hide() }
                
                if let data = dataOrNil {
                    if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                        data, options:[]) as? NSDictionary {
                            self.movies = responseDictionary["results"] as? [NSDictionary]
                            self.filteredMovies = responseDictionary["results"] as? [NSDictionary]
                            self.tableView.reloadData()
                            
                            //build a list of Movies
                            for movie in self.movies! {
                                let id = movie["id"] as! Int
                                let title = movie["title"] as! String
                                let overview = movie["overview"] as! String
                                let posterPath = movie["poster_path"] as? String
                                let voteAverage = movie["vote_average"] as? Float
                                let releaseDate = movie["release_date"] as? NSDate
                                let currentMovie = Movie( id: id, title: title, overview: overview, posterPath: posterPath, voteAverage: voteAverage, releaseDate: releaseDate)
                                self.movieList.append( currentMovie )
                            }
                    }
                }
                
                if error != nil {
                    //show network error message box
                    self.toggleNetworkErrorView(true)
                }
        });
        task.resume()
        
    }
    
    //private helper: setup and config a SwiftLoader progress bar
    func setupProgressBar() {
        var config : SwiftLoader.Config = SwiftLoader.Config()
        config.size = 120
        config.spinnerColor = .redColor()
        config.foregroundColor = .blackColor()
        config.foregroundAlpha = 0.9
        //set new config for SwiftLoader
        SwiftLoader.setConfig(config)
        //** Note: SwiftLoader is not updated for the new version of Swift.
        //** I modified the library a little
    }
    
    //callboack for UIRefreshControl
    func onRefresh() {
        delay(2, closure: {
            self.refreshControl.endRefreshing()
        })
    }
    
    //private helper:delay for the refresh control and progress bar
    func delay(delay:Double, closure: () -> ()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC) )
            ),
            dispatch_get_main_queue(), closure
        )
    }
    
    func toggleNetworkErrorView( visible: Bool) {
        //insert below searchbar and above tableview
        if visible {
            networkErrorView.hidden = false
            UIView.animateWithDuration(0.5, delay: 0.1, options: .CurveEaseOut, animations: {
                self.view.bringSubviewToFront(self.networkErrorView)
                self.tableView.frame.origin.y += self.movieSearchBar.frame.height
                }, completion: nil
            )
            
        } else {
            networkErrorView.hidden = true
        }
    }
    
    
    //style the status bar
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "movieSegue" {
            
            let chosenIndex = self.tableView.indexPathForCell(sender as! MovieCell)
            
            if let showDetailsVC = segue.destinationViewController as? ShowDetailsViewController {
                showDetailsVC.item = movieList[chosenIndex!.row]
            }
        }
    }
}


extension MoviesTabViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let filteredMovies = filteredMovies else {
            return 0
        }
        return filteredMovies.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        
        let movie = filteredMovies![indexPath.row]
        let title = movie["title"] as! String
        let overview = movie["overview"] as! String
        
        let posterPath = movie["poster_path"]
        
        let baseUrl = "http://image.tmdb.org/t/p/w500"
        let imageUrl = NSURL(string: baseUrl + (posterPath as? String ?? "") )
        let request = NSURLRequest(URL: imageUrl!)
        let placeholderImage = UIImage(named: "MovieHolder")
        
        
        //setImageWithURL() - from cocoapods AFNetworking
        //cell.movieImageView.setImageWithURL(imageUrl!) - without fadein effect
        
        //fade-in effect on movie images
        cell.movieImageView.setImageWithURLRequest(request, placeholderImage: placeholderImage, success: { (request, response, imageData) -> Void in
            UIView.transitionWithView(cell.movieImageView, duration: 0.19, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: { cell.movieImageView.image = imageData }, completion: nil   )
            }, failure: nil)
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        cell.backgroundColor = UIColor(hexString: "#f47920bb")
        return cell
    }
    
}

extension MoviesTabViewController: UISearchBarDelegate {
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        searchBar.setShowsCancelButton(true, animated: true)
        if !searchText.isEmpty {
            //TODO: when didBackwardDelete, re-filter the movie list and reload the table
            
            filteredMovies = filteredMovies!.filter({
                ($0["title"] as! String).rangeOfString(searchText,
                    options: .CaseInsensitiveSearch) != nil
            })
            tableView.reloadData()
        } else {
            filteredMovies = movies
            tableView.reloadData()
            searchBar.endEditing(true)
        }
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        filteredMovies = movies
        searchBar.text = ""
        tableView.reloadData()
    }
}


