---
title: How Zoekt works
date: 2025-01-01T12:42:06+08:00
draft: true
---

Zoekt is a full text search engine that lets you run arbitrary substring or regular expression searches on a large set of files. I think the technology is highly underrated, and I spent some time spelunking in the Zoekt codebase, so here's how it works.
*Note: I'm not a Zoekt core contributor, just someone who uses Zoekt. Zoekt is written by Han-Wen Nienhuys and maintained by Sourcegraph.*

## What is Zoekt?

Zoekt was built to be a code search engine. Given a codebase, it builds a search index that helps it answer regex queries quickly.
The technology it's built on is called Trigram search. There is an excellent article from [Russ Cox which explains it](https://swtch.com/~rsc/regexp/regexp4.html), but I will give a quick demonstration of how Zoekt does it below.

Suppose we have a file to index, which contains the string "hello, world!". We would break this into trigrams, including the space. Note that Zoekt doesn't delineate word boundaries at index time, leaving it to the Regex engine at match time.
```
"hel", "ell", "llo", "lo,", 
"o, ", ", w", " wo", "wor", 
"orl", "rld", "ld!"
```

Then, unlike Cox's technique, Zoekt also stores the index of that trigram in the document, so we'd have a map from trigram to index. Zoekt stores this in sorted order as B+ trees.

```json
{ "hel": 0, "ell": 1, /* ... */, "ld!": 10 }
```

Now suppose we have a query string "world". We break up the query string into trigrams itself, "wor", "orl", "rld". Unlike Cox's method, we only need to check the index for the two trigrams at the beginning and the end, namely "wor" and "rld", and check that their positions are 2 apart. In this case, they are two positions apart (7 and 9), so we consider this document to be *matched*.

Note that being *matched* doesn't mean that the substring is confirmed to be present, only that it is likely that the document contains the substring match. We **could** check all trigrams in the query and confirm that they are at the correct offset, but checking fewer trigrams means that we rely on the index less, and that allows Zoekt to hold less of the index in RAM. After confirming a match, the document has to be parsed anyway to retrieve the match line and any surrounding lines, so we might as well increase the false positive rate in order to reduce the index usage.

Now that the document has been matched, we then retrieve the document, and check that it matches the entire substring between index 7-12. This check is very quick, because we already know the start and end index in the document, so it's just a matter of checking that we have a full substring match.

Now let's search for the string "lo,qwor", to showcase a false positive. This generates trigrams "lo," and "wor" at the beginning and end of the query. We check the index and they are correctly 4 positions apart. So we go and check the document, but sadly the substring is not a full match.

If the query contains a regular expression, for instance say the query is `"hello.*world"`, then we can still apply the trigram trick for the beginning and end index to check if the document has both the start and end index, but now we can't use the positions to verify a match, since `.*` can match an arbitrary number of characters. So Zoekt will look at all possible matches in the document, check that they are on the same line, and run the Regex engine on them. This is similar to what is described in Cox's article.

There are also a lot of special cases, which you can find in `matchtree.go`. One interesting one is that the query `\bworld\b` completely skips the index, unlike what you might expect, instead just running directly as a substring search on the document itself. I would have thought that using the index would help speed up searches, but from the [commit that introduced it](https://github.com/sourcegraph/zoekt/commit/ea5ebffdc0f22392cf9b61900f0ffbc759a982b5), it seems that going without it sped up searches by 4-5x.


## References
1. https://github.com/sourcegraph/zoekt/blob/main/doc/design.md
2. https://swtch.com/~rsc/regexp/regexp4.html
3. https://blog.nelhage.com/2015/02/regular-expression-search-with-suffix-arrays/
4. https://zeux.io/2019/04/20/qgrep-internals/