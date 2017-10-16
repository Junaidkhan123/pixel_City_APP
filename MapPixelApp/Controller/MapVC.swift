//
//  MapVC.swift
//  MapPixelApp
//
//  Created by Junaid Khan on 02/10/2017.
//  Copyright © 2017 mac. All rights reserved.
//
import UIKit
import Alamofire
import AlamofireImage
import MapKit
import CoreLocation
class MapVC: UIViewController, UIGestureRecognizerDelegate {
    //IBoutlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var pullupview: UIView!
    @IBOutlet weak var pullUpViewHieghtConstraints: NSLayoutConstraint!
    var spinner : UIActivityIndicatorView?
    var progressLabel : UILabel?
    var collectionView : UICollectionView?
    var flowLayout = UICollectionViewFlowLayout()
    // variables
    var locationManager = CLLocationManager()
    let authorizationStatus = CLLocationManager.authorizationStatus()
    let regionRadius : Double = 100
    var screenSize = UIScreen.main.bounds
    var imageURLSArrays = [String]()
    var imageArray = [UIImage]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationServices()
        addDoubleTap()
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "PhotoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        pullupview.addSubview(collectionView!)
        
        registerForPreviewing(with: self, sourceView: collectionView!)
    }
    
    
    func addDoubleTap()
    {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin(sender:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
    }
    
    func addSwipe()
    {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown))
        swipe.direction = .down
        pullupview.addGestureRecognizer(swipe)
    }
    
    func addSpinner()
    {
        spinner = UIActivityIndicatorView()
        spinner?.center = CGPoint(x: screenSize.width / 2, y: 150)
        spinner?.activityIndicatorViewStyle = .whiteLarge
        spinner?.color = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        spinner?.startAnimating()
        collectionView?.addSubview(spinner!)
    }
    
    
    func addLabelProgress()
    {
        progressLabel = UILabel()
        progressLabel?.frame = CGRect(x: (screenSize.width / 2) - 140, y: 175, width: 280, height: 40)
        progressLabel?.font = UIFont(name: "Avenir Next", size: 18)
        progressLabel?.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        progressLabel?.textAlignment = .center
        progressLabel?.text = "Some Photos are downloading !"
        collectionView?.addSubview(progressLabel!)
    }
    
    
    func animateViewUp()
    {
        pullUpViewHieghtConstraints.constant = 300
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    
    @objc func animateViewDown()
    {
        cancelAllSession()
        pullUpViewHieghtConstraints.constant = 1
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    
    
    func removeSpinner()
    {
        if spinner != nil
        {
            spinner?.removeFromSuperview()
        }
    }
    
    
    func removeProgressLabel()
    {
        if progressLabel != nil
        {
            progressLabel?.removeFromSuperview()
        }
    }
    
    // IBActions
    @IBAction func centerMapBtnWasPressed(_ sender: Any) {
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
        {
            centerOnMapUserLoaction()
        }
    }
}


// ********************* Extensions *******************////


extension MapVC : MKMapViewDelegate
{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation
        {
            return nil
        }
        let myAnnotaion = MKPinAnnotationView(annotation: annotation, reuseIdentifier:"droppible")
        myAnnotaion.pinTintColor = #colorLiteral(red: 0.9771530032, green: 0.7062081099, blue: 0.1748393774, alpha: 1)
        myAnnotaion.animatesDrop = true
        return myAnnotaion
    }
    
    
    func centerOnMapUserLoaction()
    {
        guard let cordinates =  locationManager.location?.coordinate else {return}
        let cordinatesRegion = MKCoordinateRegionMakeWithDistance(cordinates, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(cordinatesRegion, animated: true)
    }
    
    
    @objc func dropPin(sender: UITapGestureRecognizer)
    {
        removePin()
        removeSpinner()
        removeProgressLabel()
        cancelAllSession()
        
        imageArray = []
        imageURLSArrays = []
        collectionView?.reloadData()
        
        animateViewUp()
        addSwipe()
        addSpinner()
        addLabelProgress()
        
        
        let touchPoint = sender.location(in: mapView)
        let touchCordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = TouchAblleDropPin(coordinate: touchCordinate, identifier: "droppible")
        mapView.addAnnotation(annotation)
        
        
        let cordinateRegion = MKCoordinateRegionMakeWithDistance(touchCordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(cordinateRegion, animated: true)
        retrieveURLsforImages(forAnnoataion: annotation) { (success) in
            if success
            {
                self.retrievImages(handler: { (finished) in
                    if finished
                    {
                        self.removeSpinner()
                        self.removeProgressLabel()
                        self.collectionView?.reloadData()
                    }
                })
            }
        }
    }
    
    func retrieveURLsforImages(forAnnoataion annotation: TouchAblleDropPin, complete: @escaping (_ status: Bool) ->())
    {
        let url = flickrURL(forApiKey: API_KEY, withAnnotation: annotation, numberOfPhotos: 40)
        Alamofire.request(url).responseJSON { (response) in
            guard let json = response.result.value as? Dictionary<String, AnyObject> else {return}
            let photosDict = json["photos"] as! Dictionary<String,AnyObject>
            let photostArraysDict = photosDict["photo"] as! [Dictionary<String, AnyObject>]
            for photo in photostArraysDict
            {
                let postULR = "https://farm\(photo["farm"]!).staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_h_d.jpg"
                self.imageURLSArrays.append(postULR)
            }
            complete(true)
        }
    }
    
    func retrievImages(handler: @escaping (_ status: Bool) -> ())
    {
        for url in imageURLSArrays
        {
            Alamofire.request(url).responseImage(completionHandler: { (response) in
                guard let image = response.result.value else {return}
                self.imageArray.append(image)
                self.progressLabel?.text = "\(self.imageArray.count) images Downloaded"
                if self.imageArray.count == self.imageURLSArrays.count
                {
                    handler(true)
                }
            })
        }
    }
    
    func cancelAllSession()
    {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (dataTask, uploadTask, downloadTask) in
            dataTask.forEach({$0.cancel()})
            downloadTask.forEach({$0.cancel()})
        }
    }
    
    func removePin()
    {
        for annoation in mapView.annotations
        {
            mapView.removeAnnotation(annoation)
        }
    }
}


extension MapVC : CLLocationManagerDelegate
{
    func configureLocationServices()
    {
        if authorizationStatus == .notDetermined
        {
            locationManager.requestAlwaysAuthorization()
        }
        else
        {
            return
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerOnMapUserLoaction()
    }
}


extension MapVC : UICollectionViewDelegate, UICollectionViewDataSource
{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as? PhotoCell else { return UICollectionViewCell()}
        let imageFromIndex = imageArray[indexPath.row]
        let imageView = UIImageView(image: imageFromIndex)
        cell.addSubview(imageView)
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC else {return}
        popVC.initData(forImage: imageArray[indexPath.row])
        present(popVC, animated: true, completion: nil)
    }
}

extension MapVC : UIViewControllerPreviewingDelegate
{
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionView?.indexPathForItem(at: location), let cell = collectionView?.cellForItem(at: indexPath) else {return nil}
        guard let popvc = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC else {return nil}
        popvc.initData(forImage: imageArray[indexPath.row])
        previewingContext.sourceRect = cell.contentView.frame
        return popvc
        
        
    }
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
            show(viewControllerToCommit, sender: self)
    }
}



















