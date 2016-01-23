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
    @IBOutlet weak var networkErrorView: UIView!
    var refreshControl: UIRefreshControl!
    var movieList:  [Movie] = []
    var filteredMovies: [Movie] = []
    var endpoint: String!
    var searchButtonItem: UIBarButtonItem!
    var swapViewButton: UIButton!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        movieSearchBar.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
        
        pullRefreshControl()
        setupProgressBar()
        setupMoviesData()
        customizeNavigationBar()
        toggleNetworkErrorView(false)
        
    }
    
    func didTapSearchButton(sender: AnyObject?) {
        //show search bar
        movieSearchBar.hidden = true
        movieSearchBar.alpha = 0.3
        navigationItem.titleView = movieSearchBar
        navigationItem.setRightBarButtonItem(nil , animated: true)
        UIView.animateWithDuration(0.2,
            animations: { Void in
                self.movieSearchBar.hidden = false
                self.movieSearchBar.alpha = 1
            }, completion: { finished in
                self.movieSearchBar.setShowsCancelButton(true, animated: false)
                self.movieSearchBar.becomeFirstResponder()
            }
        )
    }
    
    func hideTopBar() {
        navigationItem.setRightBarButtonItem( searchButtonItem, animated: true)
        navigationItem.titleView = nil
        movieSearchBar.text = ""
    }
    
    private func customizeNavigationBar() {
        self.navigationItem.title = "Flicks"
        if let navigationBar = navigationController?.navigationBar {
            //navigationBar.setBackgroundImage(UIImage(named: "MovieHolder"), forBarMetrics: .Default)
            navigationBar.tintColor = UIColor(hexString: "#333333ff")
            
            let shadow = NSShadow()
            shadow.shadowColor = UIColor(hexString: "#f47920aa")?.colorWithAlphaComponent(0.5)
            shadow.shadowOffset = CGSizeMake(1, 1);
            shadow.shadowBlurRadius = 2;
            navigationBar.titleTextAttributes = [
                NSFontAttributeName : UIFont.boldSystemFontOfSize(25),
                NSForegroundColorAttributeName : UIColor(hexString: "#333333ee")!,
                NSShadowAttributeName : shadow
            ]
        }
        
        //customize text to show in the header
        switch tabBarController?.selectedIndex {
        case 0?:
            navigationItem.title = "Now Playing"
        case 1?:
            navigationItem.title = "Top Rated"
        default: break
        }
        
        //setup for search bar
        movieSearchBar.hidden = true
        searchButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Search, target: self, action: "didTapSearchButton:")
        navigationItem.rightBarButtonItem = searchButtonItem
        
        //preare button for the left navigationitem's bar item button and add negative spacer
        let tableIcon = UIImage(named: "CollectionIcon")
        swapViewButton = UIButton(type: UIButtonType.Custom)
        swapViewButton.addTarget(self,
            action: "onSwapViewBarButtonTouched:", forControlEvents: .TouchUpInside)
        swapViewButton.frame = CGRectMake(0, 0, 44, 44)
        swapViewButton.setImage(tableIcon , forState: UIControlState.Normal)
        let tableBarItemButton = UIBarButtonItem(customView: swapViewButton)
        let negativeSpacer: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: nil , action: nil )
        negativeSpacer.width = -15
        navigationItem.leftBarButtonItems = [negativeSpacer, tableBarItemButton]
    }
    
    @IBAction func onSwapViewBarButtonTouched(sender: UIButton) {
        var fromView: UIView!, toView: UIView!
        //check present view and prepare fromView and toView
        let isTableViewPresent = tableView?.superview == self.view
        (fromView, toView) = isTableViewPresent ?
            (tableView, collectionView) : (collectionView, tableView)
        
        toView?.frame = fromView.frame
        UIView.transitionFromView(fromView, toView: toView,
            duration: 0.15, options: UIViewAnimationOptions.TransitionFlipFromRight, completion: nil)
        
        //toggle image icon of the fromView/toView
        if fromView == tableView {
            swapViewButton.setImage( UIImage(named: "TableIcon"), forState: .Normal )
        } else {
            swapViewButton.setImage( UIImage(named: "CollectionIcon"), forState: .Normal )
        }
    }
    
    //private helper: pull to refresh control. Add the UIRefershControl to the table view
    private func pullRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self,
            action: "onRefresh", forControlEvents: UIControlEvents.ValueChanged)
        tableView.insertSubview(refreshControl, atIndex: 0)
    }
    
    //private helper: setup data of movies from api call
    private func setupMoviesData() {
        
        let (request, session) = prepareNetworkRequestSession()
        SwiftLoader.show(title: "Loading...", animated: true)
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(request,
            completionHandler: { (dataOrNil, response, error) in
                //delay to see the effect on the simulator
                self.delay(2) { SwiftLoader.hide() }
                if let data = dataOrNil {
                    if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                        data, options:[]) as? NSDictionary {
                            let movies = responseDictionary["results"] as? [NSDictionary]
                            for movie in movies! {
                                let currentMovie = self.movieDictToModel(movie)
                                self.movieList.append( currentMovie )
                                self.filteredMovies.append( currentMovie )
                            }
                            self.refreshMovieData()
                    }
                }
                if error != nil {
                    self.toggleNetworkErrorView(true)
                }
        });
        task.resume()
    }
    
    //private helper: handle network call
    private func prepareNetworkRequestSession() -> (NSURLRequest, NSURLSession) {
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = NSURL(string:"https://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiKey)")
        let request = NSURLRequest(URL: url!)
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate:nil,
            delegateQueue:NSOperationQueue.mainQueue()
        )
        return (request, session)
    }
    
    private func movieDictToModel(movie: NSDictionary) -> Movie {
        let id = movie["id"] as! Int
        let title = movie["title"] as! String
        let overview = movie["overview"] as! String
        let posterPath = movie["poster_path"] as? String
        let voteAverage = movie["vote_average"] as? Float
        let releaseDate = movie["release_date"] as? NSDate
        return Movie( id: id, title: title, overview: overview, posterPath: posterPath,
            voteAverage: voteAverage, releaseDate: releaseDate)
    }
    
    //private helper: setup and config a SwiftLoader progress bar
    func setupProgressBar() {
        var config : SwiftLoader.Config = SwiftLoader.Config()
        config.size = 120
        config.spinnerColor = .redColor()
        config.foregroundColor = .blackColor()
        config.foregroundAlpha = 0.9
        //set new config for SwiftLoader
        //** Note: SwiftLoader not updated for the new version of Swift - I modified the lib
        SwiftLoader.setConfig(config)
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
    
    private func toggleNetworkErrorView( visible: Bool) {
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
    
    private func refreshMovieData() {
        tableView.reloadData()
        collectionView.reloadData()
    }
    
    //private helper: fade-in effect on image load from network
    private func fadeInImageOnNetworkCall<T: UIView>(request: NSURLRequest, placeholderImage: UIImage, duration: NSTimeInterval, cell: T ) -> T? {
        if let movieCell = cell as? MovieCell {
            movieCell.cellImageView.setImageWithURLRequest(request, placeholderImage: placeholderImage, success: { (request, response, imageData) -> Void in
                UIView.transitionWithView(movieCell.cellImageView, duration: duration, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: { movieCell.cellImageView.image = imageData }, completion: nil   )
                }, failure: nil)
            return movieCell as? T
        } else if let movieCell = cell as? MovieCollectionCell {
            movieCell.cellImageView.setImageWithURLRequest(request, placeholderImage: placeholderImage, success: { (request, response, imageData) -> Void in
                UIView.transitionWithView(movieCell.cellImageView, duration: duration, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: { movieCell.cellImageView.image = imageData }, completion: nil   )
                }, failure: nil)
            return movieCell as? T
        }
        return nil
    }
    
    //private helper: style the selected cell
    func beautifySelectedCell(cell: UITableViewCell) -> UITableViewCell {
        //cell.selectionStyle = .None
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.grayColor()
        cell.selectedBackgroundView = backgroundView
        return cell
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
        let baseUrl = "http://image.tmdb.org/t/p/w300"
        let imageUrl = NSURL(string: baseUrl + (posterPath ?? "") )
        let request = NSURLRequest(URL: imageUrl!)
        let placeholderImage = UIImage(named: "MovieHolder")
        
        let movieCell = fadeInImageOnNetworkCall(request, placeholderImage: placeholderImage!, duration: 0.15, cell: cell) as MovieCell!
        
        movieCell.titleLabel.text = title
        movieCell.overviewLabel.text = overview
        movieCell.backgroundColor = UIColor(hexString: "#f47920cc")
        
        //customize the cell selection effects
        let beautifiedSelectedCell = beautifySelectedCell(movieCell)
        return beautifiedSelectedCell
    }
}

extension MoviesTabViewController: UISearchBarDelegate {
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        searchBar.setShowsCancelButton(true, animated: true)
        
        filteredMovies = searchText.isEmpty ? movieList : movieList.filter({
            $0.title!.rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil
        })
        refreshMovieData()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        (filteredMovies, searchBar.text) = (movieList, "")
        refreshMovieData()
        searchBar.resignFirstResponder()
    }
}

extension MoviesTabViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.filteredMovies.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("MovieCollectionCell", forIndexPath: indexPath) as! MovieCollectionCell
        let movie = filteredMovies[indexPath.row]
        return movieToCollectionViewCell(movie , cell: cell)
    }
    
    func movieToCollectionViewCell(movie: Movie, cell: MovieCollectionCell) -> UICollectionViewCell {
        let title = movie.title
        let posterPath = movie.posterPath
        let baseUrl = "http://image.tmdb.org/t/p/w300"
        let imageUrl = NSURL(string: baseUrl + (posterPath ?? "") )
        let request = NSURLRequest(URL: imageUrl!)
        let placeholderImage = UIImage(named: "MovieHolder")
        
        let movieCell = fadeInImageOnNetworkCall(request, placeholderImage: placeholderImage!, duration: 0.15, cell: cell) as MovieCollectionCell!
        movieCell.titleLabel.text = title
        movieCell.backgroundColor = UIColor(hexString: "#f47920cc")
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.grayColor()
        movieCell.selectedBackgroundView = backgroundView
        return movieCell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("movieSegue", sender: self.collectionView.cellForItemAtIndexPath(indexPath))
    }
}


