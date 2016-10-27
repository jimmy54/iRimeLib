//
//  Catboard.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 9/24/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit


/*
This is the demo keyboard. If you're implementing your own keyboard, simply follow the example here and then
set the name of your KeyboardViewController subclass in the Info.plist file.
*/




//// /////////////////
var showTypingCellInExtraLine = getShowTypingCellInExtraLineFromSettings()

func updateShowTypingCellInExtraLine() {
    showTypingCellInExtraLine = getShowTypingCellInExtraLineFromSettings()
}

func getShowTypingCellInExtraLineFromSettings() -> Bool {
    return NSUserDefaults.standardUserDefaults().boolForKey("kShowTypingCellInExtraLine")    // If not exist, false will be returned.
}

func getEnableGestureFromSettings() -> Bool {
    return NSUserDefaults.standardUserDefaults().boolForKey("kGesture")    // If not exist, false will be returned.
}

var cornerBracketEnabled = getCornerBracketEnabledFromSettings()

func updateCornerBracketEnabled() {
    cornerBracketEnabled = getCornerBracketEnabledFromSettings()
}

func getCornerBracketEnabledFromSettings() -> Bool {
    return NSUserDefaults.standardUserDefaults().boolForKey("kCornerBracket")    // If not exist, false will be returned.
}

var candidatesBannerAppearanceIsDark = false

let indexPathZero = NSIndexPath(forRow: 0, inSection: 0)
let indexPathFirst = NSIndexPath(forRow: 1, inSection: 0)

var startTime: NSDate?


//// //////////






let kCatTypeEnabled = "kCatTypeEnabled"

class Catboard: KeyboardViewController,RimeNotificationDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var rimeSessionId_ : RimeSessionId = 0
    var candidateList:[CandidateModel]! = Array<CandidateModel>()
    var isChineseInput: Bool = true
    var switchInputView:KeyboardKey?
    var candidatesBanner: CandidatesBanner?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        NSUserDefaults.standardUserDefaults().registerDefaults([kCatTypeEnabled: true])
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("input viewDidLoad");
        
//        RimeSchemaList list;
//        rime_get_api()->get_schema_list(&list);
        
       
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        print("------------------viewDidAppear---------------------")
         RimeWrapper .setNotificationDelegate(self)
        if RimeWrapper.startService() {
            
            print("start service success");
            
        }else{
            
            print("start service error");
            
        }
    }
    
    deinit{
        
        print("-------------------------deinit---------------------------")
        RimeWrapper.destroySession(rimeSessionId_)
        RimeWrapper.stopService()
        
    }
    
    override func keyPressed(key: Key) {
        
        let textDocumentProxy = self.textDocumentProxy
        
        if self.isChineseInput == false {
            if key.type == .Backspace {
                textDocumentProxy.deleteBackward()
                return;
            }
            super.keyPressed(key)
            return
        }
        
        //中文输入
        if !RimeWrapper.isSessionAlive(rimeSessionId_) {
            rimeSessionId_ = RimeWrapper.createSession()
        }
        
        //返回键
        if key.type == .Return {
            
            if RimeWrapper.isSessionAlive(self.rimeSessionId_) == false {
                print("按键-->session 不存在")
                return;
            }
            let c: XRimeContext = RimeWrapper.contextForSession(rimeSessionId_)
            var preedite:String? = c.composition.preeditedText
            if preedite?.characters.count > 0{
                
                preedite = preedite!.stringByReplacingOccurrencesOfString(" ", withString: "")//去掉所有空格
                
                textDocumentProxy.insertText(preedite!)
                RimeWrapper.clearCompositionForSession(self.rimeSessionId_)
                
                self.candidateList.removeAll()
                self.candidatesBanner?.reloadData()
                
                return;
            }
            
            textDocumentProxy.insertText("\n")
            return
       }
        

        
        //数字，符号等
        //--------------------------------------------------
        let keyOutput = key.outputForCase(self.shiftState.uppercase())
        
        if !NSUserDefaults.standardUserDefaults().boolForKey(kCatTypeEnabled) {
            textDocumentProxy.insertText(keyOutput)
            return
        }
        
        if key.type == .SpecialCharacter {
            if let context = textDocumentProxy.documentContextBeforeInput {
                if context.characters.count < 2 {
                    textDocumentProxy.insertText(keyOutput)
                    return
                }
                
                var index = context.endIndex
                
                index = index.predecessor()
                if context[index] != " " {
                    textDocumentProxy.insertText(keyOutput)
                    return
                }
                
                index = index.predecessor()
                if context[index] == " " {
                    textDocumentProxy.insertText(keyOutput)
                    return
                }
                
                textDocumentProxy.insertText(" ")
                textDocumentProxy.insertText(keyOutput)
                return
            }
            else {
                textDocumentProxy.insertText(keyOutput)
                return
            }
        }else if key.type == .Space{
            
            textDocumentProxy.insertText(" ");
            return;
            
        }

        //----------------------------------------------
        
        let ko = key.outputForCase(self.shiftState.uppercase())
//        let ko = key.lowercaseOutput
        let nsstrTest:NSString = ko as NSString
        let result = nsstrTest.UTF8String[0] //result = 99
        
        
        //删除按钮
        var r = Int32(result)
        if key.type == .Backspace {
            r = Int32(XK_BackSpace)
        }
        

        let h = RimeWrapper.inputKeyForSession(rimeSessionId_, rimeKeyCode: r, rimeModifier: 0)
        if h == false {
            textDocumentProxy.deleteBackward()
            self.candidateList.removeAll()
            self.candidatesBanner?.reloadData()
            return;
        }
        
        
        let cl = RimeWrapper.getCandidateListForSession(rimeSessionId_) as? [String]
        
        if (cl == nil) {
            self.candidateList.removeAll()
        }else{
            
            self.addCandidates(cl!)
            
        }
        
        self.candidatesBanner?.reloadData()
        
        return;
        
    }
    
    func addCandidates(strings:[String]) {
        
        self.candidateList.removeAll()
        for s in strings {
            let candidate = CandidateModel()
            candidate.text = s
            self.candidateList.append(candidate)
        }
        
    }
    
    
    override func setupKeys() {
        super.setupKeys()
        
        
        for page in keyboard.pages  {
            for rowKeys in page.rows {
                for key in rowKeys {
                    if let keyView = self.layout?.viewForKey(key){
                        
                        if key.type == .SwitchInput {
                            self.changeSwitchInputButtonText()
                            self.switchInputView = keyView
                            keyView .removeTarget(nil, action: nil, forControlEvents: UIControlEvents.AllEvents)
                            keyView.addTarget(self, action: #selector(Catboard.switchInputTouchUp), forControlEvents: UIControlEvents.TouchUpInside)
                            keyView.addTarget(self, action: #selector(Catboard.switchInputTouchDown), forControlEvents: UIControlEvents.TouchDown)
                            
                            break;
                        }
                    }

                }
            }
        }
        
    }
    
    override func createBanner() -> ExtraView? {
        
        candidatesBanner = CandidatesBanner(globalColors: self.dynamicType.globalColors, darkMode: false, solidColorMode: self.solidColorMode())
        candidatesBanner!.delegate = self
        
        return candidatesBanner
    }
    
    
    // KeyboardViewController
    override func updateAppearances(appearanceIsDark: Bool) {
        candidatesBannerAppearanceIsDark = appearanceIsDark
        super.updateAppearances(appearanceIsDark)
        candidatesBanner?.updateAppearance()
    }
    
    
    var currentOrientation: UIInterfaceOrientation? = nil
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        super.willRotateToInterfaceOrientation(toInterfaceOrientation, duration: duration)
        currentOrientation = toInterfaceOrientation
        self.candidatesBanner?.willRotateToInterfaceOrientation(toInterfaceOrientation, duration: duration)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated
        
    }
    
    //collocetionView
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath){
        
        self.selectText(indexPath.row)
        self.exitCandidatesTableIfNecessary()
        
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let count = self.candidateList?.count
        print(count)
        return count!
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! CandidateCell
        cell.updateAppearance()
        if (indexPath == indexPathZero) {
            cell.textLabel.textAlignment = .Left
        } else {
            cell.textLabel.textAlignment = .Center
        }
        let candidate = self.candidateList[indexPath.row]
        cell.textLabel.text = candidate.text
        //        cell.textLabel.sizeToFit()
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let candidate = self.candidateList[indexPath.row]
        
        if candidate.textSize == nil{
            candidate.textSize = getCellSizeAtIndex(indexPath, andText: candidate.text, andSetLayout: collectionViewLayout as! UICollectionViewFlowLayout)
        }
        
        return candidate.textSize!
        
    }
    
    
//
    func getCellSizeAtIndex(indexPath: NSIndexPath, andText text: String, andSetLayout layout: UICollectionViewFlowLayout) -> CGSize {
        let size = CandidateCell.getCellSizeByText(text, needAccuracy: indexPath == indexPathZero ? true : false)
        if let myLayout = layout as? MyCollectionViewFlowLayout {
            myLayout.updateLayoutRaisedByCellAt(indexPath, withCellSize: size)
        }
        return size
    }
    
    
    var isShowingCandidatesTable = false
    @IBAction func toggleCandidatesTableOrDismissKeyboard() {
        
        if self.candidateList?.count <= 0 {
            Logger.sharedInstance.writeLogLine(filledString: "[DOWN] <> DISMISS")
            self.dismissKeyboard()
            return
        }
        
        
        if isShowingCandidatesTable == false {
            Logger.sharedInstance.writeLogLine(filledString: "[DOWN] <>")
            isShowingCandidatesTable = true
            showCandidatesTable()
        } else {
            Logger.sharedInstance.writeLogLine(filledString: "[UP] <>")
            isShowingCandidatesTable = false
            exitCandidatesTable()
        }
    }
    
    var candidatesTable: UICollectionView!
    func showCandidatesTable() {
        isShowingCandidatesTable = true
        candidatesBanner!.hideTypingAndCandidatesView()
        candidatesBanner!.changeArrowUp()
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .Vertical
        candidatesTable = UICollectionView(frame: CGRect(x: view.frame.origin.x, y: view.frame.origin.y + getBannerHeight(), width: view.frame.width, height: view.frame.height - getBannerHeight()), collectionViewLayout: layout)
        candidatesTable.backgroundColor = candidatesBannerAppearanceIsDark ? UIColor.darkGrayColor() : UIColor.whiteColor()
        candidatesTable.registerClass(CandidateCell.self, forCellWithReuseIdentifier: "Cell")
        candidatesTable.delegate = self
        candidatesTable.dataSource = self
        self.view.addSubview(candidatesTable)
    }
    
    func exitCandidatesTable() {
        isShowingCandidatesTable = false
        candidatesBanner!.scrollToFirstCandidate()
        candidatesBanner!.unhideTypingAndCandidatesView()
        candidatesBanner!.changeArrowDown()
        candidatesTable.removeFromSuperview()
    }
    
    func exitCandidatesTableIfNecessary() {
        if isShowingCandidatesTable == false {
            return
        }
        exitCandidatesTable()
    }
    
    //tableView
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return (self.candidateList?.count)!
    }
    

    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        
        
        var cell = tableView.dequeueReusableCellWithIdentifier("textCell")
        if cell == nil {
            cell = CandidateTableCellTableViewCell(style: .Default, reuseIdentifier: "textCell")
        }
        
        let c: CandidateTableCellTableViewCell = cell as! CandidateTableCellTableViewCell
        let candidate = self.candidateList[indexPath.row]
        c.txtLabel?.text = candidate.text
        
        return cell!
        
        
        
        
    }
    
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat{
        
        let s = self.candidateList![indexPath.row]
        
        if s.textSize == nil {
            s.textSize = CandidateCell.getCellSizeByText(s.text, needAccuracy: indexPath == indexPathZero ? true : false)
        }
        return s.textSize!.width
        
       
        
    }
    
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        

        self.selectText(indexPath.row)
        self.candidatesBanner?.scrollToFirstCandidate()
        
    }
    
    
    func selectText(index: NSInteger) {
        let res = RimeWrapper.selectCandidateForSession(self.rimeSessionId_, inIndex: index)
        if res == false {
            print("选中没有文字了")
            return;
        }
        
        let comitText = RimeWrapper.consumeComposedTextForSession(self.rimeSessionId_)
        if (comitText != nil) {
            self.textDocumentProxy.insertText(comitText)
            self.candidateList.removeAll()
            self.candidatesBanner?.reloadData()
            return;
        }
        
        let cl = RimeWrapper.getCandidateListForSession(self.rimeSessionId_) as? [String]
        
        if (cl == nil) {
            
            self.candidateList.removeAll()
            
        }else{
            
            self.addCandidates(cl!)
            
        }
        
        self.candidatesBanner?.reloadData()
    }
    
    
    
    func getPreeditedText() -> String {
       
        if RimeWrapper.isSessionAlive(rimeSessionId_) == false {
            return "";
        }
        
        let context: XRimeContext = RimeWrapper.contextForSession(rimeSessionId_)
        return context.composition.preeditedText
    }
    

    
    
    func switchInputTouchDown(){
    }
    
    func switchInputTouchUp(){
        
        self.clearInput()
        self.isChineseInput = !self.isChineseInput
        self.changeSwitchInputButtonText()
        
    }
    
    func changeSwitchInputButtonText() {
        
        if self.isChineseInput {
            self.switchInputView?.label.text = "ABC"
        }else{
            self.switchInputView?.label.text = "返回"
        }
        
    }
    
    func clearInput() {
        
        if RimeWrapper.isSessionAlive(self.rimeSessionId_) == false {
            print("按键-->session 不存在")
            return;
        }
        RimeWrapper.clearCompositionForSession(self.rimeSessionId_)
       
    }

}




