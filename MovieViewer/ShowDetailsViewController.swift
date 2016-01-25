//
//  ShowDetailsViewController.swift
//  MovieViewer
//
//  Created by Sarn Wattanasri on 1/10/16.
//  Copyright © 2016 Sarn. All rights reserved.
//

import UIKit

class ShowDetailsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
   
    @IBOutlet weak var celebCollectionView: UICollectionView!
    @IBOutlet weak var showTitle: UILabel?
    @IBOutlet weak var showOverview: UILabel?
    @IBOutlet weak var poster: UIImageView?
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var duration: UILabel!
    @IBOutlet weak var movieScrollView: UIScrollView!
    @IBOutlet weak var voteAverageLabel: UILabel!
    @IBOutlet weak var genresTextLabel: UILabel!
    
    var item: Movie?
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (item?.casts?.count)!
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CelebCollectionCell", forIndexPath: indexPath) as! CelebCollectionCell
        let celeb = item?.casts![indexPath.row]
        return celebToCollectionViewCell(celeb!, cell: cell)
    }
    
    func celebToCollectionViewCell(celeb: Celeb, cell: CelebCollectionCell) -> UICollectionViewCell {
        let characterName = celeb.character
        let name = celeb.name
        let celebProfilePath = celeb.profilePath ?? ""
        let baseUrl = "http://image.tmdb.org/t/p/w500"
        let imageUrl = NSURL(string: baseUrl + celebProfilePath)
        
        //set to the cell
        cell.characterLabel.text = characterName
        cell.celebNameLabel.text = name
        cell.celebImageView.setImageWithURL( imageUrl! )
        return cell
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        movieScrollView.contentSize = CGSizeMake(400, 2000)
        celebCollectionView.dataSource = self
        celebCollectionView.delegate = self

        // Do any additional setup after loading the view.
        showTitle!.text = item?.title
        showOverview!.text = item?.overview
        
        //more details about the movie
        duration.text =  String(item?.duration! ?? 0)
        voteAverageLabel.text =  String( roundFloat( item!.voteAverage! ?? 0.0 ))
        
        //castOneImage.setImageWithURL(NSURL(string: baseUrl + (item?.casts?[0].profilePath)!)!) //found nil while unwrapping
        let posterPath = item?.posterPath ?? ""
        let baseUrl = "http://image.tmdb.org/t/p/w500"
        let imageUrl = NSURL(string: baseUrl + posterPath)
        //load low resolution image first then larger image
        let baseUrlSmall = "http://image.tmdb.org/t/p/w92"
        let imageUrlSmall = NSURL(string: baseUrlSmall + posterPath)
        let smallImageRequest = NSURLRequest(URL: imageUrlSmall!)
        let largeImageRequest = NSURLRequest(URL: imageUrl!)
        loadLowResolutionThenLargerImages(smallImageRequest,
            largeImageRequest: largeImageRequest, poster: poster )
        
        //configure movieScrollView
        movieScrollView.contentSize = CGSize(width: movieScrollView.frame.size.width,
            height: infoView.frame.origin.y + infoView.frame.size.height)
        showOverview!.sizeToFit()
    }
    
    private func loadLowResolutionThenLargerImages(smallImageRequest: NSURLRequest,
        largeImageRequest: NSURLRequest, poster: UIImageView?) {
            
        poster!.setImageWithURLRequest(smallImageRequest,
            placeholderImage: nil ,
            success: { (smallImageRequest, smallImageResponse, smallImage) -> Void in
                self.poster!.alpha = 0.0
                self.poster!.image = smallImage
                self.poster!.contentMode = .ScaleAspectFit
                
                UIView.animateWithDuration(0.3, animations: { self.poster!.alpha = 1.0 },
                    completion: { (success) -> Void in
                        self.poster!.setImageWithURLRequest(largeImageRequest,
                            placeholderImage: smallImage,
                            success: { (largeImageRequest, largeImageResponse, largeImage) -> Void in
                                self.poster!.image = largeImage
                            }, failure: { (request, response, error ) -> Void in
                                self.poster!.image = UIImage(named: "MovieHolder")
                        })
                    }
                )
            }, failure: {(request, response, error) -> Void in
                self.poster!.image = UIImage(named: "MovieHolder")
            }
        )
    }
    
    func roundFloat(value: Float) -> Float {
        return roundf(value * 100) / 100
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
