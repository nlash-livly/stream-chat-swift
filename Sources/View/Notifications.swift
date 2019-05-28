//
//  Notifications.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 27/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import UserNotifications
import RxSwift
import RxAppState

public final class Notifications: NSObject {
    enum NotificationUserInfoKeys: String {
        case channelId
        case messageId
    }
    
    public typealias OpenNewMessageCallback = (_ messageId: String, _ channelId: String) -> Void
    
    static let shared = Notifications()
    
    let disposeBag = DisposeBag()
    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var iconBadgeNumber: Int = 0
    
    public var openNewMessage: OpenNewMessageCallback?
    
    override init() {
        super.init()
        clear()
        
        UIApplication.shared.rx.appState.subscribe(onNext: { [weak self] state in
            if state == .active {
                self?.clear()
            }
        })
        .disposed(by: disposeBag)
        
        UNUserNotificationCenter.current().delegate = self
    }
    
    func clear() {
        iconBadgeNumber = 0
        UIApplication.shared.applicationIconBadgeNumber = 0
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    public func askForPermissionsIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            self.authorizationStatus = settings.authorizationStatus
            
            if settings.authorizationStatus == .notDetermined {
                self.askForPermissions()
            } else if settings.authorizationStatus == .denied {
                print("🗞❌ Notifications denied")
            } else {
                print("🗞👍 Notifications authorized (\(settings.authorizationStatus.rawValue))")
            }
        }
        
    }
    
    func askForPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { didAllow, error in
            if didAllow {
                self.authorizationStatus = .authorized
                print("🗞👍 User has accepter notifications")
            } else if let error = error {
                print("🗞❌ User has declined notifications \(error)")
            } else {
                print("🗞❌ User has declined notifications: unknown reason")
            }
        }
    }
}

// MARK: - Message

extension Notifications {
    
    func showIfNeeded(newMessage message: Message, in channel: Channel) {
        DispatchQueue.main.async {
            if UIApplication.shared.appState == .background {
                self.show(newMessage: message, in: channel)
            }
        }
    }
    
    func show(newMessage message: Message, in channel: Channel) {
        guard authorizationStatus == .authorized else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = channel.name
        content.body = message.textOrArgs
        content.sound = UNNotificationSound.default
        iconBadgeNumber += 1
        content.badge = iconBadgeNumber as NSNumber
        
        content.userInfo = [NotificationUserInfoKeys.messageId.rawValue: message.id,
                            NotificationUserInfoKeys.channelId.rawValue: channel.id]
        
        // TODO: Add attchament image or video. The url should refer to a file.
        //  1. Download image.
        //  2. Save to NSTemporaryDirectory() + "notifications" + message id
        //  3. Create attachment
        //  4. When a notification opened, remove all tmp images from NSTemporaryDirectory() + "notifications"
        //    if let attachment = message.attachments.first,
        //        attachment.isImageOrVideo,
        //        let url = attachment.imageURL,
        //        !url.absoluteString.contains(".gif"),
        //        let notificationAttachment = try? UNNotificationAttachment(identifier: attachment.title, url: url) {
        //         content.attachments = [notificationAttachment]
        //    }
        
        let request = UNNotificationRequest(identifier: message.id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Handle Actions

extension Notifications: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
        if let userInfo = response.notification.request.content.userInfo as? [String: String],
            let messageId = userInfo[NotificationUserInfoKeys.messageId.rawValue],
            let chanellId = userInfo[NotificationUserInfoKeys.channelId.rawValue] {
            openNewMessage?(messageId, chanellId)
        }
        
        completionHandler()
    }
}
