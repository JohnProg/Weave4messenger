//
//  ColorSelectController.swift
//  msgur
//
//  Created by Roman on 08/05/15.
//  Copyright (c) 2015 Roman Shevtsov. All rights reserved.
//

import UIKit

protocol ColorSelectControllerDelegate {
    func colorSelected(color: UIColor)
}

class ColorSelectController: UIViewController {

    @IBOutlet var buttons: [UIButton]!
    
    var delegate: ColorSelectControllerDelegate?
    
    var selectedColor: UIColor?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        buttons.sort { (b1, b2) -> Bool in
            return b1.tag < b2.tag
        }
        
        for (i, button) in enumerate(buttons) {
            let c = UserDefaults.shared.colorPalette[i]
            button.backgroundColor = c
            button.layer.cornerRadius = 20
        }
        
        moveOffStage()
        
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(animated: Bool) {
        animate(true, completion: nil)
        for (i,c) in enumerate(UserDefaults.shared.colorPalette) {
            if c.isEqual(self.selectedColor) {
                self.selectButton(i)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func selectButton(id: Int) {
        UIView.animateWithDuration(0.5, delay: 0.0, options: .AllowUserInteraction, animations: { () -> Void in
            self.buttons[id].transform = CGAffineTransformMakeScale(0.8, 0.8)
        }, completion: { (_) -> Void in
            UIView.animateWithDuration(0.8, delay: 0.0, options: .Repeat | .Autoreverse | .AllowUserInteraction, animations: { () -> Void in
                self.buttons[id].transform = CGAffineTransformMakeScale(1.2, 1.2)
                }, completion: nil)
        })
    }

    func moveOffStage() {
        let t: [CGFloat] = [300, 150, 50]
        for i in 0...2 {
            self.buttons[i].transform = CGAffineTransformMakeTranslation(-t[i], 0)
            self.buttons[i].alpha = 0
        }
        for i in 3...5 {
            self.buttons[i].transform = CGAffineTransformMakeTranslation(t[i-3], 0)
            self.buttons[i].alpha = 0
        }
    }

    func moveOnStage() {
        for i in 0...2 { self.buttons[i].transform = CGAffineTransformIdentity; self.buttons[i].alpha = 1 }
        for i in 3...5 { self.buttons[i].transform = CGAffineTransformIdentity; self.buttons[i].alpha = 1 }

    }
    
    func animate(appearing: Bool, completion: (()->())?) {
        UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .AllowUserInteraction, animations: {
            if appearing {
                self.moveOnStage()
            } else {
                self.moveOffStage()
            }
        }, completion: { (_) in completion?() })
    }
    
    @IBAction func cancelTap(sender: AnyObject) {
        animate(false, completion: nil)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func buttonTap(sender: UIButton) {
        let id = sender.tag
        self.view.bringSubviewToFront(sender)
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            for button in self.buttons {
                if button.tag == sender.tag {
                    button.transform = CGAffineTransformMakeScale(15.0, 15.0)
                } else {
                    button.alpha = 0.0
                }
            }
            }, completion: { (_) in
                self.delegate?.colorSelected(UserDefaults.shared.colorPalette[sender.tag])
                self.dismissViewControllerAnimated(false, completion: nil)
        })

        
        
        
    }

}
