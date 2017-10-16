//
//  PopVC.swift
//  MapPixelApp
//
//  Created by Junaid Khan on 12/10/2017.
//  Copyright © 2017 mac. All rights reserved.
//

import UIKit

class PopVC: UIViewController,UIGestureRecognizerDelegate {

    @IBOutlet weak var popUpImage: UIImageView!
    var passedImage : UIImage!
    
    func initData(forImage image: UIImage)
    {
        self.passedImage = image
    }
        
        
    override func viewDidLoad() {
        super.viewDidLoad()
        popUpImage.image = passedImage
        addGesture()
    }
    
    func addGesture()
    {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        tap.numberOfTapsRequired = 2
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }
    
    
    @objc func tapped()
    {
        dismiss(animated: true, completion: nil)
    }
}
