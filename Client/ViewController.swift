//
//  ViewController.swift
//  VaporSocket_TCP
//
//  Created by liumingxin on 2018/10/27.
//  Copyright © 2018年 liumingxin. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var receiveTextView: UITextView!    //用于显示接收到的消息
    @IBOutlet weak var sendTextView: UITextView!
    
    @IBOutlet weak var Host: UITextField!
    @IBOutlet weak var Port: UITextField!
    
    var connect_flag:Bool = false   //true:客户端已连接上服务器，false:已经关闭客户端
    var recvAreaHexFlag = false    //true:接收区16进制显示，false:接收区按字符显示
    
    //TCP客户端
    var Addr = "192.168.0.104"
    var PortNum : UInt16 = 8080
    lazy var client:TCPClient? = {
        return nil
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        receiveMessage_client()
    }
    
    @IBAction func ConnectServer(_ sender: UIButton) {
        let Addr = Host.text!
        let PortNum:UInt16 = UInt16(Port.text!) ?? 8080
        let exit = "exit"
        var title = "打开"
        var close_flag:Bool = false
        
        //关闭当前客户端
        if connect_flag == true {
            do{
                if client?.socket.isClosed == false {
                    try client?.send(bytes: exit.toBytes())
                    try client!.close() //关闭客户端与服务端链接
                    close_flag = true
                    connect_flag = false
                }
            }catch {
                print("Close Error: \(error)")
            }
        }
        //当前没有连接则初始化客户端
        if connect_flag == false && close_flag == false {
            //先关闭当前客户端
            do{
                if client?.socket.isClosed == false{
                    try client?.send(bytes: exit.toBytes())
                    try client!.close() //关闭客户端与服务端链接
                }
            }catch {
                print("Close Error: \(error)")
            }
            
            client = {
                //初始化客户端
                let address = InternetAddress(hostname: Addr, port: PortNum)
                do {
                    connect_flag = true
                    return try TCPClient.init(address: address, connectionTimeout: 1.0)
                } catch {
                    print("Init Error: \(error)")
                    self.receiveTextView.text = "Connect failed!\n"
                    print("Connect failed!", Addr, ":", PortNum)
                    
                    connect_flag = false
                    return nil
                }
            }()
            
            //客户端打开成功
            if connect_flag == true {
                self.receiveTextView.text = "Connect success!\n"
                print("Connect success!", Addr, ":", PortNum)
            }
        }
        
        
        if connect_flag == false{
            title = "连接"
            sender.backgroundColor = UIColor.init(red: 97/255, green: 145/255, blue: 247/255, alpha: 1)
        }else{
            title = "断开"
            sender.backgroundColor = UIColor.init(red: 0, green: 0.7, blue: 0, alpha: 1)
        }
        sender.setTitle(title, for: .normal)
    }
    
    //接收服务器的数据并显示在TextView上
    func receiveMessage_client(){
        DispatchQueue.global(qos: .background).async {
            while true {
                if self.connect_flag == true {
                    do {
                        let recvData = try self.client?.receiveAll().toString() ?? ""
                        
                        var str:String = ""
                        //转换成16进制字符串
                        if self.recvAreaHexFlag == true {
                            for char in recvData.utf8 {
                                let s = String(format: "%02X", char)
                                str = str + " " + s
                            }
                        } else {
                            str = recvData
                        }
                        //接收服务器消息并显示在界面上（改变TextView中内容必须在主线程中进行）
                        if str != "" {
                            DispatchQueue.main.async {
                                self.receiveTextView.text = self.receiveTextView.text + "[receive:] \(str )\n"
                            }
                        }
                    } catch {
                        print("Error \(error)")
                    }
                }
                
            }
        }
    }
    
    //发送消息
    @IBAction func sendMessage(_ sender: Any) {
        do {
            let message = self.sendTextView.text
            if client?.socket.isClosed == false {
                if message != nil && message != "" {
                    try client?.send(bytes: message!.toBytes())
                }
            }else {
                print("Client is closed!\n")
                self.receiveTextView.text = self.receiveTextView.text + "Client is closed!\n"
            }
            
        } catch {
            print("Error \(error)")
        }
    }
    
    //清空发送区的内容
    @IBAction func ClearSendArea(_ sender: UIButton) {
        sendTextView.text = ""
    }
    
    //清空接收区的内容
    @IBAction func ClearReceiveArea(_ sender: UIButton) {
        receiveTextView.text = ""
    }
    
    @IBAction func RecvAreaHexDisp(_ sender: UIButton) {
        recvAreaHexFlag = !recvAreaHexFlag
        if recvAreaHexFlag == true {
            sender.backgroundColor = UIColor.init(red: 0, green: 0.7, blue: 0, alpha: 1)
        } else {
            sender.backgroundColor = UIColor.init(red: 97/255, green: 145/255, blue: 247/255, alpha: 1)
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

