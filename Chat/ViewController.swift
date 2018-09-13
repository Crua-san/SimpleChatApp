import UIKit
import SCLAlertView
import Firebase
import SwipeCellKit


//MARK: - ViewController
class ViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    
    enum ButtonStyle {
        case backgroundColor, circular
    }
    
    var senderId: String?
    var senderDisplayName: String?
    var userMessagesArray: [UserMessage] = []
    var defaultOptions = SwipeOptions()
    var buttonStyle: ButtonStyle = .circular
    var swipeCounter: UInt = 1
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(ViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        refreshControl.tintColor = UIColor.blue
        
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startApp()
        setUserData()
        tapGestureRecognizer()
        getDataFromFirebase()
        self.tableView.addSubview(self.refreshControl)
    }
    
    //MARK: - startApp Fuction
    
    func startApp () {
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.keyboardDismissMode = .onDrag
        messageTextField.autocorrectionType = .no
        tableView.register(UINib.init(nibName: incomingBubbleTableViewCell.capitalizingFirstLetter(), bundle: nil), forCellReuseIdentifier: incomingBubbleTableViewCell)
        tableView.register(UINib.init(nibName: outcomingTableViewCell.capitalizingFirstLetter(), bundle: nil), forCellReuseIdentifier: outcomingTableViewCell)
    }
    
    //MARK: - setUserData Fuction
    
    func setUserData() {
        let defaults = UserDefaults.standard
        if let id = defaults.string(forKey: "jsq_id"),
            let name = defaults.string(forKey: "jsq_name") {
            senderId = id
            senderDisplayName = name
        } else {
            senderId = String(arc4random_uniform(999999))
            senderDisplayName = ""
            defaults.set(senderId, forKey: "jsq_id")
            defaults.synchronize()
            showDisplayNameDialog()
            title = "Chat: \(senderDisplayName!)"
        }
    }
    
    //MARK: - tapGestureRecognizer Fuction

    func tapGestureRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showDisplayNameDialogFromSelector))
        tapGesture.numberOfTapsRequired = 1
        navigationController?.navigationBar.addGestureRecognizer(tapGesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    
    //MARK: - Get data from Firebase
    
    func getDataFromFirebase(toLast lastItemsNumber: UInt = messagesLimit) {
        userMessagesArray = []
        let query = Constants.refs.databaseChats.queryLimited(toLast: lastItemsNumber)
        Constants.refs.databaseChats.removeAllObservers()
        query.observe(.childAdded, with: { [weak self] snapshot in
            if let data     = snapshot.value as? [String: String],
                let id       = data["sender_id"],
                let name     = data["name"],
                let text     = data["text"],
                let time     = data["time"],
                !text.isEmpty {
                
                let userKey = snapshot.key
                let message = UserMessage(senderId: id, userName: name, userMessage: text, timeStamp: time, senderKey: userKey)
                self?.userMessagesArray.append(message)
                self?.userMessagesArray.sort(by: {$1.timeStamp > $0.timeStamp})
                self?.tableView.reloadData()
                let indexPath = NSIndexPath(item: (self?.userMessagesArray.count)! - 1, section: 0)
                self?.tableView.scrollToRow(at: indexPath as IndexPath, at: UITableViewScrollPosition.bottom, animated: true)
            }
        })
        
        query.observe(.childRemoved, with: { [weak self] snapshot in
            if let data     = snapshot.value as? [String: String],
                let id       = data["sender_id"],
                let name     = data["name"],
                let text     = data["text"],
                let time     = data["time"],
                !text.isEmpty {
                
                let userKey = snapshot.key
                let message = UserMessage(senderId: id, userName: name, userMessage: text, timeStamp: time, senderKey: userKey)
                if let userMessagesArray = self?.userMessagesArray.filter({ $0.senderKey != message.senderKey }) {
                    self?.userMessagesArray = userMessagesArray
                    self?.tableView.reloadData()
                }
            }
        })
    }
    
    //MARK: - Display name dialog
    
    func showDisplayNameDialog(message: String? = nil) {
        let defaults = UserDefaults.standard
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton: false,
            shouldAutoDismiss: false
        )
        
        let alert = SCLAlertView(appearance: appearance)
        
        
        let userNameTextField = alert.addTextField()
        
        userNameTextField.autocorrectionType = .no
        
        alert.addButton("Submit", backgroundColor: UIColor.blue, textColor: .white) {
            if let textField = userNameTextField.text, textField.count > 0 {
                self.senderDisplayName = textField
                var senderId = String(arc4random_uniform(999999))
                for message in self.userMessagesArray {
                    if message.userName == self.senderDisplayName {
                        senderId = message.senderId
                    }
                }
                self.senderId = senderId
                defaults.set(self.senderId, forKey: "jsq_id")
                defaults.set(textField, forKey: "jsq_name")
                defaults.synchronize
                alert.hideView()
                self.title = "Chat: \(self.senderDisplayName!)"
                self.tableView.reloadData()
            } else {
                userNameTextField.layer.borderColor = UIColor.red.cgColor
                userNameTextField.placeholder = "Please enter valid user name."
            }
        }
        alert.addButton("Cancel", backgroundColor: UIColor.red, textColor: .white) {
            alert.hideView()
        }
        alert.showWarning("Name Receipt", subTitle: "Please enter valid user name:")
    }
    
    @objc func showDisplayNameDialogFromSelector() {
        self.showDisplayNameDialog(message: nil)
    }
    
    //MARK: - Keyboard functions
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += keyboardSize.height
            }
        }
    }
    
    //MARK: - Button send
    
    @IBAction func sendButtonPressed(_ sender: UIButton) {
        let ref = Constants.refs.databaseChats.childByAutoId()
        let senderId = UserDefaults.standard.string(forKey: "jsq_id")
        let currentTime = NSDate().timeIntervalSince1970 * 1000
        let time = String(describing: currentTime)
        
        if let messageText = messageTextField.text, messageText.count > 0 {
            if let senderId = senderId, let name = senderDisplayName {
                let message = ["sender_id": senderId, "name": name, "text": messageText, "time": time]
                ref.setValue(message)
                messageTextField.text = ""
            } else {
                SCLAlertView().showError("Error", subTitle: "Some user data is lost")
            }
        } else {
            SCLAlertView().showError("Error", subTitle: "Please enter your message")
        }
    }
}

//MARK: UITableViewDelegate, UITableViewDataSource

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.swipeCounter = self.swipeCounter + 1
        getDataFromFirebase(toLast: messagesLimit * swipeCounter)
        tableView.reloadData()
        refreshControl.endRefreshing()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if self.tableView.numberOfRows(inSection: 0) != 0 {
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.userMessagesArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = self.userMessagesArray[indexPath.row]
        if senderId == message.senderId {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: outcomingTableViewCell, for: indexPath) as! OutcomingTableViewCell
            cell.delegate = self
            cell.outcomingBubbleMessage.text = message.userMessage
            cell.sizeToFit()
            cell.outcomingBubbleMessage.numberOfLines = 0
            return cell
        } else {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: incomingBubbleTableViewCell, for: indexPath) as! IncomingBubbleTableViewCell
            cell.delegate = self
            cell.incomingBubbleMessage.text = message.userMessage
            cell.incomingBubbleName.text = message.userName
            cell.sizeToFit()
            cell.incomingBubbleMessage.numberOfLines = 0
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        tableView.estimatedRowHeight = 60.0 // standard tableViewCell height
        tableView.rowHeight = UITableViewAutomaticDimension
        
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}

//MARK: SwipeTableViewCellDelegate

extension ViewController: SwipeTableViewCellDelegate {
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        
        let message = self.userMessagesArray[indexPath.row]
        if senderId == message.senderId {
            guard orientation == .right else { return nil }
            
            let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
                let message = self.userMessagesArray[indexPath.row]
                let postKey = message.senderKey
                let thisPostRef = Constants.refs.databaseChats.child(postKey!)
                if (message.senderId) != nil {
                    self.userMessagesArray.remove(at: indexPath.row)
                    thisPostRef.removeValue()
                    self.tableView.deleteRows(at: [indexPath], with: .left)
                }
            }
            deleteAction.image = UIImage(named: "delete")
            deleteAction.backgroundColor = UIColor.white
            return [deleteAction]
        } else { return nil }
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.transitionStyle = defaultOptions.transitionStyle
        
        switch buttonStyle {
        case .backgroundColor:
            options.buttonPadding = 34
        case .circular:
            options.buttonPadding = 34
            options.backgroundColor = UIColor.red
        }
        return options
    }
}


//MARK: - UITextFieldDelegate

extension ViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        return true
    }
}

//MARK: - String Extension

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}
