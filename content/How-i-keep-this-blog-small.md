---
title: "How this blog is made"
date: 2022-01-05T01:04:48-08:00
draft: true
---

TODO: this intro sounds bad

I started this blog last year, and though I've written a few pieces, I've ensured that they all score a 100% on Lighthouse.

While there isn't any particularly fancy trick I use to make the page small (I literally just don't do a lot of stuff), I figure it is at least worth writing down. At the very least, it'll help me restart everything from scratch if need be.

# Build system
First and foremost in every blog is the build system (aka CMS, aka static site generator). For some, their CMS is HTML and CSS. I don't know about you, but I don't enjoy writing HTML tags so I use [Hugo](https://gohugo.io). It lets me write markdown which is more or less like plain text.

That's basically all I use Hugo for, I don't use any of its fancy features. The main reason why I use Hugo and not some other CMS is because it's fast and it supports Windows out of the box.

Here's the hugo version used to generate this blog post. It'll probably change by the time you read it, I try to keep abreast with Hugo updates.

```
~\D\blog> hugo version
hugo v0.91.2-1798BD3F windows/amd64 BuildDate=2021-12-23T15:33:34Z VendorInfo=gohugoio
```

To keep up with software updates, I use Scoop as my package manager to manage my Hugo builds. Although Hugo subscribes to the 0-ver scheme, it is remarkably stable and I think upgrading only broke my builds once, very early on.

# Editor

I use [Neovim](https://neovim.io/) to write blog posts. As I mentioned, I really just want to write into a txt file, but markdown lets me have titles, links and code snippets, so I use markdown but basically treat it as plain text. 

I make quite extensive use of Neovim, and I'll address it in another post, but suffice to say that [Neovim has improved](https://neovim.io/charter/) [leaps and bounds](https://benfrain.com/neovim-0-5-lua-built-in-lsp-treesitter-and-the-best-plugins-for-2021/) from just a [fork of Vim](https://toroid.org/modern-neovim).


# Theme

## Where it comes from

Credits first: I owe my theme entirely to [Joway Wang](https://github.com/joway/hugo-theme-yinyang). His theme was exactly what I was looking for when I was looking for a blog theme, and though I run a custom fork of his theme, you should use his if you want a blog theme.

There are so many features of Joway's theme that make this blog look polished that I can't list them all, but here are some nice ones:

1. Hovering over a link makes the font bigger
1. Clicking on "Thomas' Weblog" takes you back to the blog main page
1. SEO optimization

When I was shopping for a theme, I specifically looked for themes that would look like the [Light Theme of Fabien Sanglard](https://fabiensanglard.net/doom_fire_psx/index.html). I really like his blog theme and wanted to copy it, minus the monospaced text (makes text hard to read).

That said, I did make some tweaks:
1. Changed the font-family to only use system fonts and removed dependency on Google fonts - speeds up page load
1. Removed the ability to switch between languages (I only write in English)
1. Removed dependence on highlight.js - An explicit goal of this blog was to have absolutely 0 bytes of Javascript unless the blog post requires some animations.
1. Broke up the CSS bundle into three bundles (explained more in the Performance section)

## Where it will go

The only downside of my current setup is that it doesn't support Dark mode as of yet. Perhaps Joway has fixed that, but I haven't really kept up to date with his changes.

Another thing that would probably be nice is something like what [Nayuki does when you click on a section header](https://www.nayuki.io/page/about#contact), which is to highlight the section using the (unknown to me!) CSS target selection feature.

Something which I won't implement, but is quite the visual delight, is Amos' "Cool bear's hot tip" (fasterthanli.me). [Check out his blog post on Rust build profiling](https://fasterthanli.me/articles/why-is-my-rust-build-so-slow) to see what it looks like.


# Performance

