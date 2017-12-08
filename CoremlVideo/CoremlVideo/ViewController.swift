//
//  ViewController.swift
//  CoremlVideo
//
//  Created by 刘李斌 on 2017/12/4.
//  Copyright © 2017年 Brilliance. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    @IBOutlet weak var preview: UIView!
    
    @IBOutlet weak var predictionTextView: UITextView!
    
    var captureSession: AVCaptureSession!
    var cameraOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var imageToAmalyze: UIImage!
    
    let synth = AVSpeechSynthesizer()
    var muUtterance = AVSpeechUtterance(string: "")
    var previousprediction = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCamera()
        
    }

    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        cameraOutput = AVCapturePhotoOutput()
        
        let device = AVCaptureDevice.default(for: AVMediaType.video)
        
        if let input = try? AVCaptureDeviceInput(device: device!) {
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                
                if captureSession.canAddOutput(cameraOutput) {
                    captureSession.addOutput(cameraOutput)
                }
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
//                previewLayer.frame = preview.bounds
                previewLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height - predictionTextView.bounds.size.height)
                preview.layer.addSublayer(previewLayer)
                captureSession.startRunning()
                
                print("preview bounds = \(self.preview.frame), main bounds = \(self.view.frame), layer frame = \(previewLayer.frame)")
            } else {
                print("could not add the input !")
            }
        } else {
            print("could not find the input !")
        }
        launchAI()
    }
    
    @objc func launchAI() {
        let settings = AVCapturePhotoSettings()
        //要处理的数据 - 像素
        let previewPiexType = settings.availablePreviewPhotoPixelFormatTypes.first
        /** 传入数据格式
         字典元素1: 告诉系统从哪个对象中拿图像数据
         字典元素2: 要处理的图像数据的大小的宽度  160像素
         字典元素3: 要处理的图像数据的大小的高度  160像素
        */
        let previewFormat = [
            kCVPixelBufferPixelFormatTypeKey as String: previewPiexType,
            kCVPixelBufferWidthKey as String: 160,
            kCVPixelBufferHeightKey as String: 160
            ]
        
        settings.previewPhotoFormat = previewFormat
        
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }
    
    //选择相片之后进行的处理
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("error code \(error.localizedDescription)")
        }
        
        if let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) {
            //运行模型
            predict(image: image)
        }
        
    }
    
    func predict(image: UIImage) {
        //把相片给模型
        if let data = UIImagePNGRepresentation(image) {
            //拿到图片路径并给图片命名
            let fileName = getDocumentDirectory().appendingPathComponent("image.png")
            //写入模型
            try? data.write(to: fileName)
            
            let model = try! VNCoreMLModel(for: VGG16().model)
            
            //异步处理结果
            let request = VNCoreMLRequest(model: model, completionHandler: preditionCompleted)
            let handler = VNImageRequestHandler(url: fileName)
            try! handler.perform([request])
        }
        
        //运行模型
        
        //拿到所有结果
        
    }
    
    //预测模型
    func preditionCompleted(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNClassificationObservation] else { fatalError("无法预测这个结果")}
        
        var bestPrediction = ""
        var confidence: VNConfidence = 0
        
        for classification in results {
            if classification.confidence > confidence {
                confidence = classification.confidence
                bestPrediction = classification.identifier
            }
        }
        
        self.predictionTextView.text = self.predictionTextView.text + bestPrediction + "\n"
        
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(launchAI), userInfo: nil, repeats: false)
    }
    
    func getDocumentDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    

}


























