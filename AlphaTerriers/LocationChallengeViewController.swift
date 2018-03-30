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

class LocationChallengeViewController: UIViewController{
    
    @IBOutlet weak var frozenTimerLabel: UILabel!
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var CurrentKingNameLabel: UILabel!
    @IBOutlet weak var CurrentKingBeginTimeLabel: UILabel!
    @IBOutlet weak var CurrentKingAnswerTimeLabel: UILabel!
    var returnText = "" // output of cloud function //REMOVE?
    var canChallenge: Bool=true // set to false to disable Challenge button
    var doneInvokingCloudLogic: Bool = false
    var jsonDict : AnyObject! // dict representation of output of cloud function
    var locationID : NSInteger! // location ID passed from previous screen
    var returnMessage : String = " "
    var currentKingBeginTimeToBeDisplayed : String = " "
    var updateInfoTimer : NSTimer!
    var checkFreezeTimer: NSTimer!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        message.text = self.returnMessage
    }
    
    override func viewDidAppear(animated: Bool) {
        print("get freeze: ", (get_frz((Int32)(self.locationID))))
        if get_frz((Int32)(self.locationID)) == -1 {
            canChallenge = true
        } else {
            canChallenge = false
        }

        //timer functions config
        self.updateInfoTimer = NSTimer(timeInterval: 1.0, target: self, selector: #selector(LocationChallengeViewController.updateInfo), userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(updateInfoTimer, forMode: NSRunLoopCommonModes)
        self.checkFreezeTimer = NSTimer(timeInterval: 1.0, target: self, selector: #selector(LocationChallengeViewController.checkFreeze), userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(checkFreezeTimer, forMode: NSRunLoopCommonModes)
    }
    
    func updateInfo(){
        let inputString = "{\"loc\":\(self.locationID)}"
        print(inputString)
        let functionName = "CurrentKingInfo"
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
                                                                    print(self.jsonDict.objectForKey("current_king"))
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
        if doneInvokingCloudLogic{
            secsSinceMidnightToTime(jsonDict.objectForKey("current_king_begin_time").stringValue)
            CurrentKingNameLabel.text = String(jsonDict.objectForKey("current_king")!)
            CurrentKingBeginTimeLabel.text = self.currentKingBeginTimeToBeDisplayed
            CurrentKingAnswerTimeLabel.text = jsonDict.objectForKey("current_king_answer_time").stringValue + " millisecs"
        }
    }
    
    @IBAction func LeaderboardAction(sender: UIButton) {
        performSegueWithIdentifier("LeaderboardSegue", sender: self)
    }
    
    @IBAction func CallengeAction(sender: UIButton) {
        if (self.canChallenge){
            performSegueWithIdentifier("ChallengeSegue", sender: self)
        }
    }
    
    func checkFreeze(){
        //ask if is still frozen, if not, unfreeze
        if (!still_frozen_loc((Int32)(locationID))){
            unfreeze_loc((Int32)(locationID))
            frozenTimerLabel.text = " "
            canChallenge = true
        } else {
            frozenTimerLabel.text = "You are Frozen. Try again in \(120-(get_current_time() - get_frz((Int32)(self.locationID)))) seconds"
            canChallenge = false
        }
    }
    
    func secsSinceMidnightToTime( secsSinceMidnight : String ){
        //convert string of seconds since midnight to clock time
        let hours : Int = Int(secsSinceMidnight)!/3600
        let minutes : Int = (Int(secsSinceMidnight)!%3600)/60
        let seconds : Int = (Int(secsSinceMidnight)!%3600)%60
        let hours_string = String(hours-4) // subtract four to convert from GMT to EST
        let seconds_string = String(seconds)
        let minutes_string = String(minutes)
        let return_string = hours_string + " : " + minutes_string + " : " + seconds_string
        
        self.currentKingBeginTimeToBeDisplayed = return_string
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "ChallengeSegue") {
            let nextViewController = segue.destinationViewController as! LocationQuestionViewController
            nextViewController.locationID = self.locationID
        }
        
        else if (segue.identifier == "LeaderboardSegue") {
            let nextViewController = segue.destinationViewController as! LeaderboardViewController
            nextViewController.locationID = self.locationID
        }
    }

    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        updateInfoTimer.invalidate()
        checkFreezeTimer.invalidate()
    }
}

//extension for AWS JSON encoding purposes
extension String {
    private func makeJsonable() -> String {
        let resultComponents: NSArray = self.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
        return resultComponents.componentsJoinedByString("")
    }
}
