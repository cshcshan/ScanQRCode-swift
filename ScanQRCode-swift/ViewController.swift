//
//  ViewController.swift
//  ScanQRCode-swift
//
//  Created by Han Chen on 15/6/2016.
//  Copyright © 2016年 Han Chen. All rights reserved.
//

// http://www.appcoda.com.tw/qr-code-reader-swift/

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
  @IBOutlet weak var output_Label: UILabel!
  @IBOutlet var web_View: UIView!
  @IBOutlet weak var webView: UIWebView!
  
  var captureSession: AVCaptureSession? // 用來協調來自影像輸入裝置至輸出的資料流程
  var videoPreviewLayer: AVCaptureVideoPreviewLayer?
  var qrCodeFrameView: UIView?

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    self.setupCaptureSession()
    self.setupVideoPreviewLayer()
    self.setupQRCodeFrameView()
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    self.setupWeb_View()
    self.startCapture()
    self.setupOutput_Label()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func setupCaptureSession() {
    captureSession = AVCaptureSession()
    // input device settings
    do {
      // AVCaptureDevice 物件代表一個實體擷取裝置
      let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
      let captureDeviceInput: AnyObject! = try AVCaptureDeviceInput(device: captureDevice)
      captureSession?.addInput(captureDeviceInput as! AVCaptureInput)
    } catch let error as NSError {
      print("setupCaptureSession error: \(error)")
    }
    // output settings
    let captureMetadataOutput = AVCaptureMetadataOutput() // 輸出裝置
    captureSession?.addOutput(captureMetadataOutput) // must add output then set metadataObjectTypes, or it will crash
    captureMetadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
    captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
  }
  
  func setupVideoPreviewLayer() {
    videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
    videoPreviewLayer?.frame = self.view.layer.bounds
    self.view.layer.addSublayer(videoPreviewLayer!)
  }
  
  func setupQRCodeFrameView() {
    qrCodeFrameView = UIView()
    qrCodeFrameView?.layer.borderColor = UIColor.greenColor().CGColor
    qrCodeFrameView?.layer.borderWidth = 2
    self.view.addSubview(qrCodeFrameView!)
    self.view.bringSubviewToFront(qrCodeFrameView!)
  }
  
  func setupWeb_View() {
    self.web_View.hidden = true
    self.web_View.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - self.output_Label.frame.size.height)
    self.view.addSubview(self.web_View)
  }
  
  func startCapture() {
    captureSession?.startRunning()
    self.videoPreviewLayer?.hidden = false
    self.qrCodeFrameView?.frame = CGRectZero
    self.output_Label.text = ""
    self.web_View.hidden = true
    self.webView.stopLoading()
  }
  
  func stopCapture() {
    self.videoPreviewLayer?.hidden = true
    captureSession?.stopRunning()
  }
  
  func setupOutput_Label() {
    self.output_Label.text = ""
    self.view.bringSubviewToFront(self.output_Label)
  }
  
  // MARK: - Utilities
  func openWebView(urlString: String) {
    let url = NSURL(string: urlString)
    let request = NSURLRequest(URL: url!)
    self.webView.loadRequest(NSURLRequest(URL: NSURL(string: "")!))
    self.webView.loadRequest(request)
    
    let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC)))
    dispatch_after(dispatchTime, dispatch_get_main_queue()) {
      self.stopCapture()
      self.web_View.hidden = false
    }
  }
  
  // MARK: - AVCaptureMetadataOutputObjectsDelegate
  func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
    if metadataObjects == nil || metadataObjects.count == 0 {
      qrCodeFrameView?.frame = CGRectZero
      self.output_Label.text = "No QR code is detected."
      return
    }
    
    let metadataObject = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
    if metadataObject.type == AVMetadataObjectTypeQRCode {
      // 透過 transformedMetadataObjectForMetadataObject method 將 metadata 物件的視覺屬性轉換成 layer coordinates
      let barCodeObject = videoPreviewLayer?.transformedMetadataObjectForMetadataObject(metadataObject) as! AVMetadataMachineReadableCodeObject
      qrCodeFrameView?.frame = barCodeObject.bounds
      if let metadataString = metadataObject.stringValue {
        self.output_Label.text = metadataString
        if metadataString.containsString("http://") || metadataString.containsString("https://") {
          self.openWebView(metadataString)
        }
      }
    }
  }
  
  // MARK: - IBAction
  @IBAction func webViewCancelButtonPressed(sender: UIBarButtonItem) {
    self.startCapture()
  }
}

