---
title: "Pony actors don't have (their own) stacks"
date: 2020-06-12T12:00:00+08:00
draft: false
---

In this short article I'm going to talk about how [Pony](https://ponylang.io) gets away with not storing a stack for each of its actors. I was pretty surprised to find this out, given that in most actor model languages actors have their own stacks. For instance, in Go, Goroutines have a stack size of 2KB. Elixir/Erlang processes have a 1.2KB combined stack and heap. 
But surprisingly, Pony's actors don't have their own stacks! Instead, they use the stack of the OS thread that they're running on.

Let's take a step back. What even is Pony? For the purposes of this blog, all you have to know is that Pony is an Actor based programming language. That means that in Pony, you can define an actors that send messages to each other, like so:   [1]
```pony
actor Main
  be say() => // say() is a function that can be called on the actor
    env.out.print("Hello, world!")

actor Caller
  be callMain(main: Main) =>
    main.say()  // send the say() message to the main actor
```
If you're not familiar with Actor based languages, I highly recommend you take a look into [Elixir](https://elixir-lang.org). For the rest of this post, I'm going assume you at least know what Actors and message passing are. 

Moreover, although Go is not an actor based language, it is similar enough that we're going to just pretend that Goroutines are like actors (they're not, strictly speaking).

## Example in Go and Elixir

So what do I mean when I say that Pony actors have no stacks? Let's take an example in Go and Elixir to see where stacks are needed in those two languages.


For this post, let's describe a very simple ping demo. We will have an main actor, that sums the numbers from 1 to 10. Then, we will pass it to actor 2, who squares that number, then returns the value to actor 1. Finally, actor 1 prints both the original and the squared numbers. A contrived example, but one that shows off what I mean to show. 

In Go, here's how we would write the code:
```go
func main() {
  var x int 
  for i := 1; i <= 10; i++ {
    x += i
  }

  // spawn a secondary Goroutine
  resultChan := make(chan int)
  go func() {
    resultChan <- x * x
  }()

  // return the result to the main Goroutine
  newVal := <-resultChan
  fmt.Printf("Original: %d, New: %d\n", x, newVal)
  // prints: Original: 55, New: 3025
}
```

In Elixir, here's how we would write the code: [2]
```elixir
x = Enum.sum(1..10)

# Spawn a thread to compute the square
parent = self()
spawn fn -> send(parent, {:result, x * x}) end

# Return the result to the main process
receive do
  {:result, newVal} -> 
    IO.puts("Original: #{x}, New: #{newVal}")
end
# prints: Original: 55, New: 3025
```

Both these languages solve this problem in quite the same way. First, the main actor does the summation. Then, the main actor spawns a worker actor to do the squaring. It then **blocks** to allow the second actor to do its work, and waits for the second actor to signal completion, either through a channel or through messages. 

## A diagram to show you what I mean

It's the blocking operation that requires a stack. To demonstrate, let's pretend that we're running this application on a single CPU. 

![Golang stack illustration](/blog/img/actor-stack-go.png)

As you can see in the figure above, the main Goroutine has its own stack. At time 1, the secondary worker is spawned, which creates another stack. Then, the main Goroutine yields control to the secondary worker. The stack pointer moves to the secondary worker's stack.

The secondary worker then does its work, and sends the newVal result over a channel back to the main goroutine. Having completed its work, the secondary worker yields control back to the main worker. The stack pointer moves to the main worker's stack. Then, the output is printed to the screen.
At this point, the secondary worker's stack is garbage, and may be collected by the GC when it runs.

## Example in Pony

However, in Pony there are **no blocking operations**, which is the key to not needing a stack!

In Pony, we have to write it in a different way. Here's how we would solve the same problem in Pony.

First, we need to have a main actor, to compute the sum of 1 to 10 and spawn a worker. We do so in the constructor of the Main actor:
```pony
actor Main
  var x: I32 // x is a member variable

  new create(env: Env) =>
    x = 0
    for i in Range(1, 11) do
      x = x + i  // sum 1 to 10 in x, a member variable
    end

    // spawn a squarer actor,
    // and then call the square behavior on it
    Squarer.square(x, this)
```
Notice that we don't do anything after calling the square function on the Squarer actor! This is because there is no way to block. Instead, the squarer actor must perform the callback to print messages, which we will see in a second.

Let's define the squarer Actor that will perform our squaring:
```pony
actor Squarer
  be square(x: I32, main: Main) =>
    let newVal = x * x
    main.printResult(newVal)
```

In the square function, we passed along a reference to the Main actor. To those familiar with Elixir, you might want to think of the reference as like the PID of the actor. With the PID, we can then send a message to the main Actor, to tell it to print the squared result.

Finally, let's define printResult():
```pony
actor Main
  var x: I32 // x is a member variable
  // ---- snipped ----

  be printResult(newVal: I32) =>
    _env.out.print("Original: " + x.string() 
                  + ", New: " + newVal.string())
```
You'll notice that we got around not having a stack by storing **x** in a Actor member variable. This is unlike Go and Elixir, where we can just refer to x since we have the stack frame lying around. In Pony, if you want to keep variable across asynchronous method calls, you have to explicitly store it in the Actor, which means that **x** is stored in the *heap*, and not the *stack*.

Let's look at a time diagram.

![Pony-actor-stack](/blog/img/actor-stack-pony.png)

1. In the figure above, time 1 is just after computing the sum from 1 to 10. As you can see, there is an implicit *this* pointer stored on the stack, and a *x* member variable stored in the actor's heap. 
1. Between time 1 and 2, the square behavior is called on the Squarer actor, and the constructor of the Main actor finishes. The Pony scheduler then schedules the Squarer actor to run the square behaviour. As the constructor's stack frame is not needed, it can be popped off the thread stack (whether it actually does is an implementation detail).
1. At time 2, the square behavior has finished.
1. At time 3, the scheduler schedules the Main actor's printResult() behavior. The previous stack frame can be popped off.

Not shown for clarity: the *env* variable, the *this* pointer of the Squarer actor. Also, this isn't exactly how it works, thanks to optimizations, but it's a good mental approximation to what happens.

Putting it together, we get:
```pony
use "collections"  // for the Range operator
actor Main
  let _env: Env
  var x: I32

  new create(env: Env) =>
    _env = env // store env in a member variable
    x = 0
    for i in Range[I32](1, 11) do
      x = x + i  // sum 1 to 10 in x, a member variable
    end

    // spawn a squarer actor,
    // and then call the square behavior on it
    Squarer.square(x, this)

  be printResult(newVal: I32) =>
    _env.out.print("Original: " + x.string() 
                  + ", New: " + newVal.string())

actor Squarer
  be square(x: I32, main: Main) =>
    let newVal = x * x
    main.printResult(newVal)
```

I've tried to keep this example as simple as possible for those new to Pony. Personally, I wouldn't implement it this way, I would use Promises. In the footnotes I've also implemented this function in two other ways, to show you how it can be done. [3]


# Conclusion
All in all, we learnt that Pony actors don't have their own stack, instead leveraging the regular OS thread's stack. This has a performance benefit because now, stack frames don't have to be preserved when switching between actors. Also, memory doesn't have to be wasted for actors not using their stack.

However, it does come with a few downsides. You still have to store variables somewhere, so now they go in the heap instead. This isn't too bad, since in an Actor model system your "stack" is really on the heap. 

More significantly, programming without blocking operations is really painful. It reminds me of early Javascript before async-await: You had to program everything with callbacks and promises. Functions that should have been one long block were split into multiple blocks. 

Pony does have promises, which helps to prevent callback hell, but as JS programmers know, promises just aren't as convenient as async await.

I wonder if it's possible for the Pony compiler to implement Javascript-style async-await, since Pony already has closures and promises.


*Notice anything wrong?* [Edit this page on Github](https://github.com/thomastay/personal-blog/blob/master/content/pony_actors_no_stacks.md)


## Footnotes
1. Yes, this is not valid Pony code. For those watching closely, the main actor has no constructor, so env cannot be used. Moreover, these are not functions, but actually asynchronous behaviors. That said, I didn't want to confuse anyone not familiar with Pony code.
1. I'm no Elixir expert, so I would appreciate any feedback! I wanted to showcase a pure Actor model ping/pong, without any use of Task abstractions, which would probably be more useful for something like this.
1. For fun, I've rewritten the Pony example using (a) callbacks, and (b) promises.

### Using callbacks

```pony
use "collections"  // for the Range operator
actor Main
  let _env: Env
  var x: I32

  new create(env: Env) =>
    _env = env // store env into a member variable
    x = 0
    for i in Range[I32](1, 11) do
      x = x + i  // sum 1 to 10 in x, a member variable
    end

    // spawn a squarer actor,
    // and then call the square behavior on it.
    // this~printResult() creates a closure which captures
    // the local variables _env and x.
    // "recover" is needed to tell the compiler to turn the
    // closure into a sendable object (in this case, an iso)
    Squarer.square(x, recover this~printResult() end)

  be printResult(newVal: I32) =>
    _env.out.print("Original: " + x.string() 
                  + ", New: " + newVal.string())

actor Squarer
  be square(x: I32, callback: {(I32): None} val) =>
    let newVal = x * x
    callback(newVal)
```

### Using promises and partial application
```pony
use "collections"  // for the Range operator
use "promises" 

actor Main
  new create(env: Env) =>
    var x: I32 = 0   // x is now a local
    for i in Range[I32](1, 11) do
      x = x + i
    end

    // create a promise that takes as input the squared num
    // then will print to stdout
    let p = Promise[I32]
    p.next[None](recover this~printResult(env, x) end)

    // spawn a squarer actor,
    // and then call the square behavior on it
    Squarer.square(x, p)

  be printResult(env: Env, x: I32, newVal: I32) =>
    env.out.print("Original: " + x.string() 
                  + ", New: " + newVal.string())

actor Squarer
  be square(x: I32, p: Promise[I32]) =>
    let newVal = x * x
    p(newVal)     // fulfil the promise
```
