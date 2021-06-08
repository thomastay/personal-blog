---
title: "Brian Harry on Resource Management in .NET (2000)"
date: 2020-08-17T22:47:39+08:00
draft: false
---

The following email is written by Brian Harry and published by Brad Abrams (brada), written in 2000. It's about the .NET runtime (C#, F#, VB),
and why they decided to go with Garbage collection instead of sticking with reference counting.
Worth a read if you're interested in the debate between GC systems vs Ref Counted systems.

The question is all the more relevant these days (2020), with Ref Counted systems in vogue and GC out of fashion. Languages like Rust and Swift are popularizing the idea of a ref-counted only language, and languages like D and Nim are trying to introduce borrowing and pure ref-counting into their languages.

I've extracted it from the Microsoft blogs and re-rendered it to be easier to read.
There are no differences in content, save for formatting changes.

The source can be found here: [Link](https://docs.microsoft.com/en-gb/archive/blogs/brada/resource-management)

### Thomas' Thoughts
- Sadly, the 3 sample files demonstrating a benchmark between GC, atomic refcounts, and single-threaded refcounts has been lost to time.
- The `using` statement that he mentioned as a proposal was eventually implemented.
- The `IDisposable` interface was implemented, and is now a core part of the .NET runtime.
- [A SO thread on this topic from 2009](https://stackoverflow.com/q/867114)
- GC heap scan times are a real pain that microbenchmarks never capture. But GC technology has also improved over the years - concurrent GCs like G1 or Shenendoah in the JVM make this point moot.
- A lot has changed in the past 20 years wrt ref counting.
- C++ introduced `unique_ptr` and `shared_ptr` in 2011, making Brian's point about C++ programmers making bugs in ref counting obsolete. The brilliant idea was to have both types of pointers, to split ref counting into ownership and shared ownership. But even in `shared_ptr`, the design is rather complex to allow for `weak_ptr`, and to guarantee atomicity.
- Rust's ownership system has relegated memory management to a very tiny fraction of an average Rust program, making Ref counting feasibly for what's left. 
- Nim has figured out how to implement Move semantics without user annotations (see Nim's arc memory management). This makes atomic ref counting largely unnecessary, which speeds up ref counting by quite a bit.

# Email reproduced below:

Date: Fri, 6 Oct 2000 08:22:59 -0700

Reply-To: dotnet discussion <DOTNET@DISCUSS.DEVELOP.COM>

Sender: dotnet discussion <DOTNET@DISCUSS.DEVELOP.COM>

From: Brian Harry <bharry@MICROSOFT.COM>

Subject: Resource management

I know people have been waiting a long time for someone at Microsoft to say
something about the issue of resource management and deterministic
finalization.  Because this is such a sensitive topic I am going to try to
be as precise and complete in my explanation as I can.  I apologize for the
length of the mail.  The first 90% of this mail is trying to convince you
that the problem really is hard.  In that last part, I'll talk about things
we are trying to do but you need the first part to understand why we are
looking at these options.  Don't get too depressed reading the first part
it's all background.

# History

First, let me start with some history.  A few years ago when this project
first started we had a massive debate on this very issue.  Some of the early
contributors to this project came from the COM and VB teams, along with many
other teams across the company.  One of the big problems we set out to solve
was to eliminate the issues with ref counting, including cycles and errors
due to misuse.  There were all kinds of anecdotes running around at the time
about how team X used the last N months of their product cycle chasing down
ref counting bugs.  I suspect some of it was overblown, but nonetheless we
believe that ref counting errors are reasonably common and providing a
uniform solution is a valuable addition.

We initially started with the assumption that the solution would take the
form of automatic ref counting (so the programmer couldn't forget) plus some
other stuff to detect and handle cycles automatically.  We looked at adding
conservative collection or tracing to the mix, GC algorithms that could
collect a single object without doing an entire graph trace, etc.  For a
variety of reasons (more on this below), we ultimately concluded that this
was not going to work in the general case.  In those days the primary focus
of our effort was in maintaining VB compatibility.  The solution had to be
complete and transparent with no semantic changes for VB.  We eventually
ended up with a context-based model where there was a "deterministic
context" and everything in that context used ref counting on top of GC and
anything outside just used GC.  This avoided some of the type bifurcation
issues described below but didn't yield a particularly good story for
fine-grained mixing of code between languages.  Ultimately, as you all know,
we decided to make a series of changes to the VB language to modernize it
and make it more capable.  As part of this decision we decided to drop the
VB lifetime compatibility requirements.    This decision also generally
ended investigation into deterministic lifetime issues.  In retrospect, I
think we tied that issue a little too closely to VB semantics and should
have instead turned the discussion to the broader issue of resource
management.  We are looking at it that way now, if belatedly.

In the beginning, I was one of the most vocal advocates of ref counting.  We
came up with a million arguments for why deterministic finalization was
critical.  However, during this time we have watched (and helped) hundreds
of thousands of lines of code be written without deterministic finalization.
Now I am convinced that substantial programs can be reasonably written and
debugged without the system providing any automatic support.  That said, I
fully agree that it would be better if the system/language provided
additional support.  Without it, you must build the behavior into the
contract of the objects (like calling the Dispose method).

on to a technical analysis of the issues...

# Deterministic Finalization

The first thing I want to do is define what it is we are talking about and
give some examples.  Without going into details of the implementation, what
we refer to as "deterministic finalization" means: immediately after an
object is determined to be no longer used by the program, its termination
code executes and releases the references it holds on other objects
cascading the termination in a predictable and repeatable order through the
graph of objects.  Ideally, this would work for both shared and single use
objects.  The term "immediately" here is open to some interpretation.  It's
actually not a promise about time at all (for example a context switch can
happen and an arbitrary amount of time can pass).  It really means that the
thread that discovers a reference is no longer used executes the termination
code before it does anything else.  There are a variety of cases where we
care about either timeliness or order of the execution of the termination
code of related objects.  The most common case is where the object
represents a physical resource (like memory or files or ...).  But it
generally applies in any case where there is contention.  Some examples:

- Memory - freeing the memory for an object graph quickly returns the memory
to the pool for use.
- Window handles - the footprint of the window object in the GC does not
reflect the actual cost - there is some footprint inside the OS to represent
the window and there may even be a limit (other than available memory) on
the total number of window handles that can be allocated.
- Database connections - concurrent database connections are frequently
licensed and therefore there may be a small (like you could actually count
that high in a few seconds) number of them available.  It is important that
these be returned to a pool promptly so they can be reused.
- Files - since there is a single instance of a given file and exclusive
access is required for many operations (deleting, writing, etc) it is
important that file handles get closed very aggressively.  The canonical
example goes something like this (in pseudo code):
  ```C#
          File f = new File("c:\foo.txt");
          byte[] b = f.Read();
          File.Delete("c:\foo.txt");
  ```
- Window subclassing - On tear down, it's reasonable to unsub-class window
functions in Windows.  It's important that this happen after all of the
messages have been sent to the window and therefore after any other
termination code that sends messages to the window.

I could go on and on, but you get the point.

# Ref counting collection

Ref counting does a reasonable job providing deterministic finalization in
many cases.  It is worth noting that there are quite a few where it does
not.  The most common cited example is cycles.  In fact, straightforward
reference counting never collects objects that participate in cycles at all.
There are techniques to manage this and we have all learned them painfully
but it is a very undesirable characteristic and a huge source of bugs.  In
addition, if you start remoting objects across apartments, you can get
apartment reentrancy and thus introduce a great deal of "nondeterminism" in
your program.  Some would argue that as soon as you hand a reference to an
object outside the immediate control of a tightly coupled program you have
lost your deterministic finalization because you have no idea when or if
that "foreign" code will release the reference.  There are others who
believe building a complex system that is very dependent on the order of
termination of a complex graph of objects is an inherently brittle design
and is likely to create a significant maintenance problem as the code
evolves.  I understand most of this is of little comfort because a
reasonably constrained program written by a reasonably competent programmer
does get the benefits of deterministic finalization.

# Tracing collection

A tracing collector definitely makes some weaker promises than ref counting
does.  It is a somewhat more "lazy" system with respect to executing
termination code.  Objects have "Finalizer" methods that are executed when
the object is no longer reachable by the program.  Tracing has the advantage
that cycles are not an issue.  It also has the huge advantage that assigning
a reference is a very simple move operation (more on this in a minute).  The
price that you pay for this is that there is no promise about termination
code running "immediately" after a reference is no longer used.  However, I
think there is a bunch of confusion about what IS promised (caused largely
by our docs and due to some bugs in the pre-release causing finalizers not
to be called on shutdown :)).  The truth is that for "well behaved"
programs, the finalizers will be called for objects.  An ill-behaved program
is one that crashes or puts the finalizer thread in an infinite loop, etc.
Our docs are overly cautious about promises in this respect.  If you have an
object with a finalizer, the system will call it.  This doesn't address the
issue of deterministic finalization, but is important to understand that
resources will get collected and finalizers are a very valuable way of
preventing resource leaks in a program.

# Performance

Before I get into an explanation of the reasoning, I want to cover
performance.  I have seen quite a lot of doubt about whether performance is
relevant.  I strongly believe it is.  I believe that we must have some kind
of tracing collector to handle cycles, which necessitates a big part of the
cost of a tracing collector.  I also believe that code execution performance
can be substantially affected by the cost of reference counting.  The good
news is that in the context of all objects allocated in a running program,
the number of those objects that really need deterministic finalization is
small.  However, below I'll talk about why it is hard to isolate the cost to
just those objects.  Let's look at some pseudo code for a simple reference
assignment when using a tracing collector vs. ref counting:

### tracing:
```C#
a = b;
```

that's it.  The compiler turns that into a single move instruction and might
even optimize the whole thing away in some circumstances.

### ref counting:
```C#
if (a != null)
        if (InterlockedDecrement(ref a.m_ref) == 0)
                a.FinalRelease();
if (b != null)
        InterlockedIncrement(ref b.m_ref);
a = b;
```

This code is huge.  The bloat is very high - bigger working set and the
execution performance is obscenely higher, especially given the two
interlocked instructions.  You can limit the code bloat by putting all of
this stuff in a "helper" and further increasing the length of the code path.
In addition code generation will ultimately suffer when you put in all of
the necessary try blocks because the optimizer has its hands somewhat tied
in the presence of exception handling code - this is true even in unmanaged
C++.  It's also worth noting that every object is 4 bytes bigger due to the
extra ref count field, again increasing memory usage and working set.

Here are a few programs I have written that demonstrate the cost of this.
This particular benchmark loops, allocating objects, doing two assignments
and exiting the scope of one reference.  As with any benchmark you can make
a million arguments about whether it is valid or not.  I'm sure someone will
argue that in the context of this routine, most of the ref counting can be
optimized away.  That's probably true, however this is intended to simply
demonstrate the effect.  In a real program, those kinds of optimizations are
actually very hard if not impossible to do.  In fact in C++, what happens is
programmers make those optimizations manually and that leads to lots of ref
counting bugs.  I would argue that in a real program the ratio of assignment
to allocation is much higher than this.

- \<\<ref\_gc.cs\>\>  - the version which relies on the tracing GC.

- \<\<ref\_rm.cs\>\> - a ref counted version that uses interlocked operations for
thread safety.  Note there is only one thread and therefore no bus
contention making this the "ideal" case.  I'm sure with some tuning we could
make it perform a bit better, but not a ton.

  It is worth noting that VB has not historically had to worry about using
interlocked operations for its ref counting (although VC has).  This is
because VB components ran in a single threaded apartment and where
"relatively" guaranteed that only a single thread would be executing in them
at one time.  One of the goals we had for this version was to open up VB for
multi-threaded programming and to get rid of the complexity of COM's
existing 7 or 8 threading models (I can enumerate them if you insist).  So I
believe the multi-threaded comparison is the correct one.  However, just in
case there are nay-sayers, I have included the version that doesn't use lock
prefixes.  It is not nearly as slow as the multi-threaded version, but it is
still quite a bit slower than the GC version.

- \<\<ref\_rs.cs\>\> - a ref counted version that assumes it is running in a
single threaded environment.

Here are the numbers I got on my dual proc PIII-600:

```
ref_gc:         531ms
ref_rm:         3563ms
ref_rs:         844ms
```

# The perfect solution

I think everyone agrees that the perfect solution is that every object in
the system is cheap to allocate, use and reclaim and at the same time goes
away in a deterministic, orderly fashion the instant the programmer believes
he/she is no longer using it regardless of whether there are cycles or
anything else.  The only way I am aware of to accomplish this is to combine
something like a tracing GC with something like ref counting.  I believe the
data shows that ref counting is too expensive to be used in a general
purpose way for all of the objects in programming environment.  The code
paths are longer, and the code and data working set are larger.  If you then
combine this already high price with the additional cost of implementing a
tracing collector to reclaim cycles, you are spending an exorbitant price
for memory management.

We researched various techniques to improve the performance of ref counting.
There have been reasonably high performance systems built on ref counting
before.  We surveyed the literature, but these systems accomplished the
improved performance by giving up some of their determinism.  I don't
remember the details because it was years ago and I didn't do the research
myself.

It is worth noting that C++ programs don't do this.  Most high performance
C++ programs that use COM actually use C++ classes internally where the
programmer is required to explicitly manage the memory.  C++ programmers
generally only use COM on the boundaries where the API is exposed to
clients.  This is a key characteristic that allows the programs to perform
well.

I'm sure my argument here is not going to sway everyone in the world.  All I
can say is we did a bunch of benchmarking and profiling and ultimately
concluded that the performance was unacceptable and therefore the solution
unattainable.

# The next best thing

OK, so you can't have it all, but what about if you could just have
deterministic finalization on those objects that you need it on?  This is
where we spent most of our time thinking.  Again you have to remember that
most of this was in the context of exactly duplicating VB6 semantics with
our new system.  Most of the analysis still applies but some ideas that we
discarded a long time ago now look more palatable as a resource management
technique rather than transparent VB6 lifetime semantics.

Our first hope was that there would be some way to simply mark a class as
requiring "deterministic finalization" either with an attribute or by
inheriting from a "special" class.  This would cause the object to be
reference counted.  We investigated tons of different designs that included
both subclasses of System.Object and changing the root of the class
hierarchy to some other class that served to bind the ref counting world to
the non-ref counting world.  There are two basic issues that we couldn't
work around:

1. composition - Any time you take an object that requires deterministic
finalization and store it in an object that does not, you have lost the
determinism transitively.  The problem is that this strikes at the heart of
the class hierarchy.  For example, what about arrays?  If you want to have
arrays of deterministic objects, then arrays had better be deterministic.
What about collections, hash tables, ....  The list goes on and on and
before you know it, the entire class library is ref counted.  The other
alternative is to bifurcate the class library - have deterministic arrays
and non-deterministic arrays, etc.  We thought about this, but soon
concluded you'd have two copies of the whole framework and that would be
confusing, perform horribly (you'd have 2 copies of every class loaded) and
in the end wouldn't be practical.  We could think of specific solutions to
specific classes (like I think, although I can't remember, that we came up
with some way to make arrays work, but the solution just didn't scale to the
whole framework).  The fundamental problem is that if a non-deterministic
object contains a reference to a deterministic one, the system is not
deterministic.  We also considered outlawing it; simply having that be an
error.  Again we felt that you couldn't write real programs under those
constraints.

1. casting - A somewhat related issue is what about casting?  Can I cast a
deterministic object to System.Object?  If so is it ref counted then?  If
the answer is "yes" than everything is ref counted.  If the answer is "no"
then the object loses determinism.  If the answer is "it is an error" then
it violates the fundamental premise that System.Object is the root of the
object hierarchy.  And what about interfaces?  If a deterministic object
implements interfaces, is the reference typed as an interface ref counted?
If the answer is "yes" then you ref count all objects that implement
interfaces (note System.Int32 implements interfaces).  If the answer is "no"
then you lose determinism.  If the answer is "it is an error" then
deterministic objects can't implement interfaces.  If the answer is "it
depends on whether the interface is marked deterministic or not" then you
have a bifurcation problem of a different sort.  Interfaces aren't supposed
to dictate object lifetime semantics.  What if some guy implemented an API
that takes an ICollection interface (pick your favorite) and your object
that implements it needs determinism but the interface wasn't defined that
way?  You are screwed.  This leads to further bifurcation.  Everybody
defines 2 interfaces, one deterministic and one not and implements every
method twice.  Believe it or not, we actually looked at what it would take
to do this automatically and to automatically generate the versions of the
methods (deterministic or not) as they were used.  That whole line of
thought deteriorated into immense complexity.

All of this led us to conclude that a really automatic and simple type
modifier couldn't be done.  That said, there are some ideas below on how we
could relax some constraints and get something that might be helpful.

# If not types what about references?

OK, so if we can't mark types and have it all just work, how about if I can
mark a variable as ref counting the referenced object?  We spent a little
while talking about this and it has some nice characteristics.  However
there are two things that cause problems.

1. construction - Since the ref counted property is associated with the
reference rather than the type it means ref counting isn't initiated at
construction.  So here's a really ugly scenario.  You create an object and
store it in an un-ref counted variable because you know it doesn't need ref
counting.  You pass it to someone else who isn't sure so he puts it in a ref
counting variable which increments the ref count to 1.  When his variable
goes out of scope, the count is reduced to 0 and the object is terminated.
The caller never knows what hit him.  This is so fragile it'll never work.

1. composition - Same kind of composition problems as above.  How do you
have a ref counted member variable in a class when you have no idea whether
its users will ref count or not.

# What about deterministic finalization and value types (structs)?

I've seen a lot of questions about structs having destructors, etc.  This is
worth comment.  There are a variety of issues for why some languages don't
have them.

1. composition - They don't give you deterministic lifetime in the general
case for the same kinds of composition reasons described above.  Any
non-deterministic class containing one would not call the destructor until
it was finalized by the GC anyway.

1. copy constructors - The one place where it would really be nice is in
stack allocated locals.  They would be scoped to the method and all would be
great.  Unfortunately, in order to get this to really work, you also have to
add copy constructors and call them every time an instance is copied.  This
is one of the ugliest and most complex things about C++.  You end up getting
code executing all over the place where you don't expect it.  It causes
bunches of language problems.  Some language designers have chosen to stay
away from this.

Let's say we created structs with destructors but added a bunch of
restrictions to make their behavior sensible in the face of the issues
above.  The restrictions would be something like:

1. You can only declare them as local variables.
1. You can only pass them by-ref
1. You can't assign them, you can only access fields and call methods on
them.
1. You can't box them.
1. Problems using them through Reflection (late binding) because that
usually involves boxing.

maybe more, but that's a good start.

What use would these things be?  Would you actually create a file or a
database connection class that can ONLY be used as a local variable?  I
don't believe anybody really would.  What you would do instead is create a
general purpose connection and then create an auto destructed wrapper for
use as a scoped local variable.  The caller would then pick what they wanted
to use.  Note the caller made a decision and it is not entirely encapsulated
in the object itself.  Given that you could use something like the
suggestions coming up in a couple of sections.

# So what then? (Summary of problem statement)

I hope the above analysis convinces you that we have thought long and hard
about this and have not been able to find a "magic bullet".  I wish there
were one, but I can't find it and I've watched dozens of other people wrack
their brains.  What I have listed here is, by no means, an exhaustive list
of everything we have considered, but should give you an idea of how hard we
have tried.

In summary:
  - We feel that it is very important to solve the cycle problem without
forcing programmers to understand, track down and design around these
complex data structure problems.
  - We want to make sure we have a high performance (both speed and
working set) system and our analysis shows that using reference counting for
every single object in the system will not allow us to achieve this goal.
  - For a variety of reasons, including composition and casting issues,
there is no simple transparent solution to having just those objects that
need it be ref counted.
  - We chose not to select a solution that provides deterministic
finalization for a single language/context because it inhibits interop with
other languages and causes bifurcation of class libraries by creating
language specific versions.

The picture can't possibly be that bleak.  Clearly you can implement
ref-counting yourself.  Just add a member variable and a few methods and
call AddRef and Release where you need to.  Further, messing up ref counting
isn't quite as bad as it used to be because you won't leak forever
(forgetting to release) and you won't crash (forgetting to add ref).  The GC
will be a back stop and make the object go away when it isn't used any
longer and keep the object alive (at least the memory) as long as you have
any references whether or not you have a ref count on it.

# Breaking down the problem and suggesting some solutions

There are really several different scenarios here.

First, let me go back to the statement of determinism.  There is a
distinction between objects that really need deterministic finalization and
those for which the GC simply can't accurately cost the footprint.  Things
like window handles, bitmaps, etc are actually fairly plentiful and the GC
could do a darn fine job collecting them if it just knew what the actual
cost to the OS was instead of the portion of the footprint that lives in the
GC heap.  In fact, internally in WinForms we have a class called
HandleCollector which keeps track of all of the Windows handles of this type
that we use and uses some metrics to decide when it is appropriate to
provoke a GC (using the GC class) to cause collection to happen and clean up
all of the unused handles.  You can also simply provoke a GC in your
resource acquisition logic whenever you fail to acquire the resources you
need in the hope that the GC will free them up.  In the last month, we have
discussed formalizing some GC extensibility (in fact the handle collector is
not tied into the GC in any way - you could write the same thing yourself)
that would allow objects/classes to describe their cost model so that the GC
can better decide when it is appropriate to do a collection.  This does not
solve the general problem of determinism because any time the number of
allowed instances is small, the GC is WAY too big of a sledge hammer to
tackle the problem.  Doing a GC every time you recycled a database
connection would destroy your performance.  Our current thinking is not to
add this to the product at this time because people can do it themselves
pretty easily.  Designing an extensible and efficient cost model will be
tricky and we can't really add much value over what you can do yourself.

For those objects that really do need precisely timed termination logic,
let's look at what you can do yourself and then let's ask ourselves what the
system/languages can do to make it easier, less prone to error, less typing,
etc.

First, we are discussing formalizing a design pattern that we already use
within the framework.  All of our resource classes already support a method
called Dispose().  It is a public method that you can call at any time that
will release the resources contained by the object.  Think of it kind of
like the c++ delete operator but it doesn't actually free the memory, it
just runs the destructor.  We are considering making this an interface to
help codify the design pattern and facilitate some language support as
described below.  The interface would look like:

```C#
public interface IDisposable
{
        void Dispose();
}
```

There are a couple of interesting scenarios: scoped locals and unscoped
members.  I discuss both below:

**scoped locals** - It is a fairly common pattern to have local variables that
allocate a resource, use it and release it before the routine returns.  The
code you would write is below (note this too is pseudo code).  Notice that
you must manually call the Dispose method and you must put it in a finally
to make it resilient to exceptions.

```C#
foo()
{
        File f = new File("c:\tmp");
        try {
                byte[] b = f.Read();
        } finally {
                f.Dispose();
        }
}
```

It gets uglier if you have more than one resource:

```C#
foo()
{
        File f = new File("c:\tmp");
        try {
                File f2 = new File("c:\tmp2");
                try {
                        byte[] b = f.Read();
                } finally {
                        f2.Dispose();
                }
        } finally {
                f.Dispose();
        }
}
```
or a little better:

```C#
foo()
{
        File f2;
        File f = new File("c:\tmp");;
        try {
                f2 = new File("c:\tmp2");
                byte[] b = f.Read();
        } finally {
                f.Dispose();
                if (f2 != null) f2.Dispose();
        }
}
```

PROPOSAL - There is a proposal here to add syntax that would make this look
like the following.  The compiler would effectively expand this code to to
the code above.  Please understand that by telling you we are considering
this, I am making no commitment and this is not a spec.  The `IDisposable`
interface I mentioned earlier would help the compiler disambiguate the
method to call at the end of the scope.  I would like to get your feedback
on the idea however.  Obviously there are subtle variations on the syntax
you can invent.  We believe that this makes the very common design pattern
quite a bit more palatable.

```C#
foo()
{
        using (File f = new File("c:\tmp")) {
                byte[] b = f.Read();
        }
}
```

**unscoped members** - The scoped local variable problem is a very constrained
problem.  It does not begin to address unscoped lifetimes (like member
variables of heap allocated classes).  The case above also only covers
single ownership and not shared ownership where no one piece of code knows
definitively when an object is no longer used.  Only something like ref
counting can be used to solve this problem.  Let's look at the code you
might write:

```C#
public interface IRefCounted : IDisposable
{
        void AddRef();
}

// ref counted base class.
class RefCountable : IRefCountable
{
        private m_ref;
        public RefCountable()
        {
                m_ref = 1;
        }
        public void AddRef()
        {
                Interlocked.Increment(ref m_ref);
        }
        public void Dispose()
        {
                if (Interlocked.Decrement(ref m_ref) == 0)
                        OnFinalDispose();
        }
        protected virtual void OnFinalDispose()
        {
        }
}

// an example ref counted class containing resources.
class Foo : RefCountable
{
        UnmanagedResource m_resource;
        RefCountable m_refCounted;

        Foo()
        {
                m_resource = ...; // acquire an unmanaged resource
                m_refCounted = ...; // allocate another ref counted object.
        }

        // replace the currently contained ref counted object.
        public void Bar(RefCountable r)
        {
                if (m_refCounted != null)
                        m_refCounted.Dispose();
                if (r != null)
                        r.AddRef();
                m_refCounted = r;
        }

        // clean up.
        public void OnFinalDispose()
        {
                if (m_refCounted != null) m_refCounted.Release();
                ...(m_resource);
        }
}
```

In theory, the compiler could hide some of the goo for you, giving you:

```C#
// an example ref counted class containing resources with compiler help.
class Foo : RefCountable
{
        UnmanagedResource m_resource;
        RefCountable m_refCounted;

        Foo()
        {
                m_resource = ...; // acquire an unmanaged resource
                m_refCounted = ...; // allocate another ref counted object.
        }

        // replace the currently contained ref counted object.
        public void Bar(RefCountable r)
        {
                m_refCounted = r;
        }

        // clean up.
        public void OnFinalDispose()
        {
                ...(m_resource);
        }
}
```

You get the basic idea.  I could do some complicated shared lifetime
example, but I won't.  It is worth noting that what I have done here works
fine with the "using" construct described above so you can use ref counted
objects in both single use and unscoped lifetime patterns.  This seems like
a reasonable solution but it fails many of the transparency tests in the
problem statement above.  If you cast Foo to Object, you no longer have any
clue that it needs to be ref counted.  If you cast it to an interface, again
you would not know the underlying object needed to be ref counted.
Although, you could chose to define some interfaces to be inherited from
IRefCountable and they could presumable be ref counted.  The question I have
is what if we put some syntax around this with those limitations and at
least made it look good?  Would that be good, or are those limitations
damning?

# SUMMARY/CONCLUSION

In summary, we could consider adding

1. Extensions to the HandleCollector class for general use
1. Language syntax like the "using" construct for scoped locals
1. Syntax to formalize use of the RefCounted class

But none of these are substantially different or better than what developers
can do themselves.  They simply make the code smaller, cleaner and
potentially less error prone (although that might be open to debate).  The
feedback we get from developers who are using the .NET Framework every day,
including internal developers who have been coding on it for the last couple
of years, is that a tracing GC with finalization is an effective solution to
the vast majority of their needs.

To be clear we are very strongly leaning against doing anything for #3.  We
are not inclined to do #1 because it is so easy for you to do it yourself.
We are closest to the border on #2 but I'd say we are slightly disinclined
to do it, again because it is really not more than syntactic sugar and we
are prioritizing shipping very high.

We generally hear requests for deterministic finalization from developers
who are new to the platform and who are looking for mechanisms that mirror
what they have used in the past.  I hope you feel we have done an adequate
job laying out the thinking and we'd love to hear your feedback.

There it is.  It's long and you probably will disagree with lots of it, but
it's a reasonable analysis (I think).  I'll probably spend the next 2 weeks
of my life clarifying each of the points :)

Brian
