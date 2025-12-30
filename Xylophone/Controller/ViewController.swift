
import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    var originalColor: UIColor!
    
    var player: AVAudioPlayer?
    
    var isRecording: Bool = false
    
    var recordingArray: [String] = []
    
    @IBOutlet weak var recButton: UIButton!
    @IBOutlet weak var timeDisplay: UILabel!
    
    private var countNum = 0
    private var timerRunning = false
    private var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        originalColor = self.view.backgroundColor
        timeDisplay.text = "00:00.00"
    }
    
    
    @IBAction func playTapped(_ sender: UIButton) {
        for (index, fileName) in recordingArray.enumerated() {
            let delay = 0.5 * Double(index)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.play(fileName: fileName)
            }
        }
    }
    
    @objc private func updateDisplay() {
        countNum += 1
        let ms = countNum % 100
        let s = (countNum / 100) % 60
        let m = (countNum / 6000) % 60   // minutes (00–59)

        timeDisplay.text = String(format: "%02d:%02d.%02d", m, s, ms)
    }
    
    @IBAction func recTapped(_ sender: UIButton) {
        if !timerRunning {
            recordingArray = []
            countNum = 0
            timeDisplay.text = "00:00.00"
            timer = Timer.scheduledTimer(timeInterval: 0.01,
                                         target: self,
                                         selector: #selector(updateDisplay),
                                         userInfo: nil,
                                         repeats: true)
            RunLoop.current.add(timer!, forMode: .common)
            timerRunning = true
            sender.setTitle("Stop", for: .normal)
        } else {
            timer?.invalidate()
            timer = nil
            timerRunning = false
            sender.setTitle("REC", for: .normal)
            print(recordingArray)
        }
    }

    @IBAction func buttonPressed(_ sender: UIButton) {
        print("\(sender.title(for: .normal)!) button was pressed")
        play(fileName: sender.title(for: .normal)!)
        
        //Reduces the sender's (the button that got pressed) opacity to half.
        sender.alpha = 0.5
        
        //Code should execute after 0.2 second delay.
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
              //Bring's sender's opacity back up to fully opaque.
              sender.alpha = 1.0
          }
        
        // Function to change the color of the background
        changeColorForThePeriodOfTime(bgColor: sender.backgroundColor)
        
        if timerRunning {
            recordingArray.append(sender.titleLabel?.text ?? "")
        }
    }
    
    func changeColorForThePeriodOfTime(bgColor: UIColor? = nil) {
            self.view.backgroundColor = bgColor // Change to new color
            
            // Wait for 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
                // Change it back to the original color
            UIView.animate(withDuration: 0.5, delay: 0.0, options: [.allowUserInteraction]) { // Optional: Animate the color change back
                    self.view.backgroundColor = self.originalColor
                }
            }
        }
    
    func play(fileName: String){
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "wav") else {
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.wav.rawValue)
            
            /* iOS 10 and earlier require the following line:
             player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
            
            guard let player = player else { return }
            
            player.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
}

