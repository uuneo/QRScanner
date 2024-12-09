# QRScanner
A simple QR Code scanner framework for iOS. Provides a similar scan effect to ios13+. Written in Swift.


* [日本語のブログ](https://tech.mercari.com/entry/2019/12/12/094129)

|iOS 13.0+| Use QRScanner in iOS 10.0+|
|-|-|
|<img src="https://raw.githubusercontent.com/mercari/QRScanner/master/images/ios13qr.gif" width="350">|<img src="https://raw.githubusercontent.com/mercari/QRScanner/master/images/qr.gif" width="350">|

"QR Code" is a registered trademark of DENSO WAVE INCORPORATED

## Feature
- Similar to iOS 13.0+ design
- Simple usage  <a href="https://github.com/mercari/QRScanner/blob/master/QRScannerSample/QRScannerSample/ViewController.swift" target="_blank">Sample</a>
- Support from iOS 10.0+

## Development Requirements
- iOS 11.0+ / Swift: 5.7.1
- iOS 13.0+ / SwiftUI
- Xcode Version: 14.1

## Installation
QRScanner supports multiple methods for installing the library in a project.

### Installation with CocoaPods

- To integrate QRScanner into your Xcode project using CocoaPods, specify it in your <code>Podfile</code>
```ruby
  platform :ios, '11.0'
  pod 'MercariQRScanner'
```

- Run command
```
  pod install
```
- Write Import statement on your source file
```swift
  import MercariQRScanner
```

### Installation with Swift Package Manager

Once you have your Swift package set up, adding QRScanner as a dependency is as easy as adding it to the dependencies value of your <code>Package.swift</code>.
```
dependencies: [
    .package(url: "https://github.com/mercari/QRScanner.git", .upToNextMajor(from: "1.9.0"))
]
```

- Write Import statement on your source file
```swift
import QRScanner
```

### Installation with Carthage

- To integrate QRScanner, add the following to your <code>Cartfile</code>.
```
github "mercari/QRScanner"
```
- Write Import statement on your source file
```swift
import QRScanner
```

## Usage

See [QRScannerSample](https://github.com/mercari/QRScanner/tree/master/QRScannerSample)

### Add `Privacy - Camera Usage Description` to Info.plist file

<img src="https://raw.githubusercontent.com/mercari/QRScanner/master/images/privacy_camera.png" width="500">

### The Basis Of Usage

```swift
import QRScanner // If use the Pod way, please import MercariQRScanner
import AVFoundation

final class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupQRScanner()
    }

    private func setupQRScanner() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupQRScannerView()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async { [weak self] in
                        self?.setupQRScannerView()
                    }
                }
            }
        default:
            showAlert()
        }
    }

    private func setupQRScannerView() {
        let qrScannerView = QRScannerView(frame: view.bounds)
        view.addSubview(qrScannerView)
        qrScannerView.configure(delegate: self, input: .init(isBlurEffectEnabled: true))
        qrScannerView.startRunning()
    }

    private func showAlert() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            let alert = UIAlertController(title: "Error", message: "Camera is required to use in this application", preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }
}

extension ViewController: QRScannerViewDelegate {
    func qrScannerView(_ qrScannerView: QRScannerView, didFailure error: QRScannerError) {
        print(error)
    }

    func qrScannerView(_ qrScannerView: QRScannerView, didSuccess code: String) {
        print(code)
    }
}
```

### Customization

#### Source Code Way

```swift
override func viewDidLoad() {
        super.viewDidLoad()

        let qrScannerView = QRScannerView(frame: view.bounds)

        // Customize focusImage, focusImagePadding, animationDuration
        qrScannerView.focusImage = UIImage(named: "scan_qr_focus")
        qrScannerView.focusImagePadding = 8.0
        qrScannerView.animationDuration = 0.5

        qrScannerView.configure(delegate: self)
        view.addSubview(qrScannerView)
        qrScannerView.startRunning()
}
```

#### Interface Builder Way

|Setup Custom Class|Customize|
|-|-|
|<img src="https://raw.githubusercontent.com/mercari/QRScanner/master/images/ib2.png" width="350">|<img src="https://raw.githubusercontent.com/mercari/QRScanner/master/images/ib1.png" width="350">|


### SwiftUI

```swift
import QRScanner
import SwiftUI

struct ScanView1: View {

	@Environment(\.dismiss) var dismiss

	@State private var torchIsOn = false
	@State private var restart = false
	@State private var showActive = false
	@State private var code = ""
	@State private var status:AVAuthorizationStatus = .authorized
	var body: some View {
		ZStack{
			QRScanner(restart: $restart, flash: $torchIsOn) { code in
				debugPrint(code)
				self.code = code
				self.showActive = true
			} fail: { error in
				switch error{
					case .unauthorized(let status):
						self.status = status
					default:
						break
				}
			}.actionSheet(isPresented: $showActive) {


				ActionSheet(title: Text( "Result: \(code)" ),buttons: [

					.default(Text( "Restart"), action: {
						self.restart.toggle()
						self.showActive = false
					}),

						.cancel({
							self.dismiss()
						})
				])
			}

			VStack{
				Spacer()
				Button{
					self.torchIsOn.toggle()
				}label: {
					Image(systemName: "flashlight.\(torchIsOn ? "on" : "off").circle")
						.font(.system(size: 50))
						.padding(.bottom, 80)
				}

			}
		}
	}

}

```



### Add FlashButton

[FlashButtonSample](https://github.com/mercari/QRScanner/blob/master/QRScannerSample/QRScannerSample/FlashButton.swift)

```swift
final class ViewController: UIViewController {

    ...

    @IBOutlet var flashButton: FlashButton!

    @IBAction func tapFlashButton(_ sender: UIButton) {
        qrScannerView.setTorchActive(isOn: !sender.isSelected)
    }
}

extension ViewController: QRScannerViewDelegate {

    ...

    func qrScannerView(_ qrScannerView: QRScannerView, didChangeTorchActive isOn: Bool) {
        flashButton.isSelected = isOn
    }
}
```

### Add Blur Effect

#### Source Code Way

```swift
     qrScannerView.configure(delegate: self, input: .init(isBlurEffectEnabled: true))
```

#### Interface Builder Way

|Customize|
|-|
|<img src="https://raw.githubusercontent.com/mercari/QRScanner/master/images/ib1.png" width="350">|

## Committers

* Hitsu ([@hitsubunnu](https://github.com/hitsubunnu))
* Sonny ([@tedbrosby](https://github.com/tedbrosby))
* Daichiro ([@daichiro](https://github.com/daichiro))

## Contribution

Please read the CLA carefully before submitting your contribution to Mercari.
Under any circumstances, by submitting your contribution, you are deemed to accept and agree to be bound by the terms and conditions of the CLA.

https://www.mercari.com/cla/

## License

Copyright 2019 Mercari, Inc.

Licensed under the MIT License.
