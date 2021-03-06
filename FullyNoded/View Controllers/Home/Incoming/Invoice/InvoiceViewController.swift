//
//  InvoiceViewController.swift
//  BitSense
//
//  Created by Peter on 21/03/19.
//  Copyright © 2019 Fontaine. All rights reserved.
//

import UIKit

class InvoiceViewController: UIViewController, UITextFieldDelegate {
    
    var textToShareViaQRCode = String()
    var addressString = String()
    var qrCode = UIImage()
    let descriptionLabel = UILabel()
    var tapQRGesture = UITapGestureRecognizer()
    var tapAddressGesture = UITapGestureRecognizer()
    var nativeSegwit = Bool()
    var p2shSegwit = Bool()
    var legacy = Bool()
    let spinner = ConnectingView()
    let qrGenerator = QRGenerator()
    var isHDMusig = Bool()
    var isHDInvoice = Bool()
    let cd = CoreDataService()
    var descriptor = ""
    var wallet = [String:Any]()
    
    @IBOutlet var amountField: UITextField!
    @IBOutlet var labelField: UITextField!
    @IBOutlet var qrView: UIImageView!
    @IBOutlet var addressOutlet: UILabel!
    @IBOutlet var minusOutlet: UIButton!
    @IBOutlet var plusOutlet: UIButton!
    @IBOutlet var indexDisplay: UILabel!
    @IBOutlet var indexLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        spinner.addConnectingView(vc: self, description: "fetching address...")
        addressOutlet.isUserInteractionEnabled = true
        addressOutlet.text = ""
        minusOutlet.alpha = 0
        plusOutlet.alpha = 0
        indexLabel.alpha = 0
        indexDisplay.alpha = 0
        amountField.delegate = self
        labelField.delegate = self
        amountField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        labelField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        getAddressSettings()
        addDoneButtonOnKeyboard()
        load()
    }
    
    @IBAction func lightningInvoice(_ sender: Any) {
        spinner.addConnectingView(vc: self, description: "creating lightning invoice...")
        // invoice msatoshi label description
        var millisats = "\"any\""
        var label = "Fully-Noded-\(randomString(length: 5))"
        if amountField.text != nil {
            if let int = Int(amountField.text!) {
                millisats = "\(int * 1000)"
            }
        }
        if labelField.text != "" {
            label = labelField.text!
        }
        let param = "\(millisats), \"\(label)\", \"\(Date())\", \(86400)"
        LightningRPC.command(method: .invoice, param: param) { [unowned vc = self] (response, errorDesc) in
            if let dict = response as? NSDictionary {
                if let bolt11 = dict["bolt11"] as? String {
                    DispatchQueue.main.async { [unowned vc = self] in
                        vc.addressOutlet.alpha = 1
                        vc.addressString = bolt11
                        vc.addressOutlet.text = bolt11
                        vc.showAddress(address: bolt11)
                        vc.spinner.removeConnectingView()
                    }
                }
                if let warning = dict["warning_capacity"] as? String {
                    if warning != "" {
                        showAlert(vc: vc, title: "Warning", message: warning)
                    }
                }
            } else {
                vc.spinner.removeConnectingView()
                showAlert(vc: vc, title: "Error", message: errorDesc ?? "we had an issue getting your lightning invoice")
            }
        }
    }
    
    
    @IBAction func minusAction(_ sender: Any) {
        if indexDisplay.text != "" {
            let index = Int(indexDisplay.text!)!
            if index != 0 {
                //fetch new address then save the updated index
                spinner.addConnectingView(vc: self, description: "fetching address index \(index - 1)")
                DispatchQueue.main.async {
                    self.indexDisplay.text = "\(index - 1)"
                }
                let param = "\(descriptor), [\(index - 1),\(index - 1)]"
                self.executeNodeCommand(method: .deriveaddresses, param: param)
            }
        }
    }
    
    @IBAction func plusAction(_ sender: Any) {
        if indexDisplay.text != "" {
            let index = Int(indexDisplay.text!)!
            if index >= 0 {
                //fetch new address then save the updated index
                spinner.addConnectingView(vc: self, description: "fetching address index \(index + 1)")
                DispatchQueue.main.async {
                    self.indexDisplay.text = "\(index + 1)"
                }
                let param = "\(descriptor), [\(index + 1),\(index + 1)]"
                self.executeNodeCommand(method: .deriveaddresses, param: param)
            }
        }
    }
    
    
    
    func load() {
        addressOutlet.text = ""
        if isHDInvoice {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.2, animations: {
                    self.minusOutlet.alpha = 1
                    self.plusOutlet.alpha = 1
                    self.indexLabel.alpha = 1
                    self.indexDisplay.alpha = 1
                }) { _ in
                    self.getHDMusigAddress()
                }
            }
        } else {
            activeWallet { [unowned vc = self] (wallet) in
                if wallet != nil {
                    let descriptorParser = DescriptorParser()
                    let descriptorStruct = descriptorParser.descriptor(wallet!.receiveDescriptor)
                    if descriptorStruct.isMulti {
                        vc.getReceieveAddressForFullyNodedMultiSig(wallet!)
                    } else {
                        vc.showAddress()
                    }
                } else {
                    vc.showAddress()
                }
            }
        }
    }
    
    private func getReceieveAddressForFullyNodedMultiSig(_ wallet: Wallet) {
        let index = Int(wallet.index) + 1
        CoreDataService.update(id: wallet.id, keyToUpdate: "index", newValue: Int64(index), entity: .wallets) { (success) in
            if success {
                let param = "\"\(wallet.receiveDescriptor)\", [\(index),\(index)]"
                Reducer.makeCommand(command: .deriveaddresses, param: param) { (response, errorMessage) in
                    if let addresses = response as? NSArray {
                        if let address = addresses[0] as? String {
                            DispatchQueue.main.async { [unowned vc = self] in
                                vc.addressOutlet.alpha = 1
                                vc.addressString = address
                                vc.addressOutlet.text = address
                                vc.showAddress(address: address)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func getAddressInfo(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "getAddressInfo", sender: vc)
        }
    }
    
    func getHDMusigAddress() {
        let walletStr = WalletOld(dictionary: wallet)
        Crypto.decryptData(dataToDecrypt: walletStr.descriptor!) { [unowned vc = self] (desc) in
            if desc != nil {
                vc.descriptor = desc!.utf8
                let label = walletStr.label
                let addressIndex = "\(walletStr.index)"
                let param = "\(vc.descriptor), [\(addressIndex),\(addressIndex)]"
                Reducer.makeCommand(command: .deriveaddresses, param: param) { (response, errorMessage) in
                    if let result = response as? NSArray {
                        if let addressToReturn = result[0] as? String {
                            DispatchQueue.main.async { [unowned vc = self] in
                                vc.indexDisplay.text = addressIndex
                                vc.addressOutlet.text = addressToReturn
                                vc.navigationController?.navigationBar.topItem?.title = label
                                vc.addressString = addressToReturn
                                vc.isHDMusig = true
                                vc.showAddress()
                            }
                        }
                    } else {
                        vc.spinner.removeConnectingView()
                        displayAlert(viewController: self, isError: true, message: errorMessage ?? "error deriving addresses")
                    }
                }
            }
        }
    }
    
    func getAddressSettings() {
        let ud = UserDefaults.standard
        nativeSegwit = ud.object(forKey: "nativeSegwit") as? Bool ?? true
        p2shSegwit = ud.object(forKey: "p2shSegwit") as? Bool ?? false
        legacy = ud.object(forKey: "legacy") as? Bool ?? false
    }
    
    func showAddress() {
        if isHDMusig {
            showAddress(address: addressString)
            spinner.removeConnectingView()
            DispatchQueue.main.async { [unowned vc = self] in
                vc.addressOutlet.text = vc.addressString
            }
        } else {
            var params = ""
            if self.nativeSegwit {
                params = "\"\", \"bech32\""
            } else if self.legacy {
                params = "\"\", \"legacy\""
            } else if self.p2shSegwit {
                params = "\"\", \"p2sh-segwit\""
            }
            self.executeNodeCommand(method: .getnewaddress, param: params)
        }
    }
    
    func showAddress(address: String) {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.qrCode = vc.generateQrCode(key: address)
            vc.qrView.image = vc.qrCode
            vc.qrView.isUserInteractionEnabled = true
            vc.qrView.alpha = 0
            vc.view.addSubview(vc.qrView)
            vc.descriptionLabel.frame = CGRect(x: 10, y: vc.view.frame.maxY - 30, width: vc.view.frame.width - 20, height: 20)
            vc.descriptionLabel.textAlignment = .center
            vc.descriptionLabel.font = UIFont.init(name: "HelveticaNeue-Light", size: 12)
            vc.descriptionLabel.textColor = UIColor.white
            vc.descriptionLabel.text = "Tap the QR Code or text to copy/save/share"
            vc.descriptionLabel.adjustsFontSizeToFitWidth = true
            vc.descriptionLabel.alpha = 0
            vc.view.addSubview(vc.descriptionLabel)
            vc.tapAddressGesture = UITapGestureRecognizer(target: vc, action: #selector(vc.shareAddressText(_:)))
            vc.addressOutlet.addGestureRecognizer(vc.tapAddressGesture)
            vc.addressOutlet.text = address
            vc.addressString = address
            vc.tapQRGesture = UITapGestureRecognizer(target: vc, action: #selector(vc.shareQRCode(_:)))
            vc.qrView.addGestureRecognizer(vc.tapQRGesture)
            vc.spinner.removeConnectingView()
            UIView.animate(withDuration: 0.3, animations: { [unowned vc = self] in
                vc.descriptionLabel.alpha = 1
                vc.qrView.alpha = 1
                vc.addressOutlet.alpha = 1
            })
        }
    }
    
    
    @objc func shareAddressText(_ sender: UITapGestureRecognizer) {
        
        UIView.animate(withDuration: 0.2, animations: {
            
            self.addressOutlet.alpha = 0
            
        }) { _ in
            
            UIView.animate(withDuration: 0.2, animations: {
                
                self.addressOutlet.alpha = 1
                
            })
            
        }
        
        DispatchQueue.main.async {
            
            let textToShare = [self.addressString]
            
            let activityViewController = UIActivityViewController(activityItems: textToShare,
                                                                  applicationActivities: nil)
            
            activityViewController.popoverPresentationController?.sourceView = self.view
            self.present(activityViewController, animated: true) {}
            
        }
        
    }
    
    @objc func shareQRCode(_ sender: UITapGestureRecognizer) {
        
        UIView.animate(withDuration: 0.2, animations: {
            
            self.qrView.alpha = 0
            
        }) { _ in
            
            UIView.animate(withDuration: 0.2, animations: {
                
                self.qrView.alpha = 1
                
            }) { _ in
                
                let activityController = UIActivityViewController(activityItems: [self.qrView.image!],
                                                                  applicationActivities: nil)
                
                activityController.popoverPresentationController?.sourceView = self.view
                self.present(activityController, animated: true) {}
                
            }
            
        }
        
    }
    
    func executeNodeCommand(method: BTC_CLI_COMMAND, param: String) {
        print("executeNodeCommand")
        
        func deriveAddresses() {
            Reducer.makeCommand(command: .deriveaddresses, param: param) { [unowned vc = self] (response, errorMessage) in
                if let result = response as? NSArray {
                    if let addressToReturn = result[0] as? String {
                        DispatchQueue.main.async { [unowned vc = self] in
                            vc.spinner.removeConnectingView()
                            vc.addressString = addressToReturn
                            vc.addressOutlet.text = addressToReturn
                            vc.showAddress(address: addressToReturn)
                            let id = vc.wallet["id"] as! UUID
                            CoreDataService.update(id: id, keyToUpdate: "index", newValue: Int32(vc.indexDisplay.text!)!, entity: .newHdWallets) { success in
                                if success {
                                    print("updated index")
                                } else {
                                    print("index update failed")
                                }
                            }
                        }
                    }
                } else {
                    vc.spinner.removeConnectingView()
                    displayAlert(viewController: vc, isError: true, message: errorMessage ?? "error deriving addresses")
                }
            }
        }
        
        func getAddress() {
            Reducer.makeCommand(command: .getnewaddress, param: param) { [unowned vc = self] (response, errorMessage) in
                if let address = response as? String {
                    DispatchQueue.main.async { [unowned vc = self] in
                        vc.spinner.removeConnectingView()
                        vc.addressString = address
                        vc.addressOutlet.text = address
                        vc.showAddress(address: address)
                    }
                } else {
                    vc.spinner.removeConnectingView()
                    showAlert(vc: vc, title: "Error", message: errorMessage ?? "error fecthing address")
                }
            }
        }
        
        switch method {
        case .deriveaddresses:
            deriveAddresses()
            
        case .getnewaddress:
            getAddress()
            
        default:
            break
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        print("textFieldDidChange")
        
        updateQRImage()
        
    }
    
    func generateQrCode(key: String) -> UIImage {
        
        qrGenerator.textInput = key
        let qr = qrGenerator.getQRCode()
        
        return qr
        
    }
    
    func updateQRImage() {
        
        var newImage = UIImage()
        
        if self.amountField.text == "" && self.labelField.text == "" {
            
            newImage = self.generateQrCode(key:"bitcoin:\(self.addressString)")
            textToShareViaQRCode = "bitcoin:\(self.addressString)"
            
        } else if self.amountField.text != "" && self.labelField.text != "" {
            
            newImage = self.generateQrCode(key:"bitcoin:\(self.addressString)?amount=\(self.amountField.text!)&label=\(self.labelField.text!)")
            textToShareViaQRCode = "bitcoin:\(self.addressString)?amount=\(self.amountField.text!)&label=\(self.labelField.text!)"
            
        } else if self.amountField.text != "" && self.labelField.text == "" {
            
            newImage = self.generateQrCode(key:"bitcoin:\(self.addressString)?amount=\(self.amountField.text!)")
            textToShareViaQRCode = "bitcoin:\(self.addressString)?amount=\(self.amountField.text!)"
            
        } else if self.amountField.text == "" && self.labelField.text != "" {
            
            newImage = self.generateQrCode(key:"bitcoin:\(self.addressString)?label=\(self.labelField.text!)")
            textToShareViaQRCode = "bitcoin:\(self.addressString)?label=\(self.labelField.text!)"
            
        }
        
        DispatchQueue.main.async {
            
            UIView.transition(with: self.qrView,
                              duration: 0.75,
                              options: .transitionCrossDissolve,
                              animations: { self.qrView.image = newImage },
                              completion: nil)
            
            impact()
            
        }
        
    }
    
    @objc func doneButtonAction() {
        
        self.amountField.resignFirstResponder()
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        view.endEditing(true)
        return false
        
    }
    
    func addDoneButtonOnKeyboard() {
        
        let doneToolbar = UIToolbar()
        
        doneToolbar.frame = CGRect(x: 0,
                                   y: 0,
                                   width: 320,
                                   height: 50)
        
        doneToolbar.barStyle = UIBarStyle.default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace,
                                        target: nil,
                                        action: nil)
        
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done",
                                                    style: UIBarButtonItem.Style.done,
                                                    target: self,
                                                    action: #selector(doneButtonAction))
        
        let items = NSMutableArray()
        items.add(flexSpace)
        items.add(done)
        
        doneToolbar.items = (items as! [UIBarButtonItem])
        doneToolbar.sizeToFit()
        
        self.amountField.inputAccessoryView = doneToolbar
        
    }
    
    @objc func dismissKeyboard() {
        
        view.endEditing(true)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "getAddressInfo" {
            
            if let vc = segue.destination as? GetInfoViewController {
                
                vc.address = addressString
                vc.getAddressInfo = true
                
            }
            
        }
        
    }

}
