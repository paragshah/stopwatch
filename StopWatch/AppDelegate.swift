//
//  AppDelegate.swift
//  StopWatch
//
//  Created by Parag Shah on 2/25/16.
//  Copyright © 2016 Parag Shah. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = StopWatchViewController()
        window?.makeKeyAndVisible()

        return true
    }
}
