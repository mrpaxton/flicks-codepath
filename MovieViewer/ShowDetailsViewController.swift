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
    var item: Movie?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        showTitle!.text = item?.title
        showOverview!.text = item?.overview
        let posterPath = item?.posterPath
        let baseUrl = "http://image.tmdb.org/t/p/w500"
        let imageUrl = NSURL(string: baseUrl + (posterPath! as String ?? "") )
        poster!.setImageWithURL(imageUrl!)
        
        //set background color of the image view
        self.view.backgroundColor = UIColor(hexString: "#f4792099")
        
        
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
