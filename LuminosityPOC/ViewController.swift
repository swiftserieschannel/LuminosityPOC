//
//  ViewController.swift
//  LuminosityPOC
//
//  Created by Chandra Bhushan on 13/11/20.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


    
    @IBAction func luminosityExample(_ sender: Any) {
        let secondVC = storyboard?.instantiateViewController(withIdentifier: "SecondVC") as! SecondVC
        self.navigationController?.pushViewController(secondVC, animated: true)
    }
    
    @IBAction func usingCamera(_ sender: Any) {
        let thirdVC = storyboard?.instantiateViewController(withIdentifier: "ThirdViewController") as! ThirdViewController
        self.navigationController?.pushViewController(thirdVC, animated: true)
    }

    @IBAction func usingBackCamera(_ sender: Any) {
        
        let thirdVC = storyboard?.instantiateViewController(withIdentifier: "ThirdViewController") as! ThirdViewController
        thirdVC.cameraPosition = .back
        self.navigationController?.pushViewController(thirdVC, animated: true)
        
    }
    
}

