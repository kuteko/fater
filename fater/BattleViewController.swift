//
//  BattleViewController.swift
//  fater
//
//  Created by 内山香 on 2016/06/11.
//  Copyright © 2016年 内山香. All rights reserved.
//

import UIKit
import AVFoundation

class BattleViewController: UIViewController, UIGestureRecognizerDelegate{

    let monsterArray:[String] = ["mob1","mob2","mob3","boss1"]
    let monsterHP:[Int] = [1000,2000,3000,5000]
    var monsternowHP:[Int] = [1000,2000,3000,5000]
    var monsterAP:[Int] = [300,400,500,600]
    let playerHP: Int = 2000
    var playernowHP: Int = 2000
    let playerMP: Int = 1000
    var playernowMP: Int = 0
    var playerAP:Float = 100
    
    
    
    @IBOutlet var monsterHP_bar:UIProgressView!
    @IBOutlet var playerHP_bar:UIProgressView!
    @IBOutlet var playerMP_bar:UIProgressView!
    @IBOutlet var monsterHP_label: UILabel!
    @IBOutlet var playerHP_label: UILabel!
    @IBOutlet var playerMP_label: UILabel!
    
    @IBOutlet var attackButton: UIButton!
    @IBOutlet var healButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var imgView: SpringImageView!
    
    var questcount: Int=0
    
    var input:AVCaptureDeviceInput!
    var output:AVCaptureStillImageOutput!
    var session:AVCaptureSession!
    var preView:UIView!
    var camera:AVCaptureDevice!
    
    let Damping: CGFloat = 0.7
    let Velocity: CGFloat = 0.7
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        monsterHP_bar.transform = CGAffineTransformMakeScale(1.0, 2.0)
        playerHP_bar.transform = CGAffineTransformMakeScale(1.0, 2.0)
        playerMP_bar.transform = CGAffineTransformMakeScale(1.0, 2.0)
        
        
        monsterHP_label.text = "\(monsternowHP[questcount])"
        playerHP_label.text = "\(playernowHP)"
        playerMP_label.text = "\(playernowMP)"
        
//        healButton.hidden = true
        
        initStatus()
        
        // 画面タップでシャッターを切るための設定
        let tapGesture:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(BattleViewController.tapped(_:)))
        // デリゲートをセット
        tapGesture.delegate = self;
        // Viewに追加.
        self.view.addGestureRecognizer(tapGesture)
        
        
    }
    
    // メモリ管理のため
    override func viewWillAppear(animated: Bool) {
        // スクリーン設定
        setupDisplay()
        // カメラの設定
        setupCamera()
    }
    
    override func viewDidDisappear(animated: Bool) {
        // camera stop メモリ解放
        session.stopRunning()
        
        for output in session.outputs {
            session.removeOutput(output as? AVCaptureOutput)
        }
        
        for input in session.inputs {
            session.removeInput(input as? AVCaptureInput)
        }
        session = nil
        camera = nil
    }
    
    func setupDisplay(){
        //スクリーンの幅
        let screenWidth = UIScreen.mainScreen().bounds.size.width;
        //スクリーンの高さ
        let screenHeight = UIScreen.mainScreen().bounds.size.height;
        
        // プレビュー用のビューを生成
        preView = UIView(frame: CGRectMake(screenWidth/12, screenHeight/2.2, screenWidth/1.2, screenHeight/2.4))
        
    }
    
    func setupCamera(){
        
        // セッション
        session = AVCaptureSession()
        
        for caputureDevice: AnyObject in AVCaptureDevice.devices() {
            
            // 前面カメラを取得
            if caputureDevice.position == AVCaptureDevicePosition.Front {
                camera = caputureDevice as? AVCaptureDevice
            }
        }
        
        // カメラからの入力データ
        do {
            input = try AVCaptureDeviceInput(device: camera) as AVCaptureDeviceInput
        } catch let error as NSError {
            print(error)
        }
        
        // 入力をセッションに追加
        if(session.canAddInput(input)) {
            session.addInput(input)
        }
        
        // 静止画出力のインスタンス生成
        output = AVCaptureStillImageOutput()
        // 出力をセッションに追加
        if(session.canAddOutput(output)) {
            session.addOutput(output)
        }
        
        // セッションからプレビューを表示を
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        previewLayer.frame = preView.frame
        
        //        previewLayer.videoGravity = AVLayerVideoGravityResize
        //        previewLayer.videoGravity = AVLayerVideoGravityResizeAspect
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        // レイヤーをViewに設定
        // これを外すとプレビューが無くなる、けれど撮影はできる
        self.view.layer.addSublayer(previewLayer)
        
        session.startRunning()
    }
    
    
    // タップイベント.
    func tapped(sender: UITapGestureRecognizer){
        print("タップ")
        takeStillPicture()
    }
    
    func takeStillPicture(){
        
        // ビデオ出力に接続.
        if let connection:AVCaptureConnection? = output.connectionWithMediaType(AVMediaTypeVideo){
            // ビデオ出力から画像を非同期で取得
            output.captureStillImageAsynchronouslyFromConnection(connection, completionHandler: { (imageDataBuffer, error) -> Void in
                
                // 取得画像のDataBufferをJpegに変換
                let imageData:NSData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataBuffer)
                
                // JpegからUIImageを作成.
                guard let image = UIImage(data: imageData) else {
                    return
                }
                
                
                
                //UIImageからCGImageを作る際なぜか90度回転するそして193行目......
                guard let cgImage = image.CGImage else {
                    return
                }
                

                // storyboardに置いたimageViewからCIImageを生成する
                let ciImage = CIImage(CGImage: cgImage)
                
                
                // 顔認識なのでTypeをCIDetectorTypeFaceに指定する
                let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
                
                // 取得するパラメーターを指定する
                let options: [String: AnyObject] = [CIDetectorSmile : true, CIDetectorEyeBlink : true, CIDetectorImageOrientation: UIImageOrientation.DownMirrored.rawValue] //謎のDownMirroredである
                
                // 画像から特徴を抽出する
                let features = detector.featuresInImage(ciImage, options: options)
                
                var result: [(hasSmile: Bool, leftEyeClosed: Bool, rightEyeClosed: Bool)] = []
                
                for feature in features as! [CIFaceFeature] {
                    
                    result.append((feature.hasSmile, feature.leftEyeClosed, feature.rightEyeClosed))
                }
                
                if result.count >= 1 {
                    if result[0].hasSmile == true{
                        
                        if self.playernowMP == self.playerMP && result[0].leftEyeClosed && result[0].rightEyeClosed {
                            
                            self.specialAttack()
                            
                        }
                        else {
                           
                            self.playerAttack()

                        }
                        
                        self.imgView.animation = "shake"
                        self.imgView.animate()
                    }
                   
                    else if result[0].leftEyeClosed || result[0].rightEyeClosed {
                        
                            self.heal()
                        
                    }
                
                    else{
                  
                        self.monsterAttack()
                    
                        }
                    
                }
                
              print(result)
                
            })
        }
    }
    

    
    func initStatus() {
        
        monsterHP_bar.progress = Float(monsternowHP[questcount]) / Float(monsterHP[questcount])
        playerHP_bar.progress = Float(playernowHP) / Float(playerHP)
        playerMP_bar.progress = Float(playernowMP) / Float(playerMP)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func heal(){
        
        if playernowHP < playerHP {
            
            playernowHP = playernowHP + (100 * (Int(rand()%10) + 1))
            //max超えたとき
            if playernowHP > playerHP {
                playernowHP = playerHP
            }
            playerHP_bar.progress = Float(playernowHP) / Float(playerHP)
            playerHP_label.text = "\(playernowHP)"
            monsterHP_bar.progress = Float(monsternowHP[questcount]) / Float(monsterHP[questcount])
            monsterHP_label.text = "\(monsternowHP[questcount])"
            
        }
                
    }
    
    
    
    
    
    
    //プレイヤーの攻撃
    func playerAttack(){
        
        let attack = Float(playerAP) * Float(Int(rand()%10) + 1) / 10
        
        monsternowHP[questcount] = monsternowHP[questcount] - Int(attack)
        //MPゲット
        playernowMP = playernowMP + Int(attack) * 2
        
        if playernowMP > playerMP {
            
            playernowMP = playerMP
        }
        
        //モンスターのHPが0になったら
        
        if monsternowHP[questcount] <= 0 {
            
            monsternowHP[questcount] = 0
            
            finishBattle(true)
        }
        
        playerMP_bar.progress = Float(playernowMP) / Float(playerMP)
        playerMP_label.text = "\(playernowMP)"
        monsterHP_bar.progress = Float(monsternowHP[questcount]) / Float(monsterHP[questcount])
        monsterHP_label.text = "\(monsternowHP[questcount])"
        
        
        monsterAttack()
        
    }
    
    //必殺技
    func specialAttack(){
        
        let attack = Float(playerAP) + Float(playernowMP) * Float(Int(rand()%10) + 1) / 10
        
        monsternowHP[questcount] = monsternowHP[questcount] - Int(attack)

        playernowMP = 0
        
        if playernowMP > playerMP {
            
            playernowMP = playerMP
        }
        
        //モンスターのHPが0になったら
        
        if monsternowHP[questcount] <= 0 {
            
            monsternowHP[questcount] = 0
            
            finishBattle(true)
        }
        
        playerMP_bar.progress = Float(playernowMP) / Float(playerMP)
        playerMP_label.text = "\(playernowMP)"
        monsterHP_bar.progress = Float(monsternowHP[questcount]) / Float(monsterHP[questcount])
        monsterHP_label.text = "\(monsternowHP[questcount])"
        
        
        monsterAttack()
        
    }
    
    //モンスターの攻撃
    func monsterAttack(){
        
        
        
        let attack : Float=Float(monsterAP[questcount]) * Float(Int(rand()%10) + 1) / 10
        
        playernowHP = playernowHP - Int(attack)
        //プレイヤーのHPが0になったら
        
        if playernowHP <= 0 {
            
            playernowHP = 0
            finishBattle(false)
        }
        
        playerHP_bar.progress = Float(playernowHP) / Float(playerHP)
        playerHP_label.text = "\(playernowHP)"
        
        
        
        
    }
    
    
  //後々
    func quest() {
        
        
        if questcount<4 {
            let monster=[monsterArray[questcount],monsternowHP[questcount],monsterAP[questcount]]
            print(monster)
        }
        else{
            print("clear")
            questcount=0
        }
        print(questcount)
        questcount=questcount+1
        
        
    }
    
    
    func finishBattle(winPlayer : Bool) {
        
        var finishedMessage:String!
        
       
        
        if winPlayer == true {
            
            finishedMessage = "プレイヤーの勝利!!\nおめでとう!!"
            
        }
        else {
            
            finishedMessage = "プレイヤーの敗北...\nくじけずリトライ!!"
            
        }
        
        let  alert = UIAlertController(title: "バトル終了", message: finishedMessage, preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: {action in self.dismissViewControllerAnimated(true, completion: nil)}))
        
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
