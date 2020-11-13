//
//  SecondVC.swift
//  LuminosityPOC
//
//  Created by Chandra Bhushan on 13/11/20.
//

import UIKit

class SecondVC: UIViewController {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var lightValueLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let light = UIScreen.main.brightness
        lightValueLabel.text = light.description
        switch light {
        case 0 ... 0.3:
            label.text = "LOW LIGHT"
        default:
            label.text = "ENOUGH LIGHT"
        }
    }
}
