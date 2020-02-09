//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit

class TXGroupQRVC: BaseVC {
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var groupImageView: UIImageView!
    @IBOutlet weak var QRImageView: UIImageView!
    var thread : TSGroupThread?
    @IBOutlet var actionBtns: [UIButton]!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "二维码"
        self.setupUI()
        self.setupData()
        
        
        
        
        
    }
    
    private func setupUI(){
        if UIDevice.current.hasIPhoneXNotch {
            self.topConstraint.constant = 108
        }
        self.groupImageView.layer.cornerRadius = 10
        self.groupImageView.clipsToBounds = true
        self.backView.backgroundColor = TXTheme.thirdColor()
        self.groupNameLabel.textColor = TXTheme.titleColor()
        for (_,button) in self.actionBtns.enumerated() {
            button.setTitleColor(UIColor.white, for: .normal)
            button.layer.cornerRadius = 20
            button.clipsToBounds = true
            button.backgroundColor = TXTheme.secondColor()
        }
    }
    
    private func setupData(){
        
        guard let model = self.thread?.groupModel else {
            OWSAlerts.showErrorAlert(message: "群信息错误")
            return
        }
        let name = model.groupName ?? "新群组"
        let attriText = NSMutableAttributedString.init(string: name + "\n", attributes: nil)
        let appendText = NSAttributedString.init(string: "扫一扫，加入群聊", attributes: [NSAttributedString.Key.font : TXTheme.secondTitleFont(size: 12)])
        attriText.append(appendText)
        self.groupNameLabel.attributedText = attriText
        self.groupImageView.image = OWSAvatarBuilder.buildImage(thread: self.thread!, diameter: UInt(self.groupImageView.size.width));

        let  jsonString = "pigram://p.land?g=\(model.groupId)"
        let qrImage = TXTheme.getQRCodeImage(jsonString, fgImage: nil)
        self.QRImageView.image = qrImage
    }

    //保存群
    @IBAction func saveImage(_ sender: UIButton) {
        guard let _ = self.QRImageView.image else {
            return
        }
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, false, 0.0)
        if let  context = UIGraphicsGetCurrentContext(){
            self.view.layer.render(in: context)
            if let viewImage = UIGraphicsGetImageFromCurrentImageContext(){
                TXTheme.saveImage(image: viewImage)
            }
        }
        UIGraphicsEndImageContext();//移除栈顶的基于当前位图的图形上下文
    }
    //分享群
    @IBAction func shareAction(_ sender: UIButton) {
        
        OWSAlerts.showActionSheet(fromVC: self, title: "分享群名片", message: "请选择分组", options: ["我的群组","我的好友"]) { [weak self] (index) in
            
            if index == 0 {
                
               GroupListVC.showGroupSelectVC(fromVC: self!, filters: [(self?.thread!.groupModel)!]) { [weak self] (vc, results) in
                                  if results != nil {
                                      self?.handleOpationResults(vc:vc, results: results!);
                                  }
                              }
                
            } else if index == 1 {
                ContactListVC.showVC(self!, navTitle: "选择好友", rightNavTitle: "完成") { [weak self] (vc, results) in
                                   self?.handleOpationResults(vc:vc,results: results);
                               }
               
            }
            
        }
    }
    private func handleOpationResults<T>(vc: UIViewController, results: [T]) {
        if results.count == 0 {
            OWSAlerts.showAlert(title: "请至少选择一项！");
            return;
        }
        if self.QRImageView.image == nil {
            OWSAlerts.showAlert(title: "没有生成二维码！");
            return;
        }
        
        var qrImg = UIImage.init(ciImage: (self.QRImageView.image?.ciImage)!);
        qrImg = qrImg.resize(width: qrImg.size.width, height: qrImg.size.height)!;
        
        let imgData = qrImg.jpegData(compressionQuality: 0.3);
        
//        self.testShowImage(img: qrImg);
//        vc.dismiss(animated: true, completion: nil);
//        return
        
        let datasource = DataSourceValue.dataSource(with: imgData!, fileExtension: "jpeg");
                
        if let _results = results as? [OWSUserProfile] {
            
                for item in _results {
                    
                    let thread = TSContactThread.getOrCreateThread(contactAddress: item.address);
                    self.tryToSendQRAttactchment(dataSource: datasource!, thread: thread);
            }
            
            
        } else if let _results = results as? [TSGroupModel] {
            
                for item in _results {
                    
                    let thread = TSGroupThread.getOrCreateThread(with: item);
                    if thread.shouldThreadBeVisible == false {
                        kSignalDB.write { (write) in
                            thread.anyUpdateGroupThread(transaction: write) { (thread) in
                                thread.shouldThreadBeVisible = true;
                            }
                        }
                    }
                    self.tryToSendQRAttactchment(dataSource: datasource!, thread: thread);
                    
                }
        }
        vc.dismiss(animated: true, completion: nil);
        
    }
    
    // MARK: 发送二维码到群组或好友
    private func tryToSendQRAttactchment(dataSource: DataSource,thread: TSThread) {
       
        
        let attachment = SignalAttachment.attachment(dataSource: dataSource, dataUTI: "public.jpeg", imageQuality: .original);
        
        kSignalDB.uiRead { (read) in
            ThreadUtil.enqueueMessage(withText: nil, mediaAttachments: [attachment], in: thread, quotedReplyModel: nil, linkPreviewDraft: nil,mentions: nil, transaction: read);
        }
        
        
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
