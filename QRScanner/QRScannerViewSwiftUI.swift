//
//  File name:     QRScannerViewSwiftUI.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/9.

import SwiftUI
import UIKit
import AVFoundation

public struct QRScanner: UIViewRepresentable {
    public typealias UIViewType = QRScannerView

    @Binding var rescan:Bool
    @Binding var flash:Bool
    var isRuning:Bool
    var input: QRScannerView.Input
    var onSuccess: (String) -> Void
    var onFailure: (QRScannerError) -> Void
    
    public init(rescan: Binding<Bool>,
                flash: Binding<Bool>,
                isRuning: Bool = true,
                input: QRScannerView.Input = .default,
                onSuccess: @escaping (String) -> Void,
                onFailure: @escaping (QRScannerError) -> Void) {
        self._rescan = rescan
        self._flash = flash
        self.isRuning = isRuning
        self.input = input
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }
    
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public func makeUIView(context: Context) -> QRScannerView {
        
        let scannerView = QRScannerView()
        
        scannerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scannerView.frame = UIScreen.main.bounds
        
        
        scannerView.configure(delegate: context.coordinator, input: input)
        
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch  authStatus {
        case .authorized:
            if isRuning{
                scannerView.startRunning()
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted && isRuning {
                    scannerView.startRunning()
                }else{
                    onFailure(QRScannerError.unauthorized(.denied))
                }
            }
        default:
            onFailure(.unauthorized(authStatus))
        }
        
        return scannerView
    }

    public func updateUIView(_ uiView: QRScannerView, context: Context) {
        
        if !isRuning {
            uiView.stopRunning()
            return
        }
        
        if rescan {
            uiView.rescan()
            DispatchQueue.main.async{
                self.rescan = false
            }
        }
        uiView.setTorchActive(isOn: flash)
    }

    public class Coordinator: NSObject, QRScannerViewDelegate {
        let parent: QRScanner

        init(parent: QRScanner) {
            self.parent = parent
        }

        public  func qrScannerView(_ qrScannerView: QRScannerView, didSuccess code: String) {
            DispatchQueue.main.async {
                self.parent.onSuccess(code)
            }
        }

        public func qrScannerView(_ qrScannerView: QRScannerView, didFailure error: QRScannerError) {
            DispatchQueue.main.async {
                self.parent.onFailure(error)
            }
        }

        public func qrScannerView(_ qrScannerView: QRScannerView, didChangeTorchActive isOn: Bool) {
            DispatchQueue.main.async {
                self.parent.flash = isOn
            }
        }
    }
}
