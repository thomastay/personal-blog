---
title: "Rashdb Part 3: Reading With B-Trees"
date: 2023-10-29T00:39:15-07:00
draft: true
---

*RashDB is a database I’m building to learn about databases. Come join me!*

In [part 2](./blog/rashdb-part-2-paging), we stopped treating our database as one big data file, and broke it down into pages of 2 kb. This let us read/write data in pages, which is going to be hugely beneficial in this section. We also took the time to implement the list of tables not as a msgpack encoded array, but as a Leaf page itself.

Part 2 commit https://github.com/thomastay/rashdb/commit/227bae98b63fb1c3cfcd968cc1cb2079d672fbf9

In this part, we're going to use the paging system that we've developed to read information from disk. Currently, we've never actually read any data individually from disk. Our test program has only been writing data to disk, and the `dump` program just reads each table row by row. We haven't actually implemented any sort of way to read from disk.

The way we're going to do it is very simple. Remember that our leaf page currently has the following format:
```
(Header - fixed 8 bytes)
+-----+
+ 0x1 + (Leaf)          (one byte)
+-----+
+--------------------+
+ Number of kv pairs +  (two bytes)
+--------------------+
+----------+
+ Reserved +            (five bytes)
+----------+

(Cell pointer area - all indexes are 2 bytes. There are 2n+1 pointers)
+----------+----------+----------+----------+     +---------+
+ key1 Idx + val1 Idx + key2 Idx + val2 Idx + ... + End Idx +
+----------+----------+----------+----------+     +---------+

(Cell area)
+=======+=======+=======+=======+
+ Key 1 + Val 1 + Key 2 + Val 2 + ...
+=======+=======+=======+=======+

```

And here's the signature for the SELECT function[1]:
```go
func (db *DB) Select(tableName string, key string) interface{}
```

In order to find the data on a leaf page, we start from the cell pointer area. Each cell pointer is a two byte value, that gives the index of the starting byte that the Key is on. For instance, Key 1's index might be 100, which means that at byte offset 100, we will find the Cell containing Key 1. Key 2's index is 125, which tells us that Key 1 spans from index 100-124.

Notice that since the cell pointer array is of a known length, and each element is 2 bytes, we don't have to start searching from Key 1. We'll start from the middle instead, and based on by byte comparison, we can decide if we need to search left or right. In other words, that lets us do **binary search** on a page.


### Footnotes
1. Note that we only allow keys to be strings for simplicity. A real implementation would allow multiple keys

