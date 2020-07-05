---
title: "Pony for Rust Developers - Ownership"
date: 2020-07-01T22:47:39+08:00
draft: true
---

If you hang around the Rust subreddit long enough, you might meet some language nerd and his usual rant about his favorite language. A few months ago, I was intrigued enough by one such rant that I checked out Pony, and I gotta say: haven't regretted it since. Pony offers a unique take on ownership, very similar to Rust --- but not quite.

Let's back up a little. What even is Pony? Pony is an Actor based programming language. That means that in Pony, you don't deal with OS threads; instead you define actors, which are like mini-processes. Actors can't read and write from the same piece of memory, and to communicate they send each other **messages**.

What makes Pony unique is its "ownership" system, which are called *reference capabilities*. Most actor based languages copy memory between actors when you send a huge array across actors. But in Pony, you can **move** objects across actors, and the type system guarantees safety.

Sound familiar? I'm going to explore the similarities between Rust and Pony's memory sharing model in this post. 

This post isn't going to be a tutorial, instead I'm going to focus on explaining exactly one example. That's it, just one example.
So, by the end of this post, you'll understand the following piece of Pony code works, and why the equivalent naive Rust implementation doesn't --- or your money back.

Sounds good? tldr, here's the code:

Here's the Rust code. Can you figure out why it doesn't compile?
```rust
use std::thread;

struct Datum {
    datum: i32,
}

struct DatumWrapper {
    field: Datum,
}

fn main() {
    let my_obj = DatumWrapper {
        field: Datum { datum: 10 },
    };
    let alias_to_field = &my_obj.field;
    thread::spawn(move || println!("{}", my_obj.field.datum));
    println!("{}", alias_to_field.datum);
}
```
[Can't figure out the error? Check it out on the Playground](https://play.rust-lang.org/?version=stable&mode=debug&edition=2018&gist=fd4d2c78eef1777c6319ddc18c9ae876)

And here's the Pony code:
```pony
actor Taker
  be take(d: DatumWrapper iso) => None // do nothing
  
class val Datum
  let datum: I32
  new val create(x: I32) =>
    datum = x

class DatumWrapper
  embed field: Datum
  new iso create(x: I32) =>
    field = Datum(x)

actor Main
  new create(env: Env) =>
  	let my_obj = DatumWrapper(10)
  	let alias_to_field = my_obj.field
  	//  ^^^^ alias occurs here
  	Taker.take(consume my_obj) // send object to another actor
  	env.out.print(alias_to_field.datum.string()) 
	//            ^^^^  alias still can be used
```

## Intrigued? Let's get started!


The first thing to talk about is the simple stuff. You know, variables, classes, functions. Let's get this out of the way so we can talk about the fun stuff.

### Variables

In Pony, you declare variables like this:

```pony
let x = "Hello"
var y = 2
x = "world"     // ERROR: x is immutable
y = 4           // ok, y is mutable
```

### Classes

Pony is an object-oriented language, so you have classes which have constructors. Nothing much here. Without concurrency in the picture, Pony acts just like Java, so if in doubt just ask: WWJD (what would Java do?)

```pony
class Datum
  let datum: I32
  new create(x: I32) =>
    datum = x
```

The above creates a very simple wrapper for an integer, which I can create by calling `Datum(10)`. The `new` keyword denotes that `create` is a constructor for the object. The `create` constructor is special, and  `Datum(10)` is desugared into `Datum.create(10)`.

There is one thing worth pointing out, namely that the `datum` field in the Datum object is public and immutable. That means, I can call `Datum(10).datum`, but I cannot change it.

### Main 

Speaking of which, let's run some code! We need a main function, which will be the constructor of the Main actor. Actors are just classes with a message queue.

```pony
actor Main
  new create(env: Env) =>
    env.out.print("Hello, world!")
    env.out.print(Datum(10).datum.string()) // Output: 10
```

Pony doesn't have a `println!` macro, unlike Rust. In fact, Pony doesn't have macros at all, which makes things annoying. But I digress.

### Async functions

Lastly, actors can have async functions, with the `be` keyword. The code below prints either 
1. `Hello, world!` followed by `Other hello!`, or
1. `Other hello!` followed by `Hello, world!`


Since the function `sayHello` can be scheduled on another thread from the `main` function.

```pony
actor Other
  be sayHello(out: OutStream) =>
    out.print("Other hello!")

actor Main
  new create(env: Env) =>
    Other.sayHello(env.out)
    env.out.print("Hello, world!")
```


## Concurrency

Let's have our program send a Datum object from one actor to the other. In Rust, we'd do it by spawning a thread and moving it to the other thread:

Rust code:
```rust
use std::thread;

struct Datum {
    datum: i32,
}

fn take(d: Datum) {}  // do nothing

fn main() {
    let my_obj = Datum { datum: 10 };
    thread::spawn(move || take(my_obj));
}
```

And in Pony, it almost works like that.
*Warning: This code will not compile!* 

```pony
class Datum
  let datum: I32
  new create(x: I32) =>
    datum = x

actor Taker
  be take(d: Datum) => None // do nothing

actor Main
  new create(env: Env) =>
  	let my_obj = Datum(10)
  	Taker.take(my_obj)
```
If you compile this, you'll get the following error:

```
Error:
main.pony:7:11: this parameter must be sendable (iso, val or tag)
  be take(s: Datum) => None // do nothing
```
What's that? It's time to talk about the fun stuff!

# Reference Capabilities

Reference capabilities are Pony's secret sauce, and it's what lets you go fast. In general, Ref Caps (as they are often called), let you prevent two actors from accessing the same piece of memory. So, no more data races, no more deadlocks!

## Your first ref cap, Ref

When we created a datum object above, it actually has a hidden type, called ref:
```pony
actor Main
  new create(env: Env) =>
  	let my_obj = Datum(10)
    // The type of my_obj is actually a Datum *ref*
    let my_obj: Datum ref = Datum(10)
```

Refs are so named because these variables are *pass-by-reference*. If you're familiar with Java/C#/Python/JS, or any language where you have references, then Pony's refs should be very unsurprising to you. 

In the following example, we create an array and pass it in to a function which modifies it. In this case, *fun* is just the way to declare a function:
```pony
actor Main
  new create(env: Env) =>
    let my_arr: Array[I32] ref = [1; 2; 3]
    let i: USize = 1 // update index 1 of the array
    try
      env.out.print(my_arr(i)?.string()) // Out: 2
      update_to_42(my_arr, i)? // pass array by reference
      env.out.print(my_arr(i)?.string()) // Out: 42
    end
    // ^^^ try block is needed in case index out-of-bounds

  fun update_to_42(my_arr: Array[I32] ref, ind: USize) ? =>
    my_arr.update(ind, 42)? // update index 1 to be 5
```

This is different from Rust's mutable borrows in that it's completely unchecked. I could take that array, store it in a million different data structures, modify it, delete it; Anything I want to. 

In fact, there's no way to express **ref** in Rust - but for good reason! This sort of thing is highly unsafe in concurrent scenarios, and even in single-threaded situations it makes code hard to reason about.

For this reason, Pony says: ok, you can eat your cake, but you can't have it too. If you have a ref, you can't pass it to another actor. It has to stay within a single actor, *forever*. You get to do all this crazy mutation, but it stays completely single-threaded.

## But I so wanna pass data around! (Iso)

If you want to pass data around, you gotta use Iso. An Iso is very similar to Rust's default types: only one variable can own an *Iso* object at a time. 

Let's change the previous function a little. We're going to make a mistake and see how the compiler saves us from a data race.

Instead of calling a function to update index 1 of the array, let's perform the update in parallel in a different actor, while still doing the printing in actor 1.

I want to stress that this is **inherently unsafe**, and compilers can basically choose to disallow it (Pony / Rust), perform a copy (Elixir), or cause a data race (C++).

Let's see what our program looks like in Rust:
```rust
use std::thread;

fn update_to_42(mut arr: Vec<i32>, ind: usize) {
    arr[ind] = 42;
}

fn main() {
    let my_arr = vec!(1, 2, 3);
    println!("{}", my_arr[1]);
    thread::spawn(|| update_to_42(my_arr, 1));
    println!("{}", my_arr[1]); // oops, borrow after move!
}
```
```
error[E0382]: borrow of moved value: `my_arr`
  --> src/main.rs:11:20
   |
8  |     let my_arr = vec!(1, 2, 3);
   |         ------ move occurs because `my_arr` has type `std::vec::Vec<i32>`, which does not implement the `Copy` trait
9  |     println!("{}", my_arr[1]);
10 |     thread::spawn(|| update_to_42(my_arr, 1));
   |                   --              ------ variable moved due to use in closure
   |                   |
   |                   value moved into closure here
11 |     println!("{}", my_arr[1]);
   |                    ^^^^^^ value borrowed here after move
```


As we expect, Rust notices that the variable is used after it's been moved, and so this program won't compile. 

#### Let's see how Pony prevents this situation with *iso*.

First, in order to pass the array from one actor to the next, we'll make our array an iso array, implying ownership. To do that, we'll use the *recover* keyword, which for now I'll treat as a black box to turn a ref into an iso. 
Next, we'll turn the `update_to_42` into an *async function* of the Worker actor.

```pony
actor Worker
  be update_to_42(my_arr: Array[I32] iso, ind: USize) =>
    try my_arr.update(ind, 42)? end
    // ^^^ try block is needed in case index out-of-bounds

actor Main
  new create(env: Env) =>
    let my_arr: Array[I32] iso = recover iso [1; 2; 3] end
    let i: USize = 1 // update index 1 of the array
    try
      env.out.print(my_arr(i)?.string()) // Out: 2
      Worker.update_to_42(my_arr, i) // pass iso array in
      env.out.print(my_arr(i)?.string()) // Out: 42
    end
    // ^^^ try block is needed in case index out-of-bounds
```
When we compile this, we'll get the following, rather inscrutable error, that basically says that we aren't passing in an **iso** parameter into the function, when it really wants an iso.
```
Error:
main.pony:12:27: argument not a subtype of parameter
      Worker.update_to_42(my_arr, i) // pass iso array in
                          ^
    Info:
    main.pony:12:27: argument type is Array[I32 val] iso!
          Worker.update_to_42(my_arr, i) // pass iso array in
                              ^
    main.pony:2:19: parameter type is Array[I32 val] iso
      be update_to_42(my_arr: Array[I32] iso, ind: USize) =>
                      ^
    main.pony:8:17: Array[I32 val] iso! is not a subtype of Array[I32 val] iso:
                iso! is not a subcap of iso
        let my_arr: Array[I32] iso = recover iso [1; 2; 3] end
                    ^
    main.pony:8:28: this would be possible if the subcap were more ephemeral
        let my_arr: Array[I32] iso = recover iso [1; 2; 3] end
                               ^
```
For various reasons, Pony doesn't do move by default, so we have to explicitly tell the compiler that we want to move *my_obj* into the function, with the **consume** keyword. Think of consume as being like **move**. The only change is in line *12*.

```pony
actor Worker
  be update_to_42(my_arr: Array[I32] iso, ind: USize) =>
    try my_arr.update(ind, 42)? end
    // ^^^ try block is needed in case index out-of-bounds

actor Main
  new create(env: Env) =>
    let my_arr: Array[I32] iso = recover iso [1; 2; 3] end
    let i: USize = 1 // update index 1 of the array
    try
      env.out.print(my_arr(i)?.string()) // Out: 2
      Worker.update_to_42(consume my_arr, i) // pass iso array in
      env.out.print(my_arr(i)?.string()) // Out: 42
    end
    // ^^^ try block is needed in case index out-of-bounds
```

Now we can pass data from one actor to the other, and Pony protects us from using the data that's been moved:
```
Error:
main.pony:13:21: can't use a consumed local or field in an expression
      env.out.print(my_arr(i)?.string()) // Out: 42
                    ^
```
Neat! Pony just saved us from ourselves.

## Val-ue your objects? Share them! (Val)

What if you have an object that you know is never going to change, and you want to pass it around? In that case, we need a different concept than ownership. We need val.

val ensures that an object will never be written to. Since it is immutable for good, we can have multiple threads reading from it at the same time. It's much like how Rust allows unlimited borrows of an object, as long as you never mutate it again. 

Let's rewrite our *Datum* code to use val, since it cannot mutate.

Here's what we want to express, written in Rust. Note that we use Arc to express shared, immutable ownership of an object:

```rust
use std::thread;
use std::sync::Arc;

struct Datum {
    datum: i32,
}

fn main() {
    let my_obj = Arc::new(Datum { datum: 10 });
    let my_obj_2 = my_obj.clone();
    let handle = thread::spawn(move || println!("{}", my_obj_2.datum));
    println!("{}", my_obj.datum); // Out: 10
    handle.join().unwrap(); // Out: 10
}
```

Let's rewrite this in Pony: (TODO)
```pony
class Datum
  let datum: I32
  new create(x: I32) =>
    datum = x

actor Taker
  be take(d: Datum val, out: OutStream) =>
    out.print(d.datum.string())

actor Main
  new create(env: Env) =>
  	let my_obj = recover val Datum(10) end
  	Taker.take(my_obj, env.out)
    env.out.print(my_obj.datum.string())
```

## Unsure?
Just like in Rust, if you're not sure of the type of an object, you can always do compiler driven development. Simply try to cast Datum(10) to a different type (e.g. I32 ref), and you'll see:

```pony
actor Main
  new create(env: Env) =>
    let my_obj: I32 ref = Datum(10)
```
```
Error:
main.pony:12:25: right side must be a subtype of left side
    let my_obj: I32 ref = Datum(10)
                        ^
    Info:
    main.pony:7:3: Datum ref is not a subtype of I32 ref
      new create(x: I32) =>
      ^
```






