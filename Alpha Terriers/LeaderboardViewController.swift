//
//  LeaderboardViewController.swift
//  Alpha Terriers
//
//  Created by Christopher Liao on 4/26/16.
//  Copyright © 2016 Christopher Liao. All rights reserved.
//

import Foundation
//
//  LoationChallengeViewController.swift
//  MySampleApp
//
//  Created by Christopher Liao on 4/21/16.
//  Copyright © 2016 Amazon. All rights reserved.
//

import Foundation
import UIKit
import AWSMobileHubHelper

class LeaderboardViewController: UIViewController{
    var returnText : String!
    var locationID : NSInteger!
    var jsonDict : AnyObject! // dict representation of output of cloud function
    var doneInvokingCloudLogic : Bool = false
    var leaderboardTimer: NSTimer!
    
    @IBOutlet weak var thirdLabel: UILabel! //displays how long was king for in seconds
    @IBOutlet weak var secondLabel: UILabel! //displays name
    @IBOutlet weak var firstLabel: UILabel! //displays rank
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.leaderboardTimer = NSTimer(timeInterval: 1.0, target: self, selector: #selector(LeaderboardViewController.displayLeaderboard), userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(leaderboardTimer, forMode: NSRunLoopCommonModes)
        leaderboard()
    }
    
    func leaderboard(){
        let inputString = "{\"loc\":\(self.locationID)}"
        print(inputString)
        let functionName = "Leaderboard"
        let jsonInput = inputString.makeJsonable()
        let jsonData = jsonInput.dataUsingEncoding(NSUTF8StringEncoding)!
        var parameters: [String: AnyObject]
        do {
            let anyObj = try NSJSONSerialization.JSONObjectWithData(jsonData, options: []) as! [String: AnyObject]
            parameters = anyObj
        } catch let error as NSError {
            print("json error: \(error.localizedDescription)")
            return
        }
        AWSCloudLogic.defaultCloudLogic().invokeFunction(functionName,
                                                         withParameters: parameters, completionBlock: {(result: AnyObject?, error: NSError?) -> Void in
                                                            if let result = result{
                                                                dispatch_async(dispatch_get_main_queue(), {
                                                                    self.jsonDict = result as! NSMutableDictionary
                                                                    self.returnText = prettyPrintJson(result)
                                                                    self.doneInvokingCloudLogic = true
                                                                })
                                                            }
                                                            
                                                            var errorMessage: String
                                                            if let error = error {
                                                                if let cloudUserInfo = error.userInfo as? [String: AnyObject],
                                                                    cloudMessage = cloudUserInfo["errorMessage"] as? String {
                                                                    errorMessage = "Error: \(cloudMessage)"
                                                                } else {
                                                                    errorMessage = "Error occurred in invoking the Lambda Function. No error message found."
                                                                }
                                                                dispatch_async(dispatch_get_main_queue(), {
                                                                    print("Error occurred in invoking Lambda Function: \(error)")
                                                                    //self.activityIndicator.stopAnimating()
                                                                    self.returnText = errorMessage
                                                                    let alertView = UIAlertController(title: NSLocalizedString("Error", comment: "Title bar for error alert."), message: error.localizedDescription, preferredStyle: .Alert)
                                                                    alertView.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment: "Button on alert dialog."), style: .Default, handler: nil))
                                                                    self.presentViewController(alertView, animated: true, completion: nil)
                                                                })
                                                            }
        })
        // end of AWSCloudLogic.defaultCloudLogic().invokeFunction
    }
    
    func displayLeaderboard(){
        if self.doneInvokingCloudLogic{
            
            var leaderboardArray = Array(jsonDict.allKeys)
            print(leaderboardArray)
            
            leaderboardArray.sortInPlace({ (v1:AnyObject!, v2:AnyObject!) -> Bool in
                let x = Int32(self.jsonDict.objectForKey(v1).stringValue)
                let y = Int32(self.jsonDict.objectForKey(v2).stringValue)
                print(x,y)
                return x > y
            })
            
            print(leaderboardArray)
            var firstString = ""
            var secondString = ""
            var thirdString = ""
            var rank:Int32 = 1
            
            for name in leaderboardArray {
                firstString += String(rank)
                secondString += name as! String
                
                thirdString += (self.jsonDict.objectForKey(name)?.stringValue)!
                firstString += "\n"
                secondString += "\n"
                thirdString += "\n"
                rank += 1
            }
            firstLabel.text = firstString
            secondLabel.text = secondString
            thirdLabel.text = thirdString
            leaderboardTimer.invalidate()
        }
    }
}


//extension for AWS JSON encoding purposes
extension String {
    private func makeJsonable() -> String {
        let resultComponents: NSArray = self.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
        return resultComponents.componentsJoinedByString("")
    }
}
