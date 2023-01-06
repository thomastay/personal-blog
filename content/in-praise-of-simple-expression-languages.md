---
title: "In Praise of Simple Expression Languages"
date: 2023-01-05T22:14:33-08:00
draft: true
---

I've gotten interested in small, scripting languages. Not the big hulking behemoths like Javascript with its hyperoptimizing JIT compiler V8, or Common Lisp with its full spec and insane compiler SBCL. Not even tiny, zippy languages like Lua, its interpreter squeezing into barely a hundred kilobytes (though I like Lua very much). I'm talking about one liner languages, the ones that fit into your JSON file and which are just a piece of a much larger puzzle.

I'll talk a bit about scripting languages, then move on to expression languages. Then I'll talk about a simple expression language interpreter I wrote, and some design notes.

## Overview of scripting languages

Most scripting languages, even the nightmare that is ES2020, began as a simple project to breathe life into an otherwise static world. Brendan Eich famously wrote the Javascript interpreter in 10 days, you know. It couldn't have been *that* complicated (and wasn't!)

If you work primarily in dynamic language land, as your author sadly does, you may not realize that every major static language has some sort of *de-facto* tiny scripting language, usually developed to script build systems but usually ending up inside the app itself. In C++, Lua is one of the dominant tiny scripting languages, being used to configure everything from [plain ol config files](https://www.lua.org/pil/25.html), to [build systems](https://xmake.io) to **entire video games themselves**[1]. Isn't that just absolutely insane! And of course there are other ones like CMake, [which is a language](https://cmake.org/cmake/help/latest/command/cmake_language.html), btw.

*Note:* Python is arguably more of a *defacto* build language for C++, but there's a fundamental difference between Python and Lua. Python is meant to run your C++ code, and Lua is meant **to be run** by your C++ code. There's a difference there.

In Java, people have to learn the [Gradle programming language](https://docs.gradle.org/current/dsl/index.html) if they want to use the Gradle build system[2]. Inside your Java app you can use [Groovy](https://www.baeldung.com/groovy-java-applications), which the Gradle DSL is actually based on! Or if you're a Lisper you can use [Clojure](https://clojure.org/).

In Go, you can use established languages like Lua too, or homegrown ones like [Tengo](https://github.com/d5/tengo) or [Expr](https://github.com/antonmedv/expr), but curiously enough Go is the first compiled language where I see people using it as a build system language. I first saw it in [SumatraPDF's homegrown build system](https://github.com/sumatrapdfreader/sumatrapdf/tree/master/do), and was so intrigued [I adapted it for my own projects to try it out](https://github.com/thomastay/wordle-helper/blob/master/cmd/build/main.go). It's pretty nice, thanks to the fast compile times.

In Rust I see people use Lua a lot too, but [Mun](https://mun-lang.org/) is also an up and coming DSL that's meant to be embedded into your Rust program. In fact, from their homepage:

> The idea to create Mun originated out of frustration with the Lua dynamic scripting language that is extensively used for game development at Abbey Games.

And the list goes on and on.

Throughout the examples, though, I hope you're starting to see a pattern. A lot of these languages that I'm talking about started out as configuration file languages. Configuration files are typically loaded while the app is running, so the language has to be fully available to the main app at runtime. This means that these languages have to be **libraries**, not standalone languages.

Most of these languages started out simple and grew larger from there. Over this Christmas break, I was interested to learn about making one of my own, and I started with the simplest type of language, the *expression language*.

## Expression languages

An expression language is nothing more than a one-liner language that lets you evaluate arithmetic operations, comparisons, read variables, call functions, etc. It looks something like this:

```javascript
rand() > 0.5 and finiteHealth ? 10 * HP : HP - 10
```

This sort of language is a miniscule subset of all the languages I've talked about above[3]. But crucially, expression languages don't have any ways to set variables. That also means no declaring functions, nor anything user defined at all. Everything is an expression.

TODO

# Footnotes
1. https://en.wikipedia.org/wiki/Category:Lua_(programming_language)-scripted_video_games
1. If you're not a build-system-DSL-fan, [Maven](https://maven.apache.org/configure.html) thankfully just uses XML files.
1. Except one. Can you figure out which one?
