//
//  DefectKanbanCollectionViewController.swift
//  RallyKit
//
//  Created by Shao-Ping Lee on 4/24/16.
//
//

import UIKit

class DefectKanbanCollectionViewController: UICollectionViewController {
    let items = [["Item1", "Item2", "Item3", "Item4"],
    ["Item5", "Item6", "Item7"],
    ["Item8", "Item9", "Item10", "Item11", "Item12"],
     ["Item13", "Item14"]]
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items[section].count
    }
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return items.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! DefectCell
        cell.formattedIDLabel.text = items[indexPath.section][indexPath.item]
        return cell
    }
}
