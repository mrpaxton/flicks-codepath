//
//  ShowDetailsViewController.swift
//  MovieViewer
//
//  Created by Sarn Wattanasri on 1/10/16.
//  Copyright © 2016 Sarn. All rights reserved.
//

import UIKit

class ShowDetailsViewController: UIViewController {

   
    @IBOutlet weak var showTitle: UILabel?
    @IBOutlet weak var showOverview: UILabel?
    @IBOutlet weak var poster: UIImageView?
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var movieScrollView: UIScrollView!
    var item: Movie?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        showTitle!.text = item?.title
        showOverview!.text = item?.overview
        let posterPath = item?.posterPath ?? ""
        let baseUrl = "http://image.tmdb.org/t/p/w500"
        let imageUrl = NSURL(string: baseUrl + (posterPath))
        poster!.setImageWithURL(imageUrl!)
        
        //set background color of the image view
        self.view.backgroundColor = UIColor(hexString: "#f4792099")
        
        
        //configure movieScrollView
        let contentWidth = view.frame.width
        let contentHeight = view.frame.height
        movieScrollView.contentSize = CGSizeMake(contentWidth, contentHeight)
        
        poster!.frame = CGRectMake(15, -100, view.bounds.width - 30, view.bounds.height - 10)
        infoView.frame = CGRectMake(15, 450, view.bounds.width - 30, 400)
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
