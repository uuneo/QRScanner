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
    
    private var lastFailCallTime: Date?
    
	public override func viewDidLoad() {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch  authStatus {
        case .authorized:
            QRView.startRunning()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.QRView.startRunning()
                }else{
                    self.triggerFailIfNeeded(QRScannerError.unauthorized(.denied))
                }
            }
        default:
            self.triggerFailIfNeeded(.unauthorized(authStatus))
            
        }
		super.viewDidLoad()
		QRView.frame = view.bounds
		view.addSubview(QRView)
		QRView.configure(delegate: self, input: .init( isBlurEffectEnabled: true))
		

	}

	public func qrScannerView(_ qrScannerView: QRScannerView, didFailure error: QRScannerError) {
        self.triggerFailIfNeeded(error)
	}

	public func qrScannerView(_ qrScannerView: QRScannerView, didSuccess code: String) {
		DispatchQueue.main.async {
			self.success?(code)
		}
	}

	public func qrScannerView(_ qrScannerView: QRScannerView, didChangeTorchActive isOn: Bool) { }

    
    private func triggerFailIfNeeded(_ error: QRScannerError) {
        let now = Date()
        if let lastTime = lastFailCallTime, now.timeIntervalSince(lastTime) < 1.0 {
            // 距离上次调用不到1秒，忽略
            return
        }
        lastFailCallTime = now
        DispatchQueue.main.async{
            self.fail?(error)
        }
    }

}
