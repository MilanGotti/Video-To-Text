//
//  TextViewController.swift
//  Video-To-Text
//
//  Created by Milan Goti on 12/01/22.
//

import UIKit
import Speech
import AVFoundation

class TextViewController: UIViewController {
    
    //MARK: Outlets
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var textViewDetail: UITextView!
    
    //MARK: Declarations
    var audioURL: URL?
    
    //MARK: View Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        let recogniser = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        let request = SFSpeechURLRecognitionRequest(url: audioURL!)
        request.shouldReportPartialResults = true

        if (recogniser?.isAvailable)! {
            recogniser?.recognitionTask(with: request) { result, error in
                guard error == nil else { print("Error: \(error!)"); return }
                guard let result = result else { print("No result!"); return }
                self.textViewDetail.text = result.bestTranscription.formattedString
            }
        } else {
            print("Device doesn't support speech recognition")
        }
        
        self.backButton.addTarget(self, action: #selector(backButtonClick), for: .touchUpInside)
    }
    
    //MARK: Button Action
    @objc func backButtonClick(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
   
}
