//
//  AboutViewController.swift
//  MapItOut
//
//  Created by Portia Wang on 8/2/17.
//  Copyright © 2017 Portia Wang. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {
    //MARK: - Properties
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var instructionView: UIView!
    @IBOutlet weak var mainView: UIView!
    var indexOfPage = 0
    
    //MARK: - Lifecycles
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(AboutViewController.swipedLeft))
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(AboutViewController.swipedRight))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.left
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        view.addGestureRecognizer(swipeLeft)
        view.addGestureRecognizer(swipeRight)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.indexOfPage = 0
        self.instructionView.isHidden = true
        self.mainView.isHidden = false
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    //MARK: - Page Control functions
    
    func swipedLeft(){
        if indexOfPage == 0{
            //Change to second page(instruction)
            UIView.transition(with: self.view, duration: 0.5, options: .transitionFlipFromRight, animations: { _ in
                self.instructionView.isHidden = false
            }, completion: nil)
            indexOfPage = 1
            self.pageControl.currentPage = 1
        }
    }
    
    func swipedRight(){
        if indexOfPage == 1{
            //Change to first page(main)
            UIView.transition(with: self.view, duration: 0.5, options: .transitionFlipFromLeft, animations: { _ in
                self.mainView.isHidden = false
                self.instructionView.isHidden = true
            }, completion: nil)
            indexOfPage = 0
            self.pageControl.currentPage = 0
        }
    }
    
    
    
    //MARK: - Functions
    
    @IBAction func backButtonTapped(_ sender: Any) {
        UIView.transition(with: self.view.superview!, duration: 0.25, options: .transitionCrossDissolve, animations: { _ in
            if self.parent is MainViewController{
                let parent = self.parent as! MainViewController
                parent.backgroundView.isHidden = true
            } else {
                let parent = self.parent as! ContactListController
                parent.backgroundView.isHidden = true
            }
        self.view.removeFromSuperview()
    }, completion: nil)
    }

}
