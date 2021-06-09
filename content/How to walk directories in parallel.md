---
title: "How to Walk Directories in Parallel using Ignore"
date: 2021-06-06T19:03:59-07:00
draft: true
---

*Alternate title*: How I made [dust (the CLI tool like du)](https://github.com/bootandy/dust) twice as fast.

> Silence is golden (ooh)
>
> But my eyes still see
>
> Silence is golden (ooh)
>
> But my eyes still see
>
> \- Silence is Golden (1967)

In this post, we're going to talk about how to use *ignore* effectively ([the awesome crate that burntsushi wrote](https://crates.io/crates/ignore)). I'm not going to have time to get into the details of how to write *ignore*'s directory walker yourself, though I plan to cover that in the follow up post to this.

### From the ignore main page
> The ignore crate provides a fast recursive directory iterator that respects various filters such as globs, file types and .gitignore files. 

I'm going to assume you know Rust, and that you've at least glanced at [ignore's well-written documentation](https://docs.rs/ignore/0.4.17/ignore/index.html). Hopefully, you're like me a few days back, thinking about how best to use the parallel walker API. If so, let's get started!

We'll start this post by implementing a toy example using the Parallel walker API, first using a typical implementation, then refining that implementation to reduce contention.

## Getting started

Let's say we want to print all the files in the current directory which have the word "rust" in them, excluding the files ignored by .gitignore. And let's say they have to be sorted, too, for good measure.

Pulling up *ignore*'s documentation, you'd get something like this:

```rust
use ignore::Walk;
let walker = Walk::new("./");
let mut entries: Vec<String> = walker
    .into_iter()
    .filter_map(|res| {
        res.ok().and_then(|entry| {
            entry.path().to_str().and_then(|path| {
                if path.contains("rust") {
                    Some(path.to_string())
                } else {
                    None
                }
            })
        })
    })
    .collect();
entries.sort_unstable();
for e in entries {
    println!("{}", e);
}
```

Looks alright, and we can customize it by using the WalkBuilder if we wish. But humor me, and let's suppose we think that the "contains" operation is too slow. We then could parallelize it using the WalkParallel iterator.

But since WalkParallel no longer can be converted `into_iter()`, sadly, we have to rethink our approach. WalkParallel provides a convenient `run` method, which takes a closure, that seems like a good step. Here's a first try:

```rs
WalkBuilder::new("./").build_parallel().run(|| {
    Box::new(|res| {
        if let Ok(entry) = res {
            if let Some(s) = entry.path().to_str() {
                if s.contains("rust") {
                    println!("{}", s);
                }
            }
        }
        WalkState::Continue
    })
});
```

The run method has kinda a wonky API, even [burntsushi himself has admitted that](https://github.com/BurntSushi/ripgrep/issues/469#issuecomment-298324153). The run method takes a closure, that then returns a closure, that will be run every time the Parallel iterator encounters a DirEntry.

Hmm. Kinda tricky. I had to mull it over in my head a long time before I really got it, and now that I have, I still think it's kinda overkill for the thing that it's doing. Plus, it doesn't play nicely with Rust-analyzer:

![Image of rust analyzer type signature being confused](/blog/img/ignore_closure_confusing_rust_analyzer.jpg)

Basically, the first closure runs the very first time that 


