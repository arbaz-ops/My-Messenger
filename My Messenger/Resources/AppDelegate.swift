
// Swift
//
// AppDelegate.swift
import UIKit
import FBSDKCoreKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
          
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
         let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String
        if let userEmail = currentUserEmail {
            print(userEmail)
        } else {
            fatalError("Something went wrong..")
            
        }
        
            FirebaseApp.configure()
            
                
                UINavigationBar.appearance().setBackgroundImage(UIImage(), for: UIBarMetrics.default)
                UINavigationBar.appearance().shadowImage = UIImage()
                
                UINavigationBar.appearance().isTranslucent = true
        
        UITabBar.appearance().backgroundImage = UIImage()
        
        
        UITabBar.appearance().isTranslucent = true

        return true
    }
          
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {

        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )

    }

}
    
