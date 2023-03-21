---
title: "Why the Wheel Appeal"
date: 2023-02-11T01:00:40-08:00
draft: false
---

I don't understand why the Wheel trading strategy is so popular on Reddit. Am I missing something? This post is a semi coherent ramble where I try and figure out why, oh why, is **the wheel** so heavily promoted on Reddit.

## What is the Wheel?

Put simply, the Wheel *is a covered call strategy*. That's all it is. Really. Nothing more. A strategy so simple that, by the way, it is literally Chapter 2 of the Options Bible, *Options as a Strategic Investment*. And Chapter 1 is definitions. Not that I have anything against Covered Calls, by the way, I use them in my retirement port.

But if it were that simple, people wouldn't be enamoured by it. No, instead the wheel disguises itself with its three step strategy:

1. Pick a good stock you want to own long term
1. Sell puts at the price you want to own the stock at.
1. If you don't get assigned, then you earn the premium, if you do get assigned, then keep the stock and sell covered calls on it until you reach your target price.

Sounds good, doesn't it? You get free money if your stock goes up, and if you get assigned, it was at the price you wanted to buy it at anyways, so you didn't lose any money. After all, stonks only go up, so eventually you'll be able to sell your favorite stock at your target price.

What's wrong?

## 1. The Wheel sounds good by blurring time

In any good magic trick, the magician moves his hand so deftly that you don't see him pull the hankerchief out of his sleeve. When the wheel is presented to you, the magic is in step 3 above.

You see, the usual Wheel strategy is to sell 30-45 days to expiry puts. But then if you get assigned, suddenly the timeframe is infinite! Stonks only go up, and since it's a stock **you picked**, it must go up, right? 😉

One thing I'm coming to realize in trading is that defining your timeframe matters so, so much. A strategy that works on an intraday time frame will be different from a 5 day strategy, which differs from a 4 week strategy, which is light years away from a 1-2 year strategy.

So the wheel pulls the wool over your eyes by cleverly suggesting that you'll be making money every month until you get assigned, then the timeframe flips to infinity.

### But you forgot about the covered calls (CC)!

Yes, but it's never suggested when you stop doing the covered calls. If the stock goes down forever, do you keep your CC position until the stock goes to 0? The timeframe for the puts is clear: 1-2 months. You can measure the P/L, EV, R/R of a position like that. But once you get assigned, suddenly you're selling calls forever. The assumption is that you hold the stock for a long time, only selling when you hit your target price or breakeven from the CC premiums. But again, that might never happen, and it's foolish to think that stonks *only go up*.

You can't count the profitability of a CC strategy solely by how much premium you get from selling calls and not care about the movement of the underlying. If not then every CC strategy has an infinite R/R ratio since there's no risk!

Let's go to Chapter 2 of OSI and see what it says:

> Covered Calls are a **bullish strategy** where the writer of the call makes a small profit if the underlying is bullish or mildly bearish

*Ok, I don't know if it says that in those words but it definitely says something to the effect of this.*

## 2. The Wheel ignores tail events

Covered Call strategies are a theta strategy, which means they are short volatility and short gamma. If implemented blindly, these strategies are prone to tail events.

### 2a. Left tail risk (Stonk drills)

The wheel always cutely reminds you that "you'll get assigned at the price you want!", cleverly hiding the fact that if the stock you're selling puts on drops 35% in a single day, you probably didn't get assigned at the price you wanted. You got a stock trading at 65% of yesterday's value.

In case you think 35% is ridiculous, it happened just last month (Feb 9 2023) with Lyft.

Or what if the stock tanks 60% overnight? Happened to Credit suisse and silicon valley bank, could happen to you too.

### 2b. Right tail risk (Stonk shreks)

This one is even more insiduous. What happens if you ran the wheel on META in early Jan '23 when it was 120, and in a month it goes to 190? I'm assuming you sold 20% OTM Calls if you're in phase 2 of the Wheel, which would be 144. So you made a profit, but would you really be happy, knowing you could have made 58% in a month if you had just held shares?

As humans, we tend to think about downside risk, which is why OTM puts are worth more than OTM calls. But stonks don't go up and down nicely, they jump like a kangaroo high on meth. Missing a 58% pump up is just as bad for your portfolio as a 38% dip in your port, but you don't think of those two numbers as being remotely equal in scariness.


## 3. The Wheel ignores research on Covered Call equity strategies

[Optimized portfolio did a fairly good article on QYLD and why it sucks](https://www.optimizedportfolio.com/qyld/). Briefly summarizing, QYLD buys the QQQ and sells 1mo ATM calls, paying out the premium as income. Even more basically, it's *the wheel* in ETF form.

However even with dividend reinvestment, QYLD underperforms the QQQ. Not too surprising, since the QQQ is a fairly volatile growth index which means that it has high right tail risk.

## 4. The wheel focuses on regular payouts while ignoring CAGR

At the end of the day, I just want to have enough money to retire and fund my kids through college. Isn't that what all you degenerates want? No? You want what? Food stamps or lambos?

It's nice to think of having a steady income stream from the wheel where you get paid monthly. But at the end of the day, I just want line to go up. I don't care if it comes in monthly or if I have to wait 10 years for it, I just want to retire, goddammit. My paycheck is my steady income stream, not my 401k.

I hope you realize that it's just more attractive as a human to think of being paid $300 a month for 10 years as opposed to a lump sum of $50,000 at the end of 10 years, even though the CAGR of one is higher than the other (even accounting for inflation). But if we want to focus on retirement, we have to have a laser sharp focus on CAGR.

## Conclusions
I don't think anything I'm saying here will be that new to experienced folks. I'm writing this more for the younger me who got so hooked in by the Wheel that I didn't understand what I was getting into.

The Predicting Alpha article written by Micah Ng (linked below) is a pretty good guide on what the wheel is, and when you should apply it. But remember that it's a **strategy**, not a religion, and you have to carefully apply the strategy to express your belief in a stock, for the right timeframe.

# Appendix

## Why the wheel is equivalent to Covered Calls

~~Google "en passant"~~

Seriously, though, here's how I think about it. 
We can show that Cash Secured Puts are equivalent to Covered calls with a proof by contradiction. Suppose WOLOG (without loss of generality) that CSPs have a higher expected return than Covered Calls. Then I will show that there exists a risk free strategy that earns money. Since this cannot exist in the real world forever, CSPs are equivalent to CCs.

Simply sell a put, short 100 shares of stock, and buy a call at the same strike as the put. Hold all three until expiration and it should be fairly clear that there is no risk in this strategy except assignment risk. For a sufficiently large entity, assignment risk isn't that big a deal since they can easily afford to get assigned on the put. And then they can immediately use it to cover the short position and they can sell the call with minimal spread.

This strategy has no risk since if the stock goes up 10 points, then the short position loses money, but the call option is worth 10 points more at expiration.

Since we assumed that the short put has a higher expected return than the covered call, this strategy by assumption makes a profit. But there's no risk, so this is impossible.

Note that I never said:
- The strike of the put
- The timeframe of the put

Since these are irrelevant to the proof. So don't listen to anyone who tells you that CSPs are better than CCs for 1-2mo periods.

### Dividend risk?
Yes, I neglected divvies in the above analysis. So this strategy is probably slightly profitable to account for the fact that your short position has to pay out the divvies. But in theory, divvies are factored into the options prices anyways...

Also, this is WSB, who even cares about divvies here.


# References

1. The Wheel: Options Strategy Guide. *https://predictingalpha.com/wheel/*
1. https://old.reddit.com/r/thetagang/comments/11mxuw1/my_nuanced_take_on_a_common_theta_gang_strategy/
