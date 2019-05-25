import ApplicativeRouter
import Foundation
import Prelude

public struct InteractiveMessageAction {
  public var actions: [Slack.Message.Attachment.InteractiveAction]
  public var callbackId: String
  public var user: User
  public var responseURL: URL
  public var originalMessage: Message
  
  public struct Message {
    public var text: String
  }
  
  public struct User {
    public var id: Slack.User.Id
  }
  
  enum CodingKeys: String, CodingKey {
    case actions
    case callbackId = "callback_id"
    case user
    case responseURL = "response_url"
    case originalMessage = "original_message"
  }
}

extension InteractiveMessageAction: Codable, Equatable {}
extension InteractiveMessageAction.Message: Codable, Equatable {}
extension InteractiveMessageAction.User: Codable, Equatable {}

extension InteractiveMessageAction {
  public var absence: Absence? {
    return Data(base64Encoded: self.callbackId)
      .flatMap { try? JSONDecoder().decode(Absence.self, from: $0)}
  }
}

//todo:

/*
 
 Error
 {
 "response_type": "ephemeral",
 "replace_original": false,
 "text": "Sorry, that didn't work. Please try again."
 }
 */
