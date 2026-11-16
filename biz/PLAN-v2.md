# FrappeX: Plan v2 (draft)

Status: draft for discussion · 2026-11-02 · replaces the scope of v1.0 (October 2025); v1.0 stays as the long-term vision.

## Goal (12 months)

**₹40K+/month recurring** from **10–15 clients running the same product**, each configured for the client.

> 12 clients × ₹3,500/month ≈ ₹42K/month, plus a one-time setup fee (₹15–30K) per client.

The two v1 goals are one goal: 10–20 clients with working apps *is* the path to ₹40K/month, as long as it is
one product configured per client, not 12 bespoke builds.

## Constraints

- Solo founder plus the AI harness (supervisor + workers on two seats).
- Evenings and weekends: about 15 hours a week.
- Self-funded. No office, no hires, no ads in year 1.
- No progress since v1.0: the plan has to move in small dated steps.

## The plan in one line

One vertical, one city, one Frappe/ERPNext-based product with one AI feature that saves real time.
Setup fee + monthly fee. Sold through conversations and referrals.

## Vertical: decided by conversations, not by this table

| | Distributor | School |
|---|---|---|
| Pain | Retailer order booking, stock, outstanding, collections | Fee collection, parent communication, attendance |
| Willingness to pay | Higher: touches cash flow | Lower, price-sensitive |
| Frappe fit | Strong: ERPNext stock, selling, receivables | OK: Education app, less mature |
| AI feature | WhatsApp order message → sales order; payment reminders on WhatsApp | Fee reminders and notices on WhatsApp in Marathi/Hindi |
| Buying window | Any time | Mostly Jan–Apr, before the academic year |
| Main risk | Tally lock-in: needs a Tally sync | Slow, multi-person decisions |

Lean: distributor. Rule: the vertical where someone says "yes, I'd pay for this" wins.

## Offer (to validate, not final)

- **Setup:** ₹15–30K one time: configuration, data migration from Tally/Excel, training.
- **Monthly:** ₹2,500–4,500: hosting, backups, support, small changes.
- **Pilot:** first client (design partner) at a token price; payment of any size is the real signal.

## Milestones

| When | Step | Done when |
|---|---|---|
| Weeks 1–2 | 8 discovery conversations (the school, the distributor, 3 peers of each); see `discovery-script.md` | 8 note sheets; vertical chosen |
| Weeks 3–8 | Build for one paying design partner | Partner uses it daily |
| Months 3–6 | Clients 2–5 in the same vertical, via referrals | 5 paying, ~₹17K/month |
| Months 6–12 | Clients 6–12; standard setup in under a week | ~₹40K/month |

## Weekly rhythm (~15 h)

- 4 h customers: conversations, demos, follow-ups.
- 9 h building, through the harness.
- 2 h admin: notes, invoices, planning next week.
- Sunday: 15-minute review: what moved, next week's three steps.

## How the harness is used

- One product repo; each client is a site on the bench, configured rather than forked.
- The supervisor turns a client's requirements into backlog items; workers build in parallel on A and B.
- Gates (tests per site) keep 12 clients upgradable from one codebase.
- Harness changes only when client work needs them.

## Cut from v1 for now

Three SaaS products, pan-India, ad budget, office, hiring, LLP upfront (start as a sole proprietor; GST when
revenue approaches the threshold), Year 2–3 projections.

## Open questions

- Which vertical (after the conversations)?
- Frontend: React as in v1, or Frappe UI / ERPNext desk with a thin custom portal where it matters?
- Tally: one-time import only, or ongoing sync?
- Pricing: confirm the setup and monthly ranges in the conversations.
