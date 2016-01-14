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
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var collectionView: UICollectionView!
    
    @IBOutlet weak var movieSearchBar: UISearchBar!
    var movies: [NSDictionary]?
    
    
    //UIRefreshControl - for pull to refresh
    var refreshControl: UIRefreshControl!
    
    @IBOutlet weak var networkErrorView: UIView!
    @IBOutlet weak var swapViewBarButton: UIButton!
    
    var movieList:  [Movie] = []
    var filteredMovies: [Movie] = []
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set delegates and datasources
        tableView.dataSource = self
        tableView.delegate = self
        movieSearchBar.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
        
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
        delay(2) { SwiftLoader.show(title: "Loading...", animated: true) }
        
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(request,
            completionHandler: { (dataOrNil, response, error) in
                //delay to see the effect on the simulator
                self.delay(3) { SwiftLoader.hide() }
                
                if let data = dataOrNil {
                    if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                        data, options:[]) as? NSDictionary {
                            self.movies = responseDictionary["results"] as? [NSDictionary]
                            
                            //build a list of Movies
                            for movie in self.movies! {
                                let id = movie["id"] as! Int
                                let title = movie["title"] as! String
                                let overview = movie["overview"] as! String
                                let posterPath = movie["poster_path"] as? String
                                let voteAverage = movie["vote_average"] as? Float
                                let releaseDate = movie["release_date"] as? NSDate
                                let currentMovie = Movie( id: id, title: title,
                                    overview: overview, posterPath: posterPath,
                                    voteAverage: voteAverage, releaseDate: releaseDate)
                                self.movieList.append( currentMovie )
                                self.filteredMovies.append( currentMovie )
                            }
                            
                            self.tableView.reloadData()
                            self.collectionView.reloadData()
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
    
    func refreshMovieData() {
        tableView.reloadData()
        collectionView.reloadData()
    }
    
    @IBAction func onSwapViewBarButtonTouched(sender: UIButton) {
        var fromView: UIView!
        var toView: UIView!
        
        if self.tableView?.superview == self.view {
            (fromView, toView) = (self.tableView, self.collectionView)
        } else {
            (fromView, toView) = (self.collectionView, self.tableView)
        }
        
        toView?.frame = fromView.frame
        UIView.transitionFromView(fromView, toView: toView,
            duration: 0.15, options: UIViewAnimationOptions.TransitionFlipFromRight, completion: nil)
        
        if fromView == tableView {
            swapViewBarButton.setImage( UIImage(named: "TableIcon"), forState: .Normal )
        } else {
            swapViewBarButton.setImage( UIImage(named: "CollectionIcon"), forState: .Normal )
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
            let chosenIndex = sender is MovieCollectionCell ?
                self.collectionView.indexPathForCell((sender as? MovieCollectionCell)!)!.row :
                self.tableView.indexPathForCell((sender as? MovieCell)!)!.row
            
            if let showDetailsVC = segue.destinationViewController as? ShowDetailsViewController {
                showDetailsVC.item = filteredMovies[chosenIndex]
            }
        }
    }
}


extension MoviesTabViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredMovies.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        
        let movie = filteredMovies[indexPath.row]
        return movieToTableViewCell(movie, cell: cell)
    }
    
    func movieToTableViewCell(movie: Movie, cell: MovieCell) -> UITableViewCell {
        let title = movie.title
        let overview = movie.overview
        let posterPath = movie.posterPath
        let baseUrl = "http://image.tmdb.org/t/p/w500"
        let imageUrl = NSURL(string: baseUrl + (posterPath ?? "") )
        let request = NSURLRequest(URL: imageUrl!)
        let placeholderImage = UIImage(named: "MovieHolder")
        //** setImageWithURL() - from cocoapods AFNetworking
        //** cell.movieImageView.setImageWithURL(imageUrl!) - without fade-in effect
        
        //fade-in effect on movie images
        cell.movieImageView.setImageWithURLRequest(request, placeholderImage: placeholderImage, success: { (request, response, imageData) -> Void in
            UIView.transitionWithView(cell.movieImageView, duration: 0.15, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: { cell.movieImageView.image = imageData }, completion: nil   )
            }, failure: nil)
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        cell.backgroundColor = UIColor(hexString: "#f47920cc")
        return cell
    }
}

extension MoviesTabViewController: UISearchBarDelegate {
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        searchBar.setShowsCancelButton(true, animated: true)
        if !searchText.isEmpty {
            //TODO: when didBackwardDelete, re-filter the movie list and reload the table
            
            filteredMovies = filteredMovies.filter({
                ($0.title)!.rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil
            })
            refreshMovieData()
        } else {
            filteredMovies = movieList
            refreshMovieData()
            searchBar.endEditing(true)
        }
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        (filteredMovies, searchBar.text) = (movieList, "")
        refreshMovieData()
    }
}

extension MoviesTabViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.filteredMovies.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("MovieCollectionCell", forIndexPath: indexPath) as! MovieCollectionCell
        let movie = filteredMovies[indexPath.row]
        return movieToCollectionViewCell(movie , cell: cell)
    }
    
    func movieToCollectionViewCell(movie: Movie, cell: MovieCollectionCell) -> UICollectionViewCell {
        let title = movie.title
        let posterPath = movie.posterPath
        
        let baseUrl = "http://image.tmdb.org/t/p/w500"
        let imageUrl = NSURL(string: baseUrl + (posterPath ?? "") )
        let request = NSURLRequest(URL: imageUrl!)
        
        let placeholderImage = UIImage(named: "MovieHolder")
        
        //fade-in effect on movie images
        cell.cellImageView.setImageWithURLRequest(request, placeholderImage: placeholderImage, success: { (request, response, imageData) -> Void in
            UIView.transitionWithView(cell.cellImageView, duration: 0.15, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: { cell.cellImageView.image = imageData }, completion: nil   )
            }, failure: nil)
        cell.titleLabel.text = title
        cell.backgroundColor = UIColor(hexString: "#f47920cc")
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("movieSegue", sender: self.collectionView.cellForItemAtIndexPath(indexPath))
    }
}



