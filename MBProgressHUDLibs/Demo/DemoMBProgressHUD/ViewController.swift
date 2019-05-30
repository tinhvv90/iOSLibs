//
//  ViewController.swift
//  DemoMBProgressHUD
//
//  Created by CenHomes on 5/30/19.
//  Copyright © 2019 Simson. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func showMBProgressHub(_ sender: Any) {
        let hub = MBProgressHUD.showAdded(to: self.view, animated: true)
        
        hub.hide(animated: true, afterDelay: 5)
    }
    
}

