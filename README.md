<p align="center">
    <a href="LICENSE">
        <img src="http://img.shields.io/badge/license-Apache-brightgreen.svg" alt="Apache License">
    </a>
    <a href="https://swift.org">
        <img src="http://img.shields.io/badge/swift-4.2.1-brightgreen.svg" alt="Swift 4.2.1">
    </a>
    <a href="https://travis-ci.org/appunite/absence-bot">
        <img src="https://travis-ci.org/appunite/absence-bot.svg?branch=master" alt="Build Status">
    </a>
</p>

# Idea

This is an side project that I've been working on to play with Server-Side Swift. General idea of this tool is to simplify process of taking absence using Slack.
AbsenceBot is already working on production since end of February 2019. We feel that simple chatbot improve our internal process of taking absence at AppUnite. It’s convenient, easy and natural for everyone. As a web framework I've used [pointfreeco/swift-web](https://github.com/pointfreeco/swift-web).✌

## Implementation

In the beginning, we have set specific goals when designing the solution: it needs to be fast, simple and natural. We’ve started to think about how we can make the process better and we decided that building chatbot which uses machine learning tools will be the best option and give us possibility to learn new things.

This still was a side job project, and we didn't want to spend to much time for development on it. We've decided to iterate fast and use some existing tools. The crucial part of any chatbot is [Natural Language Processing](https://en.wikipedia.org/wiki/Natural_language_processing) (the process of  taking input provided by users and extract meaning/context out of it). To solve this problem we’ve used [Dialogflow](https://dialogflow.com), which is simple but advance tool that allows to understand human conversation. As a web framework we've used [pointfreeco/swift-web](https://github.com/pointfreeco/swift-web). It’s nice swift-lang web framework using functional approach.

We’ve defined 5 general categories of absence:
* illness: you’re sick and you don’t plan to work at all, you’re are unavailable 
* holiday: you’re enjoying your free time, you’re are unavailable
* school: you’re generally unavailable, excluding small spots between lectures
* conference: you’re availability is limited, excluding small spots between lectures
* remote: you’re on duty, but just out of the office

## In action 

To add an absence simply start a conversation with @AbsenceBot on Slack. All the chatbot is doing, is extracting out of the context two information: **reason** and **period** of yours absence. If some pieces of information are missing, it will provide a specific question that helps him get that information. 

Just start typing and answer the question, or tell what you need, like in a normal human conversation e.g.:

* I’m not feeling good and will take off till the end of the week,
* I’m going on conference between 3-5 May

<img src=".images/screen1.png" height="400" alt="Screenshot"/>

Your request when ready (and after your verification) is posted on a dedicated private channel where all supervisors and PMs has access to and can discuss in small group about employee absence using Slack threads. Those requests can be approved or rejected by tapping on an interactive buttons. Whenever accepted or rejected, employee is informed about the status in feedback message.

<img src=".images/screen2.png" height="400" alt="Screenshot"/>

Accepted requests are added to Google Calendar with a proper title (showing name of requester and reason of absence), proper period and participants (absence requester and absence approver). Moreover, everyone in the company has read-only access to this calendar so everybody can see others absences in advance.

<img src=".images/screen4.png" height="400" alt="Screenshot"/>

## Tools 

### Dialogflow

Dialogflow is human–computer interaction technologies based on natural language conversations.
You can find exported model in this repo [here](./Dialogflow.zip)

### Slack

Right now I'm just supporting Slack as Dialogflow's channel of communication. But this is easy to extend for other like WhatApp or Messenger.

### Google Calendar

If event is approved, the app is adding an event into Google Calendar.

## ToDo

* improve README and describe how setup all needed services and tools
* run tests on Travis/CircleCI

## About

This project is made with ❤️ by [AppUnite](https://appunite.com) and maintained by [Emil](http://github.com/emilwojtaszek/).

### License

This project is licensed under the Apache License. See [LICENSE](LICENSE) for more info.
