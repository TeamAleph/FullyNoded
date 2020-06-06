//
//  ErrorView.swift
//  BitSense
//
//  Created by Peter on 16/04/19.
//  Copyright © 2019 Fontaine. All rights reserved.
//

import Foundation
import UIKit

class ErrorView: UIView {
    
    let errorLabel = UILabel()
    let upSwipe = UISwipeGestureRecognizer()
    let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.dark))
    
    @objc func handleSwipes(_ sender: UIGestureRecognizer) {
        
        print("handleSwipes")
     
        UIView.animate(withDuration: 0.2, animations: {
            
            self.backgroundView.frame = CGRect(x: 0,
                                          y: -30,
                                          width: self.backgroundView.frame.width,
                                          height: 30)
            
            self.errorLabel.frame = CGRect(x: 0,
                                           y: -30,
                                           width: self.backgroundView.frame.width,
                                           height: 30)
            
        }) { _ in
            
            UIView.animate(withDuration: 0.2, animations: {
                
                
            }, completion: { _ in
                
                self.backgroundView.removeFromSuperview()
                
            })
            
        }
        
    }
    
    func showErrorView(vc: UIViewController, text: String, isError: Bool) {
        
        self.isUserInteractionEnabled = true
        upSwipe.direction = .up
        upSwipe.addTarget(self, action: #selector(handleSwipes(_:)))
        backgroundView.addGestureRecognizer(self.upSwipe)
        //backgroundView.clipsToBounds = true
        //backgroundView.layer.cornerRadius = 15
        
        let width = vc.view.frame.width
        
        backgroundView.frame = CGRect(x: 0,
                                      y: -30,
                                      width: width,
                                      height: 30)
        
        
        backgroundView.alpha = 0
        
        
        
        if isError {
            
            //backgroundView.backgroundColor = UIColor.red
            errorLabel.textColor = UIColor.red
            
        } else {
            
            //backgroundView.backgroundColor = UIColor(#colorLiteral(red: 0.007097487926, green: 0.6329314721, blue: 0, alpha: 1))
            errorLabel.textColor = UIColor.green
            
        }
        
        errorLabel.frame = CGRect(x: 5,
                                  y: -30,
                                  width: width - 10,
                                  height: 30)
        
        //errorLabel.font = UIFont.init(name: "System-Regular", size: 10)
        errorLabel.font = UIFont.systemFont(ofSize: 12)
        errorLabel.text = text.lowercased()
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        backgroundView.contentView.addSubview(errorLabel)
        vc.view.addSubview(backgroundView)
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.clear
        imageView.image = UIImage(named: "Image-12")
        
        UIView.animate(withDuration: 0.3, animations: {
            
            if vc.navigationController != nil {
                
                guard let y = vc.navigationController?.navigationBar.frame.maxY else {
                    return
                }
                
                self.backgroundView.alpha = 1
                
                self.backgroundView.frame = CGRect(x: 0,
                                                   y: y,
                                                   width: width,
                                                   height: 30)
                
                self.errorLabel.frame = CGRect(x: 0,
                                               y: 0,
                                               width: width,
                                               height: 30)
                
            } else {
                
                self.backgroundView.alpha = 1
                
                self.backgroundView.frame = CGRect(x: 0,
                                                   y: 100,
                                                   width: width,
                                                   height: 30)
                
                self.errorLabel.frame = CGRect(x: 0,
                                               y: 0,
                                               width: width,
                                               height: 30)
            }
            
        }) { _ in
            
            DispatchQueue.main.async {
                
                impact()
                
            }
            
            let deadlineTime = 8.0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + deadlineTime, execute: {
                
                UIView.animate(withDuration: 0.3, animations: {
                    
                    self.backgroundView.frame = CGRect(x: 0,
                                                       y: -30,
                                                       width: width,
                                                       height: 30)
                    
                    self.errorLabel.frame = CGRect(x: 0,
                                                   y: -30,
                                                   width: width,
                                                   height: 30)
                    
                }) { _ in
                    
                    UIView.animate(withDuration: 0.3, animations: {
                        
                        
                    }, completion: { _ in
                        
                        self.backgroundView.removeFromSuperview()
             
                    })
                    
                }
                
            })
            
        }
        
    }
    
}
