//
//  ViewController.swift
//  twitter-hashtag-analytics
//
//  Created by Ted on 2021/02/11.
//

import UIKit
import Swifter
import CoreML
import SwiftyJSON

class ViewController: UIViewController {
    
    //MARK: - Properties
    
    @IBOutlet weak var sentimentLabel: UILabel!
    
    private let sentimentClassifier = TweetClassifier()
    private let tweetCount = 100

    let swifter = Swifter(consumerKey: "enter consumerKey", consumerSecret: "enter consumerSecret")
    
    //MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    //MARK: - IBAction
    
    @IBAction func buttonPressed(_ sender: Any) {
        self.presentAlertController()
    }
    
    //MARK: - Helpers
    
    func presentAlertController() {
        let alertController = UIAlertController(title: "Type whatever you want",
                                                message: nil,
                                                preferredStyle: .alert)
        
        self.present(alertController, animated: true)
        
        alertController.addTextField { (textField) in
            textField.placeholder = "#Apple"
        }
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak alertController] _ in
            guard let textFields = alertController?.textFields else { return }
            
            if let searchText = textFields[0].text {
                self.fetchTweets(with: searchText)
            }
        }
        
        alertController.addAction(submitAction)
    }
    
    func fetchTweets(with searchText: String) {
        swifter.searchTweet(using: searchText, lang: "en", count: tweetCount, tweetMode: .extended) { (results, metadata) in
            
            var tweets = [TweetClassifierInput]()
            
            for i in 0..<self.tweetCount {
                guard let tweet = results[i]["full_text"].string else { return }
                let tweetForClassification = TweetClassifierInput(text: tweet)
                tweets.append(tweetForClassification)
            }
            
            self.makePrediction(with: tweets)
            self.updateNavigationTitle(with: searchText)
            
        } failure: { (error) in
            print(error.localizedDescription)
        }
    }
    
    
    func makePrediction(with tweets: [TweetClassifierInput]) {
        do {
            let predictions = try self.sentimentClassifier.predictions(inputs: tweets)
            
            var sentimentScore = 0
            
            for prediction in predictions {
                let sentiment = prediction.label
                
                switch sentiment {
                case "Pos":
                    sentimentScore += 1
                case "Neg":
                    sentimentScore -= 1
                default:
                    continue
                }
            }
            
            updateUI(with: sentimentScore)
            
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    func configureUI() {
        self.navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    func updateNavigationTitle(with searchText: String) {
        DispatchQueue.main.async {
            self.navigationController?.navigationBar.topItem?.title = searchText
        }
    }
    
    func updateUI(with sentimentScore: Int) {
        DispatchQueue.main.async {
            switch sentimentScore {
            case _ where sentimentScore >= 20:
                self.sentimentLabel.text = "😍"
            case 10..<20:
                self.sentimentLabel.text = "😀"
            case 0..<10:
                self.sentimentLabel.text = "🙂"
            case -10..<0:
                self.sentimentLabel.text = "😕"
            case -20 ..< -10:
                self.sentimentLabel.text = "🤨"
            case _ where sentimentScore <= -20:
                self.sentimentLabel.text = "🤬"
            default:
                self.sentimentLabel.text = "💁‍♀️"
            }
        }
    }
}

