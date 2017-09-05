//
//  ViewController.swift
//  VideoCapture
//
//  Created by MrHuang on 17/8/13.
//  Copyright © 2017年 Mrhuang. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    fileprivate lazy var session : AVCaptureSession = AVCaptureSession()
    fileprivate var VideoOutput : AVCaptureVideoDataOutput!
    fileprivate var previewLayer : AVCaptureVideoPreviewLayer?
    fileprivate var VideoInput : AVCaptureDeviceInput?
    fileprivate var MovieOutput : AVCaptureMovieFileOutput?
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
       

        // 1.初始化视频的输入&输出
        setupVideoInputOutput()
        
        
        // 2.初始化音频的输入&输出
        setupAudioInputOutput()
        
       
        
    }
    
    // 切换摄像头
    @IBAction func rotateCamera() {
       
        // 1. 取出之前的镜头方向
        guard let videoinput = VideoInput else {
            return
        }
        // 判断是前置摄像头还是后置
        let position : AVCaptureDevicePosition = videoinput.device.position == .front ? .back : .front
        guard let devices = AVCaptureDevice.devices() as? [AVCaptureDevice] else { return
        }
        guard let device = devices.filter({$0.position == position}).first else {
            return
        }
        guard let newInput =  try? AVCaptureDeviceInput(device: device) else {
            return
        }
       
        // 2. 移除之前的input,添加新的input
        session.beginConfiguration()
        session.removeInput(videoinput)
        if session.canAddInput(newInput) {
            session.addInput(newInput)
        }
        session.commitConfiguration()
        
        // 3. 保存新的input
        self.VideoInput = newInput
        
    }
   
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

extension ViewController {

    
    @IBAction func StartCapture() {
        
        // 1.初始化一个预览图层
        setupPreviewLayer()
        // 2.开始采集
        session.startRunning()
        // 3.写入文件
        MovieWriteToFile()
        
    }
    @IBAction func StopCapture() {
       
        MovieOutput?.stopRecording()
        
        session.stopRunning()
        
        previewLayer?.removeFromSuperlayer()
    }

    
}

extension ViewController {

    // 视频的输入&输出
    fileprivate func setupVideoInputOutput(){
        // 输入
        guard let devices = AVCaptureDevice.devices() as? [AVCaptureDevice] else {return}
        //拿到所有采集设备中的前置摄像头
        guard let device = devices.filter({$0.position == .front}).first else {return}
        guard let input = try? AVCaptureDeviceInput(device: device) else {return}
        self.VideoInput = input
        
        // 输出
            let output = AVCaptureVideoDataOutput()
            let queue = DispatchQueue.global()
            output.setSampleBufferDelegate(self, queue: queue)
        self.VideoOutput = output
        
        // 添加到输入输出
        addInputOutputTosession(input, output)
    }
    
    // 音频的输入&输出
    fileprivate func setupAudioInputOutput(){
       
        // 输入
        guard let devices = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio) else { return }
        guard let input = try? AVCaptureDeviceInput(device:devices) else {
            
            return
        }
        
        // 输出
        
        let output = AVCaptureVideoDataOutput()
        let queue = DispatchQueue.global()
        output.setSampleBufferDelegate(self, queue: queue)
        
        addInputOutputTosession(input, output)
        
    }
    
    //设置预览图层
    fileprivate func setupPreviewLayer(){
        
        guard let previewLayer = AVCaptureVideoPreviewLayer(session: session) else {return}
        
        previewLayer.frame = view.bounds
        self.previewLayer = previewLayer
        
//        view.layer.addSublayer(previewLayer)
        view.layer.insertSublayer(previewLayer, at: 0)
    }
    
    private func addInputOutputTosession (_ input : AVCaptureInput, _ output : AVCaptureOutput){
        
        session.beginConfiguration()
        
        if session.canAddInput(input) {
        
            session.addInput(input)
        }
        
        if session.canAddOutput(output) {
        
            session.addOutput(output)
        }
        
        session.commitConfiguration()
    
    }

    // 写入文件
    fileprivate func MovieWriteToFile(){
    
        session.removeOutput(self.MovieOutput)
        
        let fileOutput = AVCaptureMovieFileOutput()
        self.MovieOutput = fileOutput
        
        let connection = fileOutput.connection(withMediaType: AVMediaTypeVideo)
        connection?.automaticallyAdjustsVideoMirroring = true
        
        if session.canAddOutput(fileOutput) {
            session.addOutput(fileOutput)
        }
        // 写入文件路径
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/text.mp4"
        let URLPath = URL(fileURLWithPath: path)
            fileOutput.startRecording(toOutputFileURL: URLPath, recordingDelegate: self)
        
        
    }
    
}


//MARK: -Delegate
extension ViewController : AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        if VideoOutput?.connection(withMediaType: AVMediaTypeVideo) == connection {
        
            print("采集的视频数据")
        
        }else {
            print("采集的音频数据")
        }
    }

    
}

//MARK: -通过代理监听开始写入文件, 以及结束写入文件
extension ViewController : AVCaptureFileOutputRecordingDelegate {
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        
        print("开始写入文件！！！")
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        print("结束写入文件！！！")
    }

}
