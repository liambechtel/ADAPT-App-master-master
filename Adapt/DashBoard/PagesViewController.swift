//
//  PageViewController.swift
//  Adapt
//
//  Created by Josh Altabet on 2/1/18.
//  Copyright © 2018 Timmy Gouin. All rights reserved.
//

import Foundation
import UIKit

class PagesViewController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    var playerId: Int32 = -1
    private(set) lazy var orderedViewControllers: [UIViewController] = {
        return [self.newViewController(trainingType: nil),
                self.newViewController(trainingType: TrainingType.Target),
                self.newViewController(trainingType: TrainingType.BarFlexion),
                self.newViewController(trainingType: TrainingType.BarVersion),
                ]
        }() as! [TrainingHistoryViewController]                               //
    var first: Bool = true
    private func newViewController(trainingType: TrainingType?) -> UIViewController {
        let newVC = UIStoryboard(name: "Dashboard", bundle: nil).instantiateViewController(withIdentifier: "trainingViewController")
        if let trainingVC = newVC as? TrainingHistoryViewController {
            trainingVC.titleText = trainingType != nil ? TrainingType.toString(trainingType: trainingType!) : "Overall"
            trainingVC.trainingType = trainingType
            trainingVC.playerId = playerId
        }
        return newVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        dataSource = self
                
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController],
                               direction: .forward,
                               animated: true,
                               completion: nil)
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController as! TrainingHistoryViewController) else {  //
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        
        return orderedViewControllers[previousIndex]
    }
        
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController as! TrainingHistoryViewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count
        
        guard orderedViewControllersCount != nextIndex else {
            return nil
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        return orderedViewControllers[nextIndex]
    }
    
    
    //func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController])
    //{
        //if let nextViewController = pendingViewControllers[0] as? trainingPagedViewController {
            //MainViewController.drawCircle(imageView: (self.view.viewWithTag(1) as! UIImageView)?)
        //}
    //}
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return orderedViewControllers.count
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        guard let firstViewController = viewControllers?.first as? TrainingHistoryViewController,
            let firstViewControllerIndex = orderedViewControllers.index(of: firstViewController ) else {
                return 0
            }
        
        return firstViewControllerIndex
    }
    
}



