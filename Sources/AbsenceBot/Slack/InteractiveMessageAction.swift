import ApplicativeRouter
import Foundation
import Prelude

public struct InteractiveMessageAction {
  public private(set) var actions: [Slack.Message.Attachment.InteractiveAction]
  public private(set) var callbackId: String
  public private(set) var user: User
  public private(set) var channel: Channel
  public private(set) var responseURL: URL
  public private(set) var originalMessage: Message
  
  public struct Message {
    public private(set) var text: String
  }
  
  public struct User {
    public private(set) var id: String
    public private(set) var name: String
  }
  
  public struct Channel {
    public private(set) var id: String
    public private(set) var name: String
  }
  
  enum CodingKeys: String, CodingKey {
    case actions
    case callbackId = "callback_id"
    case user
    case channel
    case responseURL = "response_url"
    case originalMessage = "original_message"
  }
}

extension InteractiveMessageAction: Codable, Equatable {}
extension InteractiveMessageAction.Message: Codable, Equatable {}
extension InteractiveMessageAction.User: Codable, Equatable {}
extension InteractiveMessageAction.Channel: Codable, Equatable {}

//todo:

/*
 
 Error
 {
 "response_type": "ephemeral",
 "replace_original": false,
 "text": "Sorry, that didn't work. Please try again."
 }
 */
