---
title: "Crazy idea for a new language"
date: 2020-06-22T15:00:00+08:00
draft: true
---

# Summary

It would transpile to Go, but also have reference capabilities

# Syntax:

## Basics and Structs
```go
x := 0      // x will be of type int
y := 1.1    // y will be of type float
z := int64(0) // z will be of type int64

struct inner {  // structs are ref by default, i.e. they can be modified
  var x int
  var y float
}

struct val Outer { // this means that `Outer` is an immutable struct, by default.
  var inn inner    // inn is a ref struct
}

// my_struct is implicitly of type Outer val
// it is of type val, since Outer was declared with `struct val Outer`
// this means it is immutable
myStruct := Outer {
              inner { 0, 1.3, }
             }
myStruct.inn = inner {1, 2.5} // ERROR - myStruct is immutable

// by default, structs passed in have box reference capability
// so they cannot be modified
func takesABox(s Outer) {   
  fmt.Println(s.inn.x) // prints x
  s.inn.x = 2     // ERROR - will not compile, since s is of type box,
                  // and thus cannot be modified
}

takesABox(myStruct) // allowed. myStruct is a val, which is a type of box
                    // this will be transpiled into:
takesABox(&myStruct) // since it doesn't have to be passed by value

// Now, s is a struct of type ref, meaning it can be modified
func takesARef(s Outer ref) {
  fmt.Println(s.inn.x) // prints x
  s.inn.x = 2     // ok
  fmt.Println(s.inn.x) // prints 2
}

takesABox(myStruct) // ERROR: myStruct is of type val, which is immutable
                    // So, we can't pass a val into a func which expects
                    // a type ref
```

## Functions
```go
// Primitives are passed by copy into functions
x := 0
func test(input int) int {
  return input
}
test(x)

// Structs are passed by reference
struct Inner {
  var f float
}

struct Data {
  var x int
  var inn Inner
}

d := Data { -1, Inner {3.2} } // x is of type Data ref

func test2(datum Data ref) {
  datum.x = 2
}

test2(d)
fmt.Println(d.x) // prints "2"
```

## Primitives
Errors are considered to be a primitive. Unless stated, Primitives are treated as vals. The full list of primitives are:
1. Integers
1. Floats
1. Strings
1. Errors
1. Slices (of default type ref)
1. Maps   (of default type ref)

## Interop with Go libraries
For Go libraries that take in a pointer, there is nothing to do. same for primitives.
The difficulty is interop-ing with golang libraries that take in an object

Most Golang libraries that take in structs actually take in interfaces.

For instance, when we perform a HTTP POST request, it expects to receive a io.Reader object.

Thus, we can pass in a pointer (by reference), since Golang doesn't care if its a pointer or an actual object.

```go
// Definition of POST request in the stdlib
func (c *Client) Post(url, contentType string, body io.Reader) (resp *Response, err error)

// Our modified definition
func (c *Client) Post(url, contentType string val,
                      body io.Reader val)
                        (resp *Response val, err error val)

// in pkg "bytes"
// creates a buffer from the byte aray, taking ownership in the process.
func NewBuffer(buf []byte iso) Buffer

// using it
a := iso { json.Unmarshal(jsonData) }  // json.Unmarshal returns a ref
b := bytes.NewBuffer(a) // a is now consumed
```

Some more examples:
```go
```

## Libraries not supported
The following libraries will not be supported, due to the necessity of taking pointers to primitives (which is not allowed under Gony rules)
1. "sync/atomic"
1. 


## Concurrency

```go
// For primitives, concurrency works exactly as before
// since primitives are just copied over channels
var x int
for i := 0; i < 10; i ++ {
  x += i
}

resultChan := make(chan int)
go func square() {
  resultChan <- x * x
}

result := <-resultChan

// ---------------------------------------
// For structs, the result is more complex
struct Inner {
  var f float
}

struct Data {
  var x int
  var inn inner
}

d := Data {
  x: 10,
  inn: Inner { 1.3, }
}
// now d is of type Data ref

chan1 := make(chan Data)
go func f1() {
  chan1 <- d  // ERROR: d is implicitly captured by the closure.
              // however, d has type "ref", so it cannot be captured.
}

// in order to send d, we first need to convert it into a sendable value
// for this case, let's send it as an iso

// now, d2 is of type Data iso, since it is wrapped in an iso block
d2 := iso {
  Data{ x: 10, inn: Inner{1.3} }
}

chan2 := make(chan Data)
go func f2() {
  d2.x = 11   // OK. d2 is an iso, so it is sendable. Unlike in Pony,
              // now, d2 is automatically consumed.
  chan2 <- d2 // again, when being sent, d2 is automatically consumed again
}()

fmt.Println(d2.x)  // ERROR: d2 is consumed on line 46, and cannot be reused

d3 := <- chan1     // d3 is of type Data iso
// However, when transpiled, d3 will actually be of type *Data
// here's what the above code looks like, transpiled:

d2 := Data{ x: 10, inn: Inner{1.3} }

chan2 := make(chan *Data)
go func f2(d2 *Data) {
  d2.x = 11
  chan2 <- d2
}(&d2)

d3 := <- chan2     // d3 is of type *Data

```

# Scrapped ideas

## [CANCELLED] Making copies and sending copies
**I think it's better to make Gony into a reference semantics language, like Java. So, there will be no value types**

Right now, we're just passing everything as pointers. This is to minimize copying.
But what if you do want to just pass variables around as values?
We can create channels that allow value types, called `copychan`s

```go
inn := iso { Inner{4.2} }

chan2 := make(copychan Inner) // ok, since Inner consists of all copyable values
go func f2() {
  inn.x = 11   // inn is captured, and has type *Inner
  chan2 <- inn // Error: cannot send struct Inner over a copychan
  chan2 <- clone(inn) // OK: Inner is now copied
}()

// ------------ TRANSPILED -----------------

inn := Inner{4.2}

chan2 := make(chan Inner)
go func f2() {
  inn.x = 11
  result := *inn
  chan2 <- result
}()

```
Note that Data cannot be similarly copied, since it holds an Inner struct of type ref
In general, the only types that can be sent over a copychan are structs which contain:
  - Primitives (int/float/...). Arrays are a type of Primitive in Gony
  - Structs/Slices/Maps/... of type val

Any other type is forbidden from being copied, since it is unsafe.

The compiler checks this when you call clone(), and when you declare a copychan type.

## Passing structs into functions


