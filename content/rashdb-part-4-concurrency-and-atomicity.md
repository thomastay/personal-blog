---
title: "Rashdb Part 4: Concurrency and Atomicity"
date: 2023-10-29T17:55:00-07:00
draft: true
---

We're going to apply several tricks in this part.
1. Instead of overwriting a page, we'll write a new one and make its parent point to it.
1. We do the same thing for the schema page. Instead of overwriting the table schema page, we will write a new one to disk and get its parent to point to it.

Huh? But currently we have it setup such that the schema page is always at page 1. If we update it, how will we know where the schema page is?

Well, as with everything in computer science, we'll apply another layer of indirection to make it work. We'll have a central "Meta" page that points to the schema page, and we'll read/write to that page in a way that can guarantee atomicity. The Meta page is always at page 1, so we know where to find it.

It'll work like this: 
The meta page layout is as follows:
```
+------------+
+ DB headers + (128 bytes)
+------------+
+-------+
+ Tx ID + (8)
+-------+
+-------+
+ Flags + (4)
+-------+
+----------------+
+ Schema Page ID + (4)
+----------------+
+------------------+
+ Freelist Page ID + (4)
+------------------+
+-----------+
+ Num Pages + (4)
+-----------+
+----------+
+ Reserved + (96)
+----------+
+----------+
+ Checksum + (8)
+----------+

```
That makes the size of the meta page 256 bytes. We've reserved quite a bit of space to allow for expanding the meta page if needed.

It's here we need to learn a bit about how disks work. Generally speaking, hard drives typically write data 512 bytes at a time. SSDs typically write data 4096 bytes at a time. Obviously, details vary according to manufacturer.
If the power fails during a page write, the entire disk sector could be corrupted. In practice, the corruption will usually just be a *short write*, meaning that the sector will only be partially written to. But there are no guarantees with disks, so we have to assume that the entire sector could be filled with random junk.

So, to guarantee safety, we reserve *two* meta pages, page 1 and page 2. This is another trick we're borrowing from BoltDB, which has this design. Page 2 has exactly the same layout as page 1, including the DB header.
To save disk IO, we'll write odd numbered transactions to page 1, and even numbered transactions to page 2.

We won't implement this, but if the user specifies page sizes of >= 8192, you could store both meta pages on page 1

## Failure recovery
When the app first boots up, it will attempt to read page 1 and 2. Hopefully, at least one of these two are not corrupted. If both are not, we use the one with the highest transaction ID. If both are corrupted, we have no choice but to reject the database as fatally corrupted. But if the disk is working as advertised, this should not happen.

Consider that since the DB header is on page 1, it can be corrupted as well. Without it, we can't find page 2, since we don't know the page size. In this tutorial, we will just assume this means fatal corruption, but you could actually search the file for the header string "rashdb format A" to find page #2.



#### Design choice 🤔

Our choice to use meta pages is a design choice limited by our goals. Remember that goal #1 is that rashdb must always fit on a single file.

In the DB world, most other databases don't have this limitation, so they use a Write-Ahead Log (WAL) to achieve this goal. Even sqlite, the database famous for having only one file, does this too. When sqlite is running in WAL mode, it writes all new pages to a new file called the WAL file. When your application closes the connection to the DB, it checkpoints the WAL file back into the main sqlite database.

The benefits of a WAL can't be overstated. By and large, file systems are optimized to **append** to the end of a file. WAL files are only ever appended to, so performance wise they are the most optimal way to write to disk.

By separating out reading and writing, WAL also allows for the writer to not block readers. Even we are doing a "mini-WAL" design by writing out new pages to disk instead of overwriting old ones. The difference is that we're not appending to the end of a file, but rather writing blocks within the same file, which is generally slower.

#### end 🤔
