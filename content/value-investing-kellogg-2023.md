---
title: "Value investing analysis: Kellogg (KLG) 2023"
date: 2023-11-12T12:36:35-08:00
draft: false
---

# Summary
Kellogg (KLG) is a recent spinoff of the North American cereal business from the larger parent Kellanova (K). I believe that Kellogg has great investment potential as a classic Greenblatt spinoff play. It experienced indiscriminate selling, is trading close to dividend value, and has a potential for 30% returns.

# Introduction

On Oct 2 2023 [1], Kellogg separated into its own company. This is part of a broader move by the parent company to split up Kellogg into cereal and snacks. Kellanova, now the name of the parent company, believes that snacks are the faster growing part of the business, and cereal is the boring but blue chip part of the business. So to me, the rationale for the split was to allow the snacks company to trade at higher multiples like consumer discretionary; and for Kellogg to trade more like a consumer defensive.

## Spinoff and indiscriminate selling
As of the spinoff date, Kellanova's market cap was around 18B, and it is a member of the S&P 500. As a result, it is heavily held by many institutional investors.
In contrast, Kellogg's new market cap is around 950M, which places it in the realm of the Russell 2000. S&P 500 funds, upon receipt of the shares, are legally required to sell off their shares.

As you can see from this graph, within days of the listing, KLG's share price dipped from $13.80 to $10.19, and it has been trading in a tight band since.
![K share price](/blog/img/klg-share-price.jpg)

# Valuation

## Intrinsic value

Kellogg is a high dividend yield company. In their Aug 23 investor day [2], they mentioned that they expect to have a payout ratio of 45%.

As of Nov 23 quarterly report, KLG book value was $2.30/share, and they paid out $0.16 in dividends, a payout ratio of 33%. We assume that their payout ratio will increase to 45%.

To calculate their dividend value, we used the following factors
1. 10 year RFR - 4.60%
1. Equity Risk Premium - 5%
    1. We do not assume any country risk, since Kellogg is operating entirely in USA, Canada, and the Carribean.
    1. For simplicity, we assume a beta of 1. This may be adjusted in the future.
1. Company risk premium - 1.58%
    1. To calculate this, we note that Kellanova (the parent) is rated as a BBB bond rating. The default spread of this for 10 year bonds of this rating class was 1.58%.
1. Flat income with no growth.
    1. This is a fairly stable assumption, since Kellogg's own quarterly guidance for 2024 is that sales will be flat.
    1. Kellogg's earnings for Q4 2023 was 42M, which equals $0.49 / share

Given these assumptions, we estimate a future quarterly dividend of $0.22, at a discount rate of 11.18%, giving a dividend value of **$7.90**.

In sum, that gives an intrinsic valuation of 2.30 + 7.90 = **$10.20**. This number comes with the assumption of zero change in earnings and thus dividends.
In later sections, we will challenge this analysis by exploring factors that cause earnings to change. 



## Cash flow analysis

YTD, their cash flow analysis is:

![Cash flow Sankey](/blog/img/KLG-20230931-YTD.png)
```
Sales [2112] Revenue
Insurance payout [4] Revenue
Working Capital [88] Revenue
Depreciation [49] Revenue
Misc (1) [2] Revenue

Inventories [106] Working Capital
Payable [22] Working Capital
Accrued Adv&Promo [22] Working Capital
Accrued Salary [22] Working Capital
Misc [8] Working Capital
Working Capital [92] Receivables

Revenue [1544] COGS
Revenue [497] SG&A
Revenue [93] Property Developments
Revenue [29] Tax
Revenue [7] Interest
Revenue [25] Payments to parent company
Revenue [60] Net Cash
```

This leaves 60M cash. Company counts it as 64M cash since they also added back in stock awards (which I don't count), and there is an additional 1M from financing that I didn't count.

Of this, currently 13.7M per quarter will have to go out as dividends. The max amount that can go out every quarter is 15M, which corresponds to a dividend of only $0.175, a decrease from the expected number of $0.22.

This assumes that their property investment remains constant, and that they can't reduce COGS through modernization of the plant.

**note: here is where I gave up, posting these notes years after the fact as analysis notes**


# Footnotes
1. https://investor.wkkellogg.com/news-events/press-releases/press-releases-details/2023/Kellogg-Company-board-of-Directors-Approves-Separation-into-Two-Companies-Kellanova-and-WK-Kellogg-Co/default.aspx
2. https://investor.wkkellogg.com/news-events/press-releases/press-releases-details/2023/KELLOGG-COMPANY-UNVEILS-STRATEGIES-AND-FINANCIAL-OUTLOOKS-FOR-KELLANOVA-AND-WK-KELLOGG-CO-AT-INVESTOR-DAY/default.aspx

