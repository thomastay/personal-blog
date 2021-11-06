---
title: "I made x86 flags"
date: 2021-11-06T12:16:51-07:00
draft: false
---

This is going to be a tiny blog post to say that I've made a tiny site (microsite?) that's all about x86 flags. I'm learning about x86 assembly, SIMD, and microarch these few weeks. 

The eflags register is really confusing, so i made a tiny simulator to help me remember which flag is which. Particularly the carry and overflow flags, cos f**k whoever thought that was a good way to name their flags.

You can find the site here: [x86 flags](https://ttay.me/x86flags.html)

Just FYI, here are some sites that I find useful when learning x86:
1. [Agner fog](https://agner.org/optimize/)
1. [x86 stack overflow](https://stackoverflow.com/questions/tagged/x86?tab=Votes). Look for Peter Cordes.
1. [Bit twiddling hacks](https://graphics.stanford.edu/~seander/bithacks.html)
1. [Anything by Wojciech Muła](http://0x80.pl/articles/simd-byte-lookup.html) That guy is a god.
1. [simd json internals by Geoff Langdale](https://branchfree.org/2019/02/25/paper-parsing-gigabytes-of-json-per-second/)
1. [The picohttp parser SIMD algorithm](https://github.com/h2o/picohttpparser/blob/066d2b1e9ab820703db0837a7255d92d30f0c9f5/picohttpparser.c#L108)

