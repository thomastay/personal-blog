---
title: "100% Reliable and Fast"
date: 2022-01-30T19:31:48+08:00
draft: true
---

I work on a front end project which has two Git repositories, three completely different build systems, five languages, over 10,000 files and 10 million lines of code. It's been built over six years, with the effort over at least a thousand engineers. At this scale, IDE's just can't work effectively. 

For instance, Jump to Definition (F12 in vscode) mostly works, except when navigating to a concrete implementation of an interface injected ten files away. Hover-over type declarations mostly works, except when the Typescript server can't resolve a particular namespace because some legacy code fiddled with webpack magic. Automatic renaming within files mostly works, except when someone used the same variable name in a deeply nested closure and Typescript can't infer that because there isn't enough type information to go on. And let's not even talk about renaming across files. You'd be better off winning the powerball [1].

In this codebase, there's no substitute for grep. Specifically, there's no substitute for ripgrep, which is the only popular tool i know which can effectively search a codebase of this size. [1] Many of the senior engineers working on this codebase agree. Thank goodness vscode uses ripgrep as the default.

Same story when debugging production code. Source maps work, except when you're dealing with the oldest cruft of the code which is built on the Grunt build system instead of industry standard Webpack. Or when you're running your app on your battery powered laptop in the cafeteria, not your powerful dev box. Or when the issue only repros when startup happens too fast and you can't wait for the source maps to load.

In the end, I followed the senior engineers and now I count myself as being proficient at: (A) reading prettified mangled Javascript and (B) reading mangled Typescript ES5 output for async functions. For those unwaware, async functions in ES5 compile down to switch cases, where 2 means "Continue", 3 means "Return" and 5-7 indicate error codes. You just have to memorize that, or pay the price of looking that up when you're debugging seven layers deep.

## Software should have a lite mode

In both these cases, we were saved by the presence of a solution which was 100% effective and fast. That's ripgrep for code search and setting up breakpoints in minified code. Both solutions have a better, more correct alternative, namely IDEs and source maps respectively. Yet in practice, I can assure you that we have to fallback to the simpler methods at least once daily. 

TODO
1. Gmail html only site
1. Github vs Git vs Git plumbing tools (can always fall back to Git intenrals)
1. ??
1. Erlang crash handler
1. C macros
1. Golang compiler vs webpack



# Footnotes
1. aka the lotto (UK), or 4D (Singapore).
1. I personally have moved off ripgrep, and I use [qgrep](https://github.com/zeux/qgrep), which keeps a compressed index of all the files in work repos. It requires some setup and you have to update the index every time you switch branches, but it is 10x faster than ripgrep. And milliseconds add up.
1. 

