//
//  NotificationService.swift
//  RichNotificationExtension
//
//  Created by Uros Krkic on 6/8/17.
//  Copyright © 2017 Uros Krkic. All rights reserved.
//

import UserNotifications
import UIKit

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
	var originalContent: UNMutableNotificationContent!

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
		originalContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            bestAttemptContent.title = "\(bestAttemptContent.title) [modified]"
			bestAttemptContent.subtitle = "\(bestAttemptContent.subtitle) [modified]"
			bestAttemptContent.body = "\(bestAttemptContent.body) [modified]"
			
			guard let attachment = bestAttemptContent.userInfo["attachment"] as? String else {
				print("Bad attachment in push payload!")
				contentHandler(self.originalContent)
				return
			}
			
			let imageUrl = URL(string: attachment)
			let session = URLSession.shared
			
			let task = session.downloadTask(with: imageUrl!, completionHandler: { (url, response, error) in
				guard let url = url else {
					contentHandler(self.originalContent)
					return
				}
				
				do {
					let attachmentID = "attach-" + ProcessInfo.processInfo.globallyUniqueString
					let filePath = NSTemporaryDirectory() + "/" + attachmentID + ".png"
					
					try FileManager.default.moveItem(atPath: url.path, toPath: filePath)
					let attachment = try UNNotificationAttachment(identifier: attachmentID, url: URL(fileURLWithPath: filePath))
					
					bestAttemptContent.attachments.append(attachment)
				}
				catch {
					print("Download file error: \(String(describing: error))")
					contentHandler(self.originalContent)
					return
				}

				contentHandler(bestAttemptContent)
			})
			task.resume()
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
