
import UIKit
import AVFoundation

var recordingsDictionary: [String: [String]] = [:]

class ViewController: UIViewController {
    
    var originalColor: UIColor!
    
    var player: AVAudioPlayer?
    
    var isRecording: Bool = false
    
    var recordingArray: [String] = []
    
    var melodyNames: [String] = []

    private let picker = UIPickerView()
    private let dummyTextField = UITextField(frame: .zero)

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
        
        picker.dataSource = self
        picker.delegate = self
        
        view.addSubview(dummyTextField)
        dummyTextField.inputView = picker
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap(_:)))
        tap.cancelsTouchesInView = false   // чтобы кнопки продолжали работать
        view.addGestureRecognizer(tap)
    }
    
    @objc private func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        
        if picker.frame.contains(location) { return }

        if dummyTextField.isFirstResponder {
            dummyTextField.resignFirstResponder()
        }
    }
    
    
    @IBAction func playTapped(_ sender: UIButton) {
        melodyNames = Array(recordingsDictionary.keys)
        picker.reloadAllComponents()
        
        guard !melodyNames.isEmpty else { return }
        
        if dummyTextField.isFirstResponder {
            dummyTextField.resignFirstResponder()
        } else {
            dummyTextField.becomeFirstResponder()
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
            
            // Alert

            let alertController = UIAlertController(title: "Title", message: "", preferredStyle: .alert)

            let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
                let textField = alertController.textFields![0]
                let name = textField.text ?? ""
                if !name.isEmpty && !self.recordingArray.isEmpty {
                    recordingsDictionary[name] = self.recordingArray
                }
                print(recordingsDictionary)
            }

            saveAction.isEnabled = false   // стартуем с выключенной

            alertController.addTextField { textField in
                textField.placeholder = "Enter the name"
                textField.addTarget(self,
                                    action: #selector(self.alertTextFieldDidChange(_:)),
                                    for: .editingChanged)
            }

            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alertController.addAction(saveAction)
            present(alertController, animated: true)

        }
    }
    
    @objc private func alertTextFieldDidChange(_ textField: UITextField) {
        if let alert = presentedViewController as? UIAlertController,
           let saveAction = alert.actions.last {
            let text = textField.text ?? ""
            saveAction.isEnabled = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
    
    func playSequence(notes: [String]) {
        var index = 0

        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if index >= notes.count {
                timer.invalidate()
                return
            }

            let noteName = notes[index]
            self.play(fileName: noteName)
            index += 1
        }
    }
}

extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return melodyNames.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return melodyNames[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let name = melodyNames[row]
        guard let notes = recordingsDictionary[name] else { return }
        
        dummyTextField.text = name
        playSequence(notes: notes)
    }
}
