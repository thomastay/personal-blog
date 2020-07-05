---
title: "Looking at language websites"
date: 2020-06-29T17:46:28+08:00
draft: true
---
Reviving this old issue as I've been thinking about this too. I also disagree that code samples are that important, especially since syntax isn't Pony's strength. 

k think it's most insightful to take a leaf from other languages' websites. Below, I will analyze some of the top rising languages in 2020:

## Rust
https://www.rust-lang.org/ 

- Has a splash logo, the language name in HUGE FONT, a tagline "A language empowering everyone
to build reliable and efficient software.", and a "Get Started" button. All things which are immediate in drawing attention. Importantly, users **self-classify** : those who want to use Rust will get started, users who aren't conviced will read on.
- On that note, the Get Started page takes them immediately to the install page. There is no choice in this matter, which is good in guiding users. Remember: this target audience is users who already want to use the language.
- For users who aren't convinced, scrolling down the homepage brings you to "Why Rust?", with three taglines: 

1. Performance - Rust is blazingly fast and memory-efficient: with no runtime or garbage collector, it can power performance-critical services, run on embedded devices, and easily integrate with other languages.
1. Reliability - Rust’s rich type system and ownership model guarantee memory-safety and thread-safety — enabling you to eliminate many classes of bugs at compile-time.
1. Productivity - Rust has great documentation, a friendly compiler with useful error messages, and top-notch tooling — an integrated package manager and build tool, smart multi-editor support with auto-completion and type inspections, an auto-formatter, and more.

- The Homepage then follows with 4 classes of apps that can be built in Rust, along with 4 links for the unconvinced user to **self-classify** themselves, and read the guide *that is tailored* for that particular group. When you click on 1 of the 4 links, **now** only do you see the code samples. 
- You see a Testimonials section, where there are big splash quotes from prominent users who've used Rust.
- Then, a "Get Involved" section. Personally, I think that section is unhelpful for new users and is mainly for existing users who want to deepen their knowledge.
- Laslty, a "Thanks" section, linking to their backer page.

### Comments
Notice that there are no code samples. There is just one line about the borrow checker. Nothing about syntax. Nothing about error handling. It's all about what Rust provides: a No GC language that happens to have a great type system. And more importantly, it's about the problem domains that Rust solves. They really neatly categorised them, which is nice as a developer.

## Typescript
https://www.typescriptlang.org/
- The page opens with a huge splash image of Seattle. This is odd for many reasons, but it is beautiful. 
- The word "Typescript" is in huge font, along with the tagline: *JavaScript that scales.*
- Then, a brief explanation: *TypeScript is a typed superset of JavaScript that compiles to plain JavaScript. Any browser. Any host. Any OS. Open source.*
- Following are two links, "Download" and "Documentation". Once again, this is to **self classify** users. Those who are convinced click on "Download", those who want to learn click "Documentation", those who are unconvinced read on.
- Scrolling down, we have a Carousel of Twitter testimonials on how Typescript helped them. This helps to inspire unconvinced users.
- Then, we have the "What is Typescript good for" part. They focus on three areas:
1.  Starts and ends with JavaScript 
1.  Strong tools for large apps 
1.  State of the art JavaScript 
- Obviously, you can tell from just the headlines that they are targeting enterprise Javascript developers. Indeed, that is exactly their target audience. 
- For those who are *now* convinced, they have a "Learn it fast" button, **which links to the same Documentation page above**
- For those who are *now* convinced and wanna get the shiny toy, they provide immediately CLI instructions for downloading, as well as Editor support.
- Below, we see a *See ts in action* section, with a video of Anders presenting on Typescript.
- Then, they highlight Typescript is Open source, because every language in 2020 has to be. (and because Microsoft knows of its reputation)
- Then, another carousell showing off more testimonials from Enterprises (the one above was from users)
- Lastly, a "Get involved" section and another "Learn" section.

### Comments
The Typescript page is less convincing for me than the Rust page, but I think Typescript is targeting a different group. Namely, engineering managers / architects who already know JS intimately, and are looking to upgrade their front end apps. To those people, they probably know why types are important, Typescript just has to convince them that it is stable enough to be adopted in their organization. 

Again, there are no code samples. It's all about how stable Typescript is and how clean it is. I really doubt many will watch the video, but having a video there shows commitment! It shows that people like this language enough, that they made a whole video on this. (For those unaware, MS Build is a huge Microsoft conference, and to be featured there is a big deal; F# wasn't even featured in this year's MS Build and it's an older language than TS)

## Go

I don't want to make it sound like I'm bashing code samples, so it's just nice that the next language I picked, Go, has a lot of code samples on their website:
https://golang.org/ 

- The page opens with a big tagline, *Go is an open source programming language that makes it easy to build simple, reliable, and efficient software.* 
- The Go Gopher is prominently featured, alongisde a large button that says "Download Go". Obviously, this is for users who are already convinced.
- On the right, we see a lot of code samples! We see Hello world, Game of Life, Peano Integers, Fibonacci, Concurrent Pi, Concurrent prime sieve, Trees. More importantly, these examples each show off a **specific** aspect of the Go language. (see the page for more details, there's too much to summarize here)
- If you liked the code samples, there is a link that will take you to the Go Tour. But this button is tiny and hidden, and so might be lost on a first look.
- we see featured articles on the bottom left, and featured videos on the bottom right.
- That's it! 


### Comments
The Go website is minimalist, reflecting the developers' philosophy. Indeed, the Go language, Go tutorial all follow this design scheme of minimalism. For instance, the Go playground doesn't even have syntax highlighting. 

More interestingly is the abundance of code samples. My guess is that Go can focus on this, since its syntax is so similar to C like languages that anyone with a programming background can understand most of it. 

Very little is said about Go's strengths, namely its easy concurrency handling, its huge standard library, and its minimalist syntax. 

Overall, a nice contrast from the marketing-heavy websites above.

*snark*: It's kinda funny that Rust and Go both use basically the same tagline...

## Dart
https://dart.dev/

- Wow! The webpage opens with a fluid animation of a swivelling phone, and the splash intro appears *Paint your UI to life*, *with Dart VM's hot reload*
- Scrolling down, we see the tagline: *Dart is a client-optimized language for fast apps on any platform*
- We also get to watch a video, but it is a link, not an embedded player.
- A big "Made by Google" sign right there.
- Then, a list of features, much like Rust/TS, along with a quick description
1. Optimized for UI
1. Productive development 
1. Fast on all platforms

- Then, the website explains each of the features in depth. It has UI cards for all three features, each card having 2-3 bullet points explaining the feature. If you mouseover each bullet point, different code samples appear next to it.
- A note: the languages Dart compares itself to are TS, Kotlin, and Swift, reflecting Dart's focus on mobile dev.
- Then, we see a "Try Dart in your browser"
- Afterwards, there is a very tiny URL link (not even a button!), encouraging you to download Dart.

### Comments
The animation is super smooth, they really hired good designers for this. IMHO, I think this website is designed to convince people to use Dart. The target audience is mobile app developers who have never heard of Dart, who probably won't use Dart right now, but might in the future. That's why there is very little focus on getting Dart installed on their computers. 

The focus is on convincing you, the reader, that Dart is a good language that you might consider for your next hobby project, and hopefully later on, your next company project. 

This reflects Dart's position - It's definitely not as big as Kotlin / Swift / Typescript for mobile app dev (TS thanks to React Native). So, it has to compete by focusing on impressing new devs, even those who probably won't download your language.

## Kotlin

  - Starts out with a tagline "A modern programming language
  that makes developers happier.". 
  - Has two big "Get Started" and "Try Online" buttons next to the tagline
    - Get Started takes you to the docs reference page
    - Try Online catapults you down the page, to the "Try Online" section
  - Immediately goes on to tell you what it's good for. Each of these links takes you to a customized page written for that discipline. 
    - Mobile cross platform
    - Server side
    - Native
    - Web Development
    - Data Science
    - Android
  - Then, a bunch of news from the Kotlin page, stating the latest releases
  - Finally, a Try Kotlin section, showing off these features
    - Hello World
    - OO Hello world
    - Coroutines
  - There is a "More Examples" section that takes you to a specific page where there are plenty of code samples

### Comments
This page doesn't tell me much. That's fine, since I think the point of this page is for users to self-classify and select which group they most identify with. 

Going into each of the sections, I see that the Kotlin team spent quite a bit of effort in explaining the 6 markets they try to target. Perhaps since Kotlin is a more mature language, they have their target audience clearly laid out, and would rather focus on each segment individually. 



