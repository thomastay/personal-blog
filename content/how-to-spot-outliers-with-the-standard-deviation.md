---
title: "How to Spot Outliers With the Standard Deviation"
date: 2023-11-15T23:34:57-08:00
draft: true
---

Take a look at this time series chart. Knowing absolutely nothing about the chart or what it means, can you spot the outlier?

Not so easy, is it? Now, what if I add this overlay on top of it?

Now it's much easier, right? In this post, we'll talk about how to generate the second sort of graph, and how we use it to visually spot problems in our backend services.

## The problem
One of my duties as a Software Engineer on a chat app is to monitor the flow of messages and make sure there are no interruptions. To do that, we keep track of the number of missing messages between the client and the server, which come over a good old fashioned Websocket connection. The details about how we do that aren't important, but suffice to say that this data is reported from the app itself, and is sent to us via telemetry.

Some number of dropped messages are expected. Networks drop packets all the time, and clients go in/out of network connectivity, etc. What's not expected is if:

a) Lots of clients suddenly start reporting missing messages at the same time, for **different chats**

b) Lots of clients report missing messages **for the same chat**

These two situations signify something going wrong with our backend services. Crucially, they represent a different sort of error!

Situation A is usually an issue at the Websocket / networking layer, since it's happening all across the board.
Situation B implies that there is something going wrong with that chat specifically, and we might need to look at the backend telemetry.

In the past, our monitoring didn't distinguish between situations A and B, making it harder for us to see at a glance what is going on. Put yourself in my shoes for a moment: you're being paged at two in the morning and your brain is just mush. What you want is a really nice-to-spot graph that tells you what's going on immediately. *Like Graph 2 above!*

Let's look at some sample data. 
