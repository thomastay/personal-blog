---
title: "How I Made Wordle Helper"
date: 2022-02-22T18:16:00-08:00
draft: true
---

I recently made a web app that helps you play Wordle, everyone's favorite word game. In case you haven't heard of it, Wordle is a game where you try and guess a 5 letter word in 6 tries (just Google it!)

If you want to check out my Wordle Helper, [click here to go to my website and try it out](https://ttay.me/wordle-helper).

TODO: screenshot here!

I thought it might be worth sharing the engineering of how I designed, wrote and published this site. Plenty of people have written 
[much](https://github.com/jason-chao/wordle-solver)
[better](https://www.kerrigan.dev/2022/01/10/building-a-wordle-solver-in-python.html)
[wordle](https://github.com/theboywhoboasted/whurdle)
[solvers](https://github.com/christiangenco/wordlesolver)
than mine, using
[cooler techniques like information theory](https://www.youtube.com/watch?v=v68zYyaEmEA), unlike my very naive heuristic.

So why is mine special? Well, I designed Wordle Helper with these goals: 
1. Runs everything locally, no need for a backend server.
1. Response time under 10ms, the threshold for instantanous 
1. Suggest words that a human would guess, not necessarily one that is mathematically optimal
1. Fast build times as a developer

I'm going to focus this article on how I managed to achieve those goals.

# 1. Starting out

I got the Wordle word list from the website itself. Wordle has an internal word list of 2047 words which it just rotates through daily - that's what the 248 in `Wordle 248` represents.

You can easily find the word list by going on the Wordle web site, going to the main.js file in the Sources tab, then click on pretty print. Once the js is pretty printed, just search for a Wordle word like "cloak" or "cigar", and the word list pops up pretty quickly. In the second picture below, it's assigned to the variable `Ma`.

![Click on pretty print](/blog/img/wordle-pretty-print-1.jpg)

![word list](/blog/img/wordle-wordlist.jpg)

Once I got this copied into a text file, I immediately sorted it to avoid spoilers. The answers appear one after the other, so if you see the word in position 249, that's the answer for day 249.

I started out by writing the HTML and Javascript inline directly, copying my other website [x86 flags](/x86flags.html). It looked something like this:

```html
<!doctype html> <html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
<meta name="description" content="Your description here">
<meta name="author" content="Thomas Tay Ang Chun">
<script type="text/javascript">
  'use strict';
  function update() {
    // more here ...
  }
</script>
<body>
  <h1>Enter your guesses here</h1>
  <input id="input1" oninput="update()"></input>
  <!-- more here... -->
</body>
```

*Moral #1*: If you're overwhelmed by the JS build ecosystem, you can just start by writing inline JS in a HTML file. Don't let people shame you for it. I did it for [X86 flags](/x86flags.html) and it worked out fine.

However after about a day of writing code, the JS part of my file was growing larger and larger, so it was time to set up a build system.

# 2. My franken-build system

> Demo build systems are all alike; every real build system is convoluted in its own way - **Tolstoy**

At this stage, the usual technique is to split up your file into an index.html, and an index.js. The index.html imports index.js like so:
`<script src="./index.js">`
and that lets you write your HTML and JS separately.

To be honest, I should have just done that, which would shorted this section of the blog post, but I chose to inline the JS into the HTML file instead.

I knew that when I shipped the end product, I'd want to inline the JS into the HTML, for 2 reasons:
1. Turns 2 network requests into one, which reduces the failure rate. For some reason, devs tend to assume that script loads never fail, which isn't true. In my day job, I work on [a web app](https://www.microsoft.com/en-us/microsoft-teams/group-chat-software) which has a scale large enough that we have to be concerned about this.
1. Improves efficiency of the gzip compressor, and thus smaller bundle sizes. From [my investigations into the DEFLATE spec](/blog/gzip_investigations/), I knew that gzip builds a dynamic huffman table for each block (about 16k symbols). Since I guessed that my entire HTML + JS file would fit in one block, this would decrease the overhead of compression since I'd only need to store one dynamic huffman table instead of two.

Of course, there are downsides to this approach, which you should be aware of:
1. If your JS comes before your HTML, and your JS is big, it will block the page load. Usual solution to this is to put your JS after your HTML, but then:
1. (cont) If your HTML comes before your JS, and your HTML is big, it will prevent the browser from compiling your JS code in parallel, which it can actually do.
1. Increases complexity because now you have to inline the JS into the HTML somehow. Pretty much every bundler (Webpack, Snowpack, Vite) out there supports separate HTML and JS files as a default use case.

Without measuring, I'd say that if your HTML is more than 16kb, or if your Javascript files need to be split into multiple bundles, then it makes sense to split the HTML and JS files up for production.

Note that this has nothing to do with how you *develop* your applications, in which you should absolutely split your HTML and JS files apart.

At any rate, I made my life harder for your benefit. *you're welcome* 😅


## Correctness

example:

Suppose the user got a result like this:

KROO,K,

this says that there is no K in the first position and last position. Furthermore, it says that there is exactly 1 K and exactly 1 O.
function to filter 

For instance, here's some words that a naive algorithm might accept:
- CLOAK (wrong, since there one K, but it's in the position marked wrong)
- KIOSK (wrong, since there are 2 Ks, and one O is on the position marked as not contained)
- KOALA (wrong, since there one K, but it's in the position marked as not contained)

The filtering algorithm provided in kerrigan.dev accepts the last suggestion KOALA listed above, which is incorrect.
