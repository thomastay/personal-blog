---
title: "Causal Messaging by example"
date: 2020-07-17T12:00:00+08:00
draft: false
---

When people first build a distributed system, they normally think of FIFO messaging, or maybe they build their system to be linearizable. But there's an in-betweener, and that's causal messaging.

Instead of giving you the definition, which is pretty mathematical, I'll let you read it on your own, and I'll give a real life example that you can hopefully grok. 

Causal messaging is pretty important for some types of distributed systems. It's used in implementing reference counting in the Pony runtime, for implementing sane Logging systems, and generally just making sure that your system makes sense, without full linearizability. You probably already use a Causal messaging system without knowing it --- synchronous gRPC calls basically almost guarantees causal messaging.

But one place that causal messaging doesn't show up is in vanilla TCP connections. TCP only guarantees FIFO ordering of messages, without any causal ordering of messages between systems.

So, let's take a look at what I mean:

# Scenario

Let's imagine a fictional chat room. There are 3 people, Alice, Thomas, and you. In this chat room, people just broadcast messages to everyone else without a central server. Horrible, I know, but effective.

```
     Alice
   /       \
  /         \
 You ----- Thomas
```

Let's say that Alice greets Thomas. After that, she asks him how his day was, and Thomas replies.  
For Alice, these are the 3 messages she sees on her computer:
  1. Alice: Hello, Thomas!
  1. Alice: How was your day?
  1. Thomas: Pretty alright, work was busy.

Let's call these message 1, 2, and 3 respectively. To avoid confusion, I'm going to use bullet points later on.

#### So what do you, the silent observer, see? 

Well, there are 3 possibilities:

### Causal messaging

Scenario 1: (*I'll have the usual, Joe*)

- Alice: Hello, Thomas!
- Alice: How was your day?
- Thomas: Pretty alright, work was busy.

Scenario 2: (*kinda weird but alright*)

- Alice: Hello, Thomas!
- Thomas: Pretty alright, work was busy.
- Alice: How was your day?

### No Causal messaging, but FIFO ordered

Scenario 3: (*ok......?*)

- Thomas: Pretty alright, work was busy.
- Alice: Hello, Thomas!
- Alice: How was your day?

## Huh? That's not what I expected?

Scenario 3 can't occur under causal messaging because Alice's first message is sent after her second. Since Thomas sends message 3 only after seeing the second message, there's a dependency between message 1 and message 3. That means that message 1 will be delivered before 3.

Most people (including me, when I first thought about this) are surprised that scenario 2 can occur under causal messaging. The reason is as follows:

- Message 1 must come before 2, since Alice sends 1 before 2, and messages are sent out in FIFO order.
- Message 1 must precede 3, since the message 2 causes message 3 to be sent. Since message 1 is sent before message 2, this means that message 1 precedes 3.
- However, message 3 can arrive at your doorstep earlier than 2! Think of it this way: Let's say that Alice broadcasts out message 2 to both Thomas and you. In the time it takes for 2 to reach you, Thomas has received message 2, and send out message 3, which reaches you first. This isn't a violation of causal ordering, since Alice's broadcast of message 2 occurs concurrently. 

## What if I don't like things out of order?
Note that if you only want scenario 1 to be the only scenario that happens, what you desire is **serializability** and not causal messaging. 

To do that, you basically have to have one actor process each message, effectively turning your server into single-threaded mode. While this is often required for chat servers, it's often unnecessary for other types of work.

