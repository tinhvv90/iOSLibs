//
//  ViewController.swift
//  DemoHMSegmentedControl
//
//  Created by CenHomes on 5/30/19.
//  Copyright © 2019 Simson. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    let segmentedControl = HMSegmentedControl(sectionTitles: ["One", "Two", "Three"])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(segmentedControl!)
        segmentedControl?.backgroundColor = #colorLiteral(red: 0.7683569193, green: 0.9300123453, blue: 0.9995251894, alpha: 1)
        segmentedControl?.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl?.selectionIndicatorLocation = .down
        segmentedControl?.selectionIndicatorColor = #colorLiteral(red: 0.1142767668, green: 0.3181744218, blue: 0.4912756383, alpha: 1)
        
        segmentedControl?.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1),
            NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17)
        ]
        
        segmentedControl?.selectedTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor : #colorLiteral(red: 0.05439098924, green: 0.1344551742, blue: 0.1884709597, alpha: 1),
            NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 17)
        ]
        
        segmentedControl?.indexChangeBlock = { index in
            print(index)
            //            print(self.segmentedControl.selectedSegmentIndex)
            //            self.segmentedControl.selectedSegmentIndex = 1
        }
        
        NSLayoutConstraint.activate(
            [(segmentedControl?.leftAnchor.constraint(equalTo: view.leftAnchor))!,
             (segmentedControl?.heightAnchor.constraint(equalToConstant: 50))!,
             (segmentedControl?.rightAnchor.constraint(equalTo: view.rightAnchor))!,
             (segmentedControl?.topAnchor.constraint(equalTo: view.topAnchor, constant: 40))!]
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        segmentedControl?.selectedSegmentIndex = 0
    }
}

