---
title: "Rashdb Part 2: Paging"
date: 2023-10-03T18:41:24-07:00
draft: true
---

RashDB is a database I'm building to learn about databases. Come join me! In part 1, we went over the fundamentals of rashdb, and managed to read/write data to disk.

Part 1 Commit: https://github.com/thomastay/rashdb/tree/6486b0804b18489212dfe2c15f0bbf0b3a31f6cb

As a summary, here's what our database file looks like right now:
```
(DB header)
+-------+---------+
+ Magic + Version +
+-------+---------+

(Table headers)
+------+-------------+
+ Name + Primary Key +
+------+-------------+
+------------+------------+
+ Col 1 Name + Col 1 Type +
+------------+------------+
+------------+------------+
+ Col 2 Name + Col 2 Type +
+------------+------------+
...

(Data section)
+--------------------+
+ Number of kv pairs +
+--------------------+
+----------+----------+-------+-------+
+ key1 Len + val1 Len + key 1 + val 1 +
+----------+----------+-------+-------+
+----------+----------+-------+-------+
+ key2 Len + val2 Len + key 2 + val 2 +
+----------+----------+-------+-------+
...
```

It's pretty good for a start. But obviously, there are a few things wrong with it:
1. It only supports one table
1. The entire DB has to be read/written every time you do an insert
1. Searching for a key on disk is a linear search, since we have to decode key 1, then check if it matches, then decode key 2, etc...

So let's fix it! The standard solution is to implement pages. We've put it off for a while, but it's inevitable so we might as well do it right.

Simply put, we're going to divide our database file up into blocks of four kilobytes. Every disk read/write is going to be done at the 4kb level, and we will implement a **pager** to fetch and cache these pages from disk into memory.

Every table is represented by a unique set of pages, so when we write data to one table, we can do it without affecting other tables. We're also going to store the table *headers* separate from the table *data* - that way, an insert doesn't have to re-write the table headers to disk again, which is useful since the headers basically never change.

In this part, we're **not** going to worry about trees, and interior pages. We're going to assume that every table's data fits onto one page. We'll tackle that in part 3. If you're familiar with B-trees, we're just treating every page as a leaf.

## Data page layout


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

(Cell area - equals signs means variable length fields)
+=======+=======+=======+=======+
+ Key 1 + Val 1 + Key 2 + Val 2 + ...
+=======+=======+=======+=======+

(Free space)
```
Here's the breakdown of a single cell:

```
+=====+=======+=======+=======+     +--------------------------+
+ Len + Col 1 + Col 2 + Col 3 + ... + Page ID of overflow page +
+=====+=======+=======+=======+     +--------------------------+
```
The length of a cell is encoded as a variable length integer, which includes the length of any overflow that spills onto other pages. It doesn't include the 4 bytes used for the page ID, and is really just for the use of overflow. The size of the cell can always be determined by looking at the cell pointer array

(TODO more explanations)

```go
type LeafPage struct {
	// Header     byte  // Not actually stored in memory, but represented in the struct
	NumKV      uint16
	CellOffset uint16
	// reserved (one byte - not used for now)
	Pointers []uint16
	Cells    []Cell
}

// An opaque representation of anything, it could be a series of columns or just a single column
// The application layer is responsible for decoding this
type Cell struct {
	// Encoded as a varint, and represents the size of the entire payload, including overflow
	Len            uint64
	PayloadInitial []byte
	OffsetPageID   uint32 // if there is no offset, represented as 0 and not written to disk.
}

const (
	HeaderLeafPage = 0x1
)
```

Next, we'll change db.Insert to write data to a leaf page instead. We'll keep the headers the same for now and change them later.

We'll write a new function to encode data as a single page

```go
func (n *tableNode) EncodeDataAsPage(pageSize int) (*disk.LeafPage, error) {
	page := disk.LeafPage{}
	numKV := len(n.data)
	if numKV > 65536 {
		panic("TODO: Multi-pages not implemented")
	}
	page.NumKV = uint16(numKV)

	cells := make([]disk.Cell, 2*numKV)
	for i, data := range n.data {
		// Marshal primary key and vals
		diskKV, err := app.EncodeKeyValue(&n.headers, &data)
		if err != nil {
			return nil, err
		}
		keyBytes, valBytes := diskKV.Key, diskKV.Val
		// TODO feat: overflow pages

		cells[i*2] = disk.Cell{
			Len:            varint.EncodeArrLen(len(keyBytes)),
			PayloadInitial: keyBytes,
		}
		cells[i*2+1] = disk.Cell{
			Len:            varint.EncodeArrLen(len(valBytes)),
			PayloadInitial: valBytes,
		}
	}
	page.Cells = cells

	// Calculate pointers
	offsets := make([]uint16, 2*numKV+1)
	ptr := 10 + 4*numKV
	// ^^ 8 bytes header, then 2 bytes each for (2n + 1) pointers
	offsets[0] = uint16(ptr)
	for i := 1; i < len(offsets); i++ {
		cell := cells[i-1]
		ptr += len(cell.Len) + len(cell.PayloadInitial)
		if cell.OffsetPageID != 0 {
			ptr += 4
		}
		if ptr >= 65536 {
            panic("TODO feat: multiple pages")
		}
		offsets[i] = uint16(ptr)
	}
	page.Pointers = offsets

	return &page, nil
}
```

We also have to write the code that dumps the page to disk:
```go
func (p *LeafPage) MarshalBinary(pageSize int) ([]byte, error) {
	var err error
	buf := NewFixedBytesBuffer(make([]byte, pageSize))

	// ---- Write headers ---
	buf.WriteByte(HeaderLeafPage)
	err = binary.Write(buf, binary.BigEndian, p.NumKV)
	if err != nil {
		return nil, err
	}
	err = binary.Write(buf, binary.BigEndian, p.CellOffset)
	if err != nil {
		return nil, err
	}
	buf.WriteByte(0) // reserved for now
	// ---- End headers ---

	for _, ptr := range p.Pointers {
		err = binary.Write(buf, binary.BigEndian, ptr)
		if err != nil {
			return nil, err
		}
	}

	for _, cell := range p.Cells {
		buf.Write(cell.Len)
		buf.Write(cell.PayloadInitial)
		if cell.OffsetPageID != 0 {
			err = binary.Write(buf, binary.BigEndian, cell.OffsetPageID)
			if err != nil {
				return nil, err
			}
		}
	}

	result := buf.Bytes()
	if len(result) > pageSize {
		panic("Leaf page must fit onto page size, splitting should have happened earlier on.")
	}
	return buf.Bytes(), nil
}
```

Next we'll have to read/write pages from disk. It requires some other modifications to 



```
// Temp function until we do something better
func (db *DB) SyncAll() error {
	pagerInfo, err := db.table.root.EncodeDataAsPage()
	if err != nil {
		return err
	}
	err = db.pager.WritePage(pagerInfo)
	if err != nil {
		return err
	}

	tablePagerInfo, err := db.table.MarshalMetaAsPage()
	if err != nil {
		return err
	}
	err = db.pager.WritePage(tablePagerInfo)
	if err != nil {
		return err
	}

	return db.file.Sync()
}
```
Now that we've finished paging, an interesting fact - we don't have to write the header first any more! In fact, we'll test this by flipping things around, and writing the data page before writing the header page.

As it turns out, this is the correct order for our MVCC implementation later on, since we'll be writing data to fresh new pages, then updating the header page to point to those new pages.


Most of part 2 is done by this commit: https://github.com/thomastay/rashdb/tree/c6f1c74bbcabfcb76c60663ea9908e81035651f3

# Part 3: Retrieving
OOf, that's too much data!
The app layer needs to expose a function to find a value by key and return it
Then the app layer can pass a functor to the data layer to retrieve the appropriate cell via binary search
