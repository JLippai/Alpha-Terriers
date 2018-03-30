//
//  NewViewController.swift
//  MySampleApp
//
//  Created by Christopher Liao on 4/23/16.
//  Copyright © 2016 Amazon. All rights reserved.
//

import Foundation

import UIKit
import AWSMobileHubHelper

class LocationQuestionViewController: UIViewController{
    @IBOutlet weak var answerField: UITextField!
    @IBOutlet weak var invalidEntryLabel: UILabel!
    @IBOutlet weak var Q: UIImageView!
    var answer : NSInteger!
    var keyInt : NSInteger! //this is both the number of the question asked and the correct canswer to the question
    var dumbyPersistentInt1 : Int32 = 1 // for C++ source code
    var dumbyPersistentInt2 : Int32 = 2 // for C++ source code
    var locationID : NSInteger!
    var challengeSuccessful : Bool! // true if usurped previous king
    var timeTakenToRespond : Int32! // can be -1 if incorrect
    var returnMessage : String = " " // message to send back to Challenge View after submitting answer
    let regionDict : [Int:String] = [0 : "PHO", 1:"EPIC", 2:"GSU", 3:"CAS"] // UPDATE IF SCALING
    private var activityIndicator = UIActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()
        //Acitivity indicator config
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.frame = CGRectMake(0.0, 0.0, 40.0, 40.0)
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
        activityIndicator.bringSubviewToFront(view)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //executes before view appears
        self.keyInt = (NSInteger)(challenge(&dumbyPersistentInt1, &dumbyPersistentInt2))
        let questionString:String = "Question\((String)(self.keyInt))"
        Q.image = UIImage(named: questionString)
    }
    
    @IBAction func giveUpAction(sender: UIButton) {
        self.returnMessage = "Failure! You gave up."
        freeze_loc((Int32)(locationID))
        print("Give up.")
        performSegueWithIdentifier("BackSegue", sender: self)
    }
    
    @IBAction func submitAction(sender: AnyObject) {
        answer = Int(answerField.text!)
        if answer == nil || answer < 1 || answer > 12{
            print("answer is either not int or not between 1 and 12")
            self.invalidEntryLabel.text = "Invalid answer! Answers are integers between 1 and 12."
            return
        }
        
        self.timeTakenToRespond = (answer_fallout((Int32)(answer),(Int32)(keyInt),dumbyPersistentInt1,dumbyPersistentInt2,(Int32)(locationID)))
        print("time taken to respond", timeTakenToRespond)
        if (timeTakenToRespond != -1) {
            print("CORRECT")
            betterTime()
            
            //pause thread while aws thread executes
            self.activityIndicator.startAnimating()
            while self.challengeSuccessful == nil {
                sleep(1)
                print("waiting for aws")
            }
            self.activityIndicator.stopAnimating()
            
            if !self.challengeSuccessful{
                freeze_loc((Int32)(locationID))
                self.returnMessage = "Failure! Failed to beat current king's time."
                print("failed to usurp, freezing")
            } else {
                self.returnMessage = "Success! You are now the Alpha Terrier of \(self.regionDict[locationID]!)"
                print("Successful!")
            }
        } else {
            print("WRONG")
            self.returnMessage = "Failure! Your answer was wrong."
        }
        performSegueWithIdentifier("BackSegue", sender: self) //move back to Challenge view
    }
    
    func betterTime(){
        let identityManager = AWSIdentityManager.defaultIdentityManager()
        let myName = identityManager.userName! // must be signed in
        let inputString = "{\"loc\":\(self.locationID),\"time\":\(self.timeTakenToRespond),\"name\":\"\(myName)\"}"
        let functionName = "BetterTime"
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
                                                                    print("CloudLogicViewController: Result: \(result)")
                                                            
                                                                })
                                                                let result_int = Int(prettyPrintJson(result))
                                                                //print("result", self.test)
                                                                switch result_int! {
                                                                case 0:
                                                                    self.challengeSuccessful = false
                                                                case 1:
                                                                    self.challengeSuccessful = true
                                                                default: break
                                                                }
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
                                                                    //self.returnText = errorMessage
                                                                    let alertView = UIAlertController(title: NSLocalizedString("Error", comment: "Title bar for error alert."), message: error.localizedDescription, preferredStyle: .Alert)
                                                                    alertView.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment: "Button on alert dialog."), style: .Default, handler: nil))
                                                                    self.presentViewController(alertView, animated: true, completion: nil)
                                                                })
                                                            }
        })
        // end of AWSCloudLogic.defaultCloudLogic().invokeFunction
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "BackSegue") {
            let nextViewController = segue.destinationViewController as! LocationChallengeViewController;
            nextViewController.locationID = self.locationID
            nextViewController.returnMessage = self.returnMessage
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