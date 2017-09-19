//
//  ChatViewController.swift
//  Bourdain
//
//  Created by Karen Ho on 9/17/17.
//  Copyright © 2017 Karen Ho. All rights reserved.
//

import Foundation
import UIKit
import JSQMessagesViewController
import ChameleonFramework
import Hyphenate

struct User {
    let id: String
    let name: String
}

var count = 0

class ChatViewController: JSQMessagesViewController, EMChatroomManagerDelegate {
    
    let user1 = User(id: "1", name: "jane")
    let user2 = User(id: "2", name: "david")
    let user3 = User(id: "3", name: "stan")
    let user4 = User(id: "4", name: "sally")
    let user5 = User(id: "5", name: "kevin")
    
    var messages = [JSQMessage]()
    
    var conversation: EMConversation?
    
    let dinnerImage = JSQPhotoMediaItem(image: UIImage(named: "dinner"))
    let tomatoImage = JSQPhotoMediaItem(image: UIImage(named: "tomato"))
    
    let sender = EMClient.shared().currentUsername
    var numberMessageSent = 0
    //let message1 = JSQMessage(senderId: "2", displayName: "Stan", text: "It is business casual, like Cali casual with American (New) food.")
    //let message2 = JSQMessage(senderId: "3", displayName: "David", text: "It is smaller, more plush, more intimate, and less hectic than the previous iterations of this restaurant.")
    
    
    var currentUser: User {
        return user1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        if count == 0 {
            //messages = [message1!, message2!]
            
            var hyphenateMessages = [JSQMessage]()
            EMClient.shared().roomManager.joinChatroom("27520287178753", completion: {(chatroom, error) in
                if error != nil {
                    NSLog("\(error)")
                }
            })
            self.conversation = EMClient.shared().chatManager.getConversation("27520287178753", type: EMConversationTypeChatRoom, createIfNotExist: false)
            self.conversation?.loadMessagesStart(fromId: nil, count: 10, searchDirection: EMMessageSearchDirectionUp, completion: { (messages, aError) in
                if let chatMessages = messages {
                    for message in chatMessages {
                        if let chatMessage = message as? EMMessage {
                            let body = chatMessage.body
                            if body?.type == EMMessageBodyTypeText {
                                let text = (body as! EMTextMessageBody).text
                                if let chatText = text {
                                    var senderId = chatMessage.from
                                    if chatMessage.from == "bourdain" {
                                        senderId = "b"
                                    }
                                    let displayMessage = JSQMessage(senderId: senderId, displayName: chatMessage.from, text: chatText)
                                    hyphenateMessages.append(displayMessage!)
                                }
                            }
                        }
                    }
                }
                self.messages = hyphenateMessages
                self.collectionView.reloadData()
            })
        } else {
            messages = []
        }
        count += 1
        
        self.senderId = currentUser.id
        self.senderDisplayName = currentUser.name

        self.collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        self.collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return 15
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.row]
        let messageUsername = message.senderDisplayName
        
        return NSAttributedString(string: messageUsername!)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        
        let message = messages[indexPath.row]
        
        if message.senderDisplayName == "bourdain" {
            return bubbleFactory?.incomingMessagesBubbleImage(with: UIColor(hexString: "6E00AB"))
        } else if currentUser.id == message.senderId {
            return bubbleFactory?.outgoingMessagesBubbleImage(with: UIColor(hexString: "2DA1FD"))
        } else {
            return bubbleFactory?.incomingMessagesBubbleImage(with: UIColor(hexString: "A3A3A3"))
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let message = JSQMessage(senderId: senderId, displayName: senderDisplayName, text: text)
        
        messages.append(message!)
        
        let body = EMTextMessageBody.init(text: text)
        let msg = EMMessage.init(conversationID: "27520287178753", from: sender, to: "27520287178753", body: body, ext: nil)
        msg!.chatType = EMChatTypeGroupChat
        
        DispatchQueue.global().async {
            EMClient.shared().chatManager.send(msg, progress: nil) { (message, error) in
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
        }
        
        DispatchQueue.global().async {
            self.sendMessageToServer(message: text)
        }
        
        if count == 1 {
            if numberMessageSent == 0 {
                let when = DispatchTime.now() + 2
                DispatchQueue.main.asyncAfter(deadline: when) {
                    let message3 = JSQMessage(senderId: "4", displayName: "sally", text: "I'm a vegan too and they’re great here! The marinara sauce is to die for.")
                    
                    let message4 = JSQMessage(senderId: "4", displayName: "sally", media: self.dinnerImage)
                    
                    self.messages.append(message3!)
                    self.messages.append(message4!)
                    self.refreshAndScrollToBottom()
                }
                self.numberMessageSent += 1
            } else if numberMessageSent == 1 {
                let when = DispatchTime.now() + 2
                DispatchQueue.main.asyncAfter(deadline: when) {
                    let message5 = JSQMessage(senderId: "5", displayName: "tom", text: "40 mins")
                    self.messages.append(message5!)
                    self.refreshAndScrollToBottom()
                }
            }
        } else {
            if numberMessageSent == 0 {
                let when = DispatchTime.now() + 2
                DispatchQueue.main.asyncAfter(deadline: when) {
                    let bourdainMessage1 = JSQMessage(senderId: "b", displayName: "bourdain", text: "There are many great recommendations for vegans, linguini marinara or the bruschetta with tomato and basil")
                    
                    self.messages.append(bourdainMessage1!)
                    self.refreshAndScrollToBottom()
                    
                    let when = DispatchTime.now() + 2
                    DispatchQueue.main.asyncAfter(deadline: when) {
                        let bourdainImage1 = JSQMessage(senderId: "b", displayName: "bourdain", media: self.dinnerImage)
                        let bourdainImage2 = JSQMessage(senderId: "b", displayName: "bourdain", media: self.tomatoImage)
                        self.messages.append(bourdainImage1!)
                        self.messages.append(bourdainImage2!)
                        self.refreshAndScrollToBottom()
                    }
                }
            }
        }
        
        finishSendingMessage()
    }
    
    func refreshAndScrollToBottom() {
        self.collectionView.reloadData()
        let path = IndexPath(item: self.messages.count - 1, section: 0)
        self.collectionView.scrollToItem(at: path, at: UICollectionViewScrollPosition.top, animated: true)
        
    }
    
    func sendMessageToServer(message: String) {
        //declare parameter as a dictionary which contains string as key and value combination. considering inputs are valid
        
        let parameters = ["message": message] as [String : Any]
        
        //create the url with URL
        let url = URL(string: "https://find-me-outside.herokuapp.com/restaurants/1")!
        
        //create the session object
        let session = URLSession.shared
        
        //now create the URLRequest object using the url object
        var request = URLRequest(url: url)
        request.httpMethod = "POST" //set http method as POST
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
        } catch let error {
            print(error.localizedDescription)
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        //create dataTask using the session object to send data to the server
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
        })
        task.resume()
    }
    
    @IBAction func goBack(_ sender: UIButton) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
}
