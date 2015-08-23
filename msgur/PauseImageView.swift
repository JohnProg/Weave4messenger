//
//  PauseImageView.swift
//  msgur
//
//  Created by asdfgh1 on 11/05/15.
//  Copyright (c) 2015 Roman Shevtsov. All rights reserved.
//

import UIKit

class PauseImageView: UIImageView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.alpha = 0.0
    }
    
    override func startAnimating() {

        self.stopAnimating()
        UIView.animateWithDuration(0.8, delay: 0.0, options: .Repeat | .Autoreverse, animations: { () -> Void in
            self.alpha = 1.0
            }, completion: nil)
    }
    
    override func stopAnimating() {

        self.layer.removeAllAnimations()
        self.alpha = 0.0
    }
    
    
}
