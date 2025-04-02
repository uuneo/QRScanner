//
//  File name:     QRScannerViewSwiftUI.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/9.
import SwiftUI
import AVFoundation
import AudioToolbox

@available(iOS 13.0, *)
public struct QRScanner: UIViewControllerRepresentable {


	@Binding var restart:Bool
	@Binding var flash:Bool

	var success:((String)->Void)?
	var fail:((QRScannerError)->Void)?


	public init(restart: Binding<Bool>, flash: Binding<Bool>, success: ((String) -> Void)? = nil, fail: ((QRScannerError) -> Void)? = nil) {
		self._restart = restart
		self._flash = flash
		self.success = success
		self.fail = fail
	}


	public func makeUIViewController(context: Context) -> QRScannerViewController {
		let controller = QRScannerViewController()
		controller.success = success
		controller.fail = fail
		return controller
	}

	public func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {
		// Here you can update the controller if needed.
		if restart {
			uiViewController.QRView.rescan()
			DispatchQueue.main.async{
				self.restart = false
			}
		}
		uiViewController.QRView.setTorchActive(isOn: flash)
	}




}


public class QRScannerViewController: UIViewController , QRScannerViewDelegate{

	var success:((String)->Void)?
	var fail:((QRScannerError)->Void)?

	var QRView = QRScannerView()
    

	public override func viewDidLoad() {
		super.viewDidLoad()
        
        
		QRView.frame = view.bounds
		view.addSubview(QRView)
		QRView.configure(delegate: self, input: .init( isBlurEffectEnabled: true))
		let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
		switch  authStatus {
			case .authorized:
				QRView.startRunning()
			case .notDetermined:
				AVCaptureDevice.requestAccess(for: .video) { granted in
					if granted {
						DispatchQueue.main.async {
							self.QRView.startRunning()
						}
					}
				}
			default:
				DispatchQueue.main.async {
					self.fail?(.unauthorized(authStatus))
				}

		}

	}

	public func qrScannerView(_ qrScannerView: QRScannerView, didFailure error: QRScannerError) {
		DispatchQueue.main.async {
			self.fail?(error)
		}
	}

	public func qrScannerView(_ qrScannerView: QRScannerView, didSuccess code: String) {
		DispatchQueue.main.async {
            AudioServicesPlaySystemSound(1000)
			self.success?(code)
		}
	}

	public func qrScannerView(_ qrScannerView: QRScannerView, didChangeTorchActive isOn: Bool) { }


}
