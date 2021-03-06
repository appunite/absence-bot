<p align="center">
    <a href="LICENSE">
        <img src="http://img.shields.io/badge/license-Apache-brightgreen.svg" alt="Apache License">
    </a>
    <a href="https://swift.org">
        <img src="http://img.shields.io/badge/swift-5.0.1-brightgreen.svg" alt="Swift 5.0.1">
    </a>
    <a href="https://travis-ci.org/appunite/absence-bot">
        <img src="https://travis-ci.org/appunite/absence-bot.svg?branch=master" alt="Build Status">
    </a>
</p>

# Idea

This is a side project that I've been working on to play with Server-Side Swift. General idea of this tool is to simplify the process of taking absence by using Slack.
AbsenceBot has already been working on production since the end of February 2019. We feel that a simple chatbot improves our internal process of taking absence in AppUnite. It’s convenient, easy and natural for everyone. As a web framework I've used [pointfreeco/swift-web](https://github.com/pointfreeco/swift-web).✌

## Implementation

In the beginning, we have set specific goals when designing the solution: it has to be fast, simple and feel natural. We’ve started to think about how we can make the process better and we decided that building a chatbot that uses machine learning tools will be the best option that additionally would give us an opportunity to extend our knowledge of ML and chatbots.

We treated this as a side project, and we didn't want to spend too much time on creating it. We've decided to iterate fast and use some existing tools. The crucial part of any chatbot is [Natural Language Processing](https://en.wikipedia.org/wiki/Natural_language_processing) (the process of  taking input provided by users and extract meaning/context out of it). To solve this challenge, we’ve decided to use [Dialogflow](https://dialogflow.com). Dialogflow is a simple but advanced tool that allows to capture and interpret human conversation. As a web framework, we've used [pointfreeco/swift-web](https://github.com/pointfreeco/swift-web). It’s a nice, swift-lang web framework using functional approach.

We’ve defined 5 general categories of absence:
* illness: you’re sick and you don’t plan to work at all, you’re are unavailable 
* holiday: you’re enjoying your free time, you’re are unavailable
* school: you’re generally unavailable, excluding short breaks between lectures
* conference: your availability is limited, excluding short breaks between lectures
* remote: you’re on duty, but just out of office

## In action 

To add an absence our team member simply starts a conversation with @AbsenceBot on Slack. All the chatbot does, is extract two pieces of information from the context: **reason** and **period** of your absence. If some pieces of information are missing, it will provide an additional question that helps it get this information. 

Our team member starts to type and answer chatbot questions. He/She can also simply tell what they need, like in an ordinary human conversation e.g.:

* I’m not feeling good and will take time off till the end of the week,
* I’m going to a conference between 3-5 May.

<img src=".images/screen1.png" height="400" alt="Screenshot"/>

When your request is ready (and after your verification), it’s posted on a dedicated private channel which all supervisors and PMs have an access to and can discuss in a small group a given employee’s absence using Slack threads. Those requests can be approved or rejected by tapping on the interactive buttons. Whenever accepted or rejected, an employee is informed about the status in a feedback message.

<img src=".images/screen2.png" height="400" alt="Screenshot"/>

Accepted requests are added to our internal Google Calendar with a proper title (showing the name of arequester and the reason for an absence), the period of time and participants (an absence requester and an absence approver). Moreover, everyone in the company has a read-only access to this calendar, so everybody can see others’ absences in advance.

<img src=".images/screen4.png" height="300" alt="Screenshot"/>

## Tips&Tricks

Project calendar can be very useful. It can really helps with tracking important events related to the project, such as: certificates expiration, client’s meetings, release deadlines or team member absences. It brings us a lot of benefits, like transparency and improve our work planning.

### Absences

At AppUnite, AbsenceBot is adding all absences into one internal calendar. The amount of events collected by this calendar is sometimes overwhelming, and sometime interesting information can be hidden. That’s why when absence is accepted it’s better to make a copy of an event to dedicated project’s calendar, to better track those types of event by team members.

To do so, there are no needed additional changes in actual process of taking absences, just few additional steps. After your absence is accepted, chat bot is automatically creating a calendar event and informs you about it in a message with appropriate link.

Steps:

1. Open Google Calendar by tapping event link in AbsenceBot feedback message,
2. Tap on settings button in Google’s Calendar Event detail page
3. Tap on “Copy to {calendar}” to copy event to desired project calendar — you can copy to multiple calendars, if necessary

By doing so you inform your team members about you absences, and everything is well organized. The main benefit of this is that you don’t have to deal with clumsy global absences view anymore in order to check your team members absences.

## Tools 

### Dialogflow

Dialogflow is human–computer interaction technology based on natural language processing.
You can find exported model in this repo [here](./au-absence-bot-prod-dialogflow.zip)

### Slack

Right now I'm just supporting Slack as Dialogflow's channel of communication. But it will be easy to extend for other channels such as WhatApp or Messenger.

### Google Calendar

If a particular event is approved, the app is adding an event to Google Calendar.

## ToDo

I think it would  be nice to extend this Readme with information how to setup all services like Google Calendar or Dialogflow and deploy this on Heroku.

## About

This project is made with ❤️ by [AppUnite](https://appunite.com) and maintained by [Emil](http://github.com/emilwojtaszek/).

### License

This project is licensed under the Apache License. See [LICENSE](LICENSE) for more info.
