//
//  AppDelegate.swift
//  VEditorKit
//
//  Created by Geektree0101 on 01/02/19.
//  Copyright © 2019 Geektree0101. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds) // create UIwindow
        if let window = window {
            let navController = UINavigationController.init(rootViewController: EditorNodeController())
            window.rootViewController = navController
            window.makeKeyAndVisible()
        }
        
        return true
    }
    
}
