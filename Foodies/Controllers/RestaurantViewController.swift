//
//  RestaurantViewController.swift
//  Foodies
//
//  Created by mohamed fawzy on 10/21/18.
//  Copyright © 2018 mohamed fawzy. All rights reserved.
//

import UIKit

class RestaurantViewController: UIViewController {
    

    
    var manager = RestaurantDataManager()
    var selectedRestaurant:RestaurantItem?
    var selectedCity:LocationItem?
    var selectedType:String?
    
    @IBOutlet weak var collectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        createData()
        setupTitle()
       collectionView.prefetchDataSource = self
    }
    
    func createData() {
        guard let location = selectedCity?.city, let filter = selectedType else { return }
        manager.fetch(by: location, withFilter: filter) {
            if manager.numberOfItems() > 0 {
                collectionView.backgroundView = nil
            }
            else {
                let view = NoDataView(frame: CGRect(x: 0, y: 0, width: collectionView.frame.width, height: collectionView.frame.height))
                    view.set(title: "Restaurants")
                    view.set(description: "No restaurants found.")
                    collectionView.backgroundView = view
            }
            collectionView.reloadData()
        }
    }
    
    func setupTitle() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        if let city = selectedCity?.city, let state = selectedCity?.state {
            title = "\(city.uppercased()), \(state.uppercased())"
        }
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segue.showDetail.rawValue {
            if let index = collectionView.indexPathsForSelectedItems?.first {
                selectedRestaurant = manager.restaurantItem(at: index)
                let vc = segue.destination as! RestaurantDetailViewController
                vc.selectedRestaurant = selectedRestaurant
            }
        }
    }
    
}



//MARK:- collectionView dataSource
extension RestaurantViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return manager.numberOfItems()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "restaurantCell", for: indexPath) as! RestaurantCell
        let item = manager.restaurantItem(at: indexPath)
        if let name = item.name { cell.titleLabel.text = name }
        if let cuisine = item.subtitle { cell.cuisineLabel.text = cuisine }
        cell.imageView.image = item.image
        if item.task == nil && item.image == nil {
            self.collectionView(collectionView, prefetchItemsAt: [indexPath])
        }

        return cell
    }
}

extension RestaurantViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let restaurant = manager.restaurantItem(at: indexPath)
            guard restaurant.image == nil else {return}
            guard restaurant.task == nil else{return}
            
            if let s =  restaurant.imageURL {
                let url = URL(string: s)!
                restaurant.task = URLSession.shared.dataTask(with: url, completionHandler: { (data, res, error) in
                    restaurant.task = nil
                    if let d = data {
                        restaurant.image = UIImage(data:d)
                        DispatchQueue.main.async {
                            collectionView.reloadItems(at: [indexPath])
                        }
                    }
                })
                restaurant.task.resume()
            }
            
        }
    }

    
}
