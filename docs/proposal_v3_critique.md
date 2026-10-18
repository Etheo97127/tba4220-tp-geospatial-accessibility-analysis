# Critique of proposal v3

Written against `proposal_v3.docx`, 2026-09-20. Two parts: whether the four
questions hang together, then the proposal as a whole.

---

## Part 1 — Do Q1–Q3 build toward Q4?

**No. They are not a chain, and the proposal currently reads as four
disconnected questions.** That is worth knowing before a reviewer says it.

Taking each link honestly:

| Link | Real? | Why |
|---|---|---|
| Q1 → Q2, Q3, Q4 | **yes** | Q1 is a gate on the input data. Every later result is computed on OSM counts, so Q1 conditions all three. This dependency is genuine and already stated. |
| Q2 → Q4 | **no** | Q2 establishes spatial autocorrelation. Q4's k-means is aspatial — it clusters on the six category scores and ignores geography entirely. Nothing from Q2 enters Q4. |
| Q3 → Q4 | **weak, and partly redundant** | Q3 regresses access on elderly share, housing mix, density, transit distance. Q4's random forest predicts neighbourhood type from essentially the same feature set. Q4 is close to a non-parametric, multi-outcome restatement of Q3. |

Two consequences, one narrative and one methodological.

**Methodological (the serious one).** Q2 exists to establish that access is
spatially autocorrelated. Q4 then runs a chi-square test on the cross-tabulation
of neighbourhood type by city. Chi-square assumes independent observations.
If Q2 succeeds, Q4's test is invalid as specified — neighbouring subzones are
not independent draws, so the effective sample size is far below the nominal
one and the p-value is anti-conservative. This is not a stylistic gap; it is
Q2's own result invalidating Q4's headline test.

*Fix, and it is also the missing link:* replace the naive chi-square with a
spatially-blocked permutation test, and cite Q2 as the reason. Q2 then feeds Q4
materially, and the design reads as deliberate rather than accidental.

**Narrative.** The project's actual conclusion is not Q4. It is the comparative
claim already in the Objective: does planned provision distribute access more
evenly than market-led provision? Under that framing the structure is not a
chain but a **triangulation** — three independent lines of evidence converging
on one claim, gated by a fourth:

- Q1 gates the data.
- Q2 tests **evenness** (is access spatially clustered?).
- Q3 tests **equity** (does access track elderly share and housing type?).
- Q4 tests **structure** (do the same neighbourhood kinds exist in both cities?).

That is a defensible design — arguably better than a chain, since three
independent tests failing to agree is itself informative. But the proposal does
not say it. **Add three sentences to the Objective** making the triangulation
explicit and naming the shared conclusion. It costs ~60 words and converts an
apparent weakness into a stated design choice.

Also worth stating plainly, to pre-empt the redundancy charge: Q3 explains the
**level** of access; Q4 explains its **profile**. Different outcomes, same
predictors.

---

## Part 2 — Critique of the whole proposal

### What is genuinely strong

- Deriving the weights from expenditure data rather than judgement is the best
  idea in the proposal, and it is properly executed — the figures reconcile to a
  single public file, and the equal-weight robustness check is promised.
- Every question carries an explicit H₀. The brief asks for this directly.
- The contingencies are real, not decorative: routing kept off the critical
  path, the Week-2 rough-score release, the drop-Hong-Kong fallback.
- "Population density will come out positive; that is not a finding, it is a
  control" — this kind of line is what distinguishes a designed study from a
  fishing expedition.

### Substantive weaknesses, roughly in order of how much they threaten the conclusion

**1. The detour factor is the largest threat to the comparison, and it is
treated as a nuisance parameter.** A single scalar multiplier on straight-line
distance assumes detour is isotropic and city-invariant. Hong Kong has severe
vertical relief, grade separation and footbridge networks; Singapore does not.
If the *mean* factor differs between cities the comparison is biased, not merely
noisy — and the whole project is a comparison. The proposal even concedes that
hills are ignored, then leaves the concession in Limitations rather than acting
on it.
*Fix:* estimate and report the factor **separately for each city**, test whether
they differ, and use city-specific factors if they do. A significant difference
is itself a publishable observation about urban form, not an inconvenience.

**2. The access score compounds four modelling choices, only one of which is
justified from data.** The 1 km radius, the log transform, the variety
multiplier and the 0–100 rescaling are all asserted. Sensitivity analysis is
promised only for the weights.
*Fix:* vary the radius (800 m / 1 km / 1.2 km) as well. It is one loop, and the
radius is by far the most consequential of the four — it determines how many
facilities enter every count.

**3. Q4's random forest has label leakage and no success criterion.** The
k-means labels are fitted on **both** cities jointly, then a model trained on
Singapore predicts those labels in Hong Kong. The Hong Kong labels are
therefore partly derived from Hong Kong data the model is being tested on. And
"see whether what explains Singapore also explains Hong Kong" states no
threshold — what accuracy counts as transfer?
*Fix:* fit the clustering on Singapore only and assign Hong Kong areas to the
nearest Singapore centroid; state a baseline (majority-class rate, or permuted
labels) and report transfer relative to it.

**4. Workload is unbalanced, which the brief grades under "easy to manage".**
M1 owns Q1 *and* the access score — the critical path everyone else waits on.
M2 owns Moran's I, LISA and Gi*, which is the lightest workstream by some
margin. A reviewer reading for manageability will notice.
*Fix:* move the access score, or at least the detour-factor validation, to M2.

**5. Singapore weights applied to Hong Kong.** The justification given — that it
isolates what is on the ground from differences in spending habits — is correct.
But it means the score is "access to a Singapore-weighted basket", not a welfare
measure for Hong Kong residents. State that, or the comparison invites a
straightforward objection.

**6. n is smaller than 332.** Many subzones are non-residential — Tuas, the
water catchment, offshore islands, parts of the Central Area. After dropping
low-population units the effective n may be nearer 250–270. That affects power
in Q3 and cluster stability in Q4, and should be anticipated rather than
discovered in Week 5.

**7. Mature / non-mature was retired by HDB in 2024.** Using it is fine, but it
must be labelled as a historical classification with its source fixed, or it
reads as an error.

**8. Q1's audit is one category, 12.9% of weight.** Already stated in
Limitations, which is the right call. The residual exposure is Q3's health
sub-hypothesis: elderly residents and void-deck clinics both concentrate in
mature estates, so under-mapping biases that coefficient *toward* the
hypothesis. The proposal now says this. Keep it — spotting it reads as rigour.

### Rubric check

| Criterion | Status |
|---|---|
| ≥ 2 datasets | met (six) |
| Methods beyond the course | met, and explicitly listed — this is where the criterion is scored |
| Quality of design / feasible | strong, subject to items 1 and 4 above |
| No obvious facts | met — the text explains design choices, not GIS basics |
| 5 pages | ~4.5–5; verify by rendering before submission |
| Complexity justifies 4 members | met, but see item 4 on balance |

### The three edits worth making before submission

1. Add the triangulation paragraph to the Objective (Part 1).
2. Replace Q4's chi-square with a spatially-blocked permutation test, citing Q2.
3. Make the detour factor city-specific and testable (item 1).

Everything else can be handled in the final report rather than the proposal.
