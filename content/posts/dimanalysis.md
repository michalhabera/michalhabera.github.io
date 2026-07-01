+++
date = "2026-05-15"
title = "Automated dimensional analysis"
+++

Another post in our series about "dolfiny" demos will be on dimensional analysis and physical units.

- Website: [dolfiny.uni.lu](https://dolfiny.uni.lu)
- Repository: [github.com/fenics-dolfiny/dolfiny](https://github.com/fenics-dolfiny/dolfiny)

---

Did you know that a physicist named [Geoffrey Taylor](https://en.wikipedia.org/wiki/G._I._Taylor) in
1947 used dimensional analysis to estimate an approximate energy released by the first atomic
explosion in New Mexico, just from motion picture records! The energy released was considered
classified at the time.

Dimensional analysis provides a scaling law between radius \(R\) of the expanding spherical fireball and
the elapsed time \(t\) as
$$R = A t^{2/5},$$
where A is related to the released energy. He then fitted the
motion of expanding fireball and the energy estimate was born.

This was explained also in a [Bomb Blast Radius - Numberphile](https://www.youtube.com/watch?v=SUnAvL-ThMs) video.
For more detailed explanation, see initial chapters in Barenblatt (2003).

{{< figure src="/images/plot.png" title="Figure 1" caption="Photograph of the fireball of the atomic explosion in New Mexico, taken from Barenblatt (2003)." >}}

---

Partial Differential Equations (PDEs) are a mathematical model for the phenomena we're interested
in. They aim to capture the laws of physics, and the laws of physics relate quantities that we
observe and measure. If [FEniCS](https://fenicsproject.org) has a domain specific language for PDEs
called UFL, it sounds natural to annotate its objects with information about units. And that is what
we've been working on for a bit more than a year now: [Automated dimensional analysis for
PDEs](https://arxiv.org/abs/2601.06535).

In a nutshell, this allows you to attach physical units to quantities in PDEs and validate that the
equation is dimensionally consistent (i.e. not adding meters to seconds etc.) In addition, it runs
[Buckingham Pi](https://en.wikipedia.org/wiki/Buckingham_pi_theorem) analysis and provides the
number of dimensionally independent quantities, so-called Pi groups, or also called dimensionless
numbers.

Moreover, since we can traverse the symbolic expression tree of the PDE, we provide an automated
factorization step, that pulls out the dimensional factors from terms in the equations, just like
you'd do manually when proceeding with nondimensionalization.

In the past year I've seen this approach detect some form of dimensional or scaling inconsistency in
every single model where I've applied it to. It catches many of the common mistakes: adding
objective functions of different dimensions, regularization/penalization parameters of magically
small value \(10^{-6}\) or even typos and severe modeling mistakes.

There is a documented demo for this work, applied to the "Hello World" of nondimensionalization,
the [Dimensional analysis of the Navier-Stokes equations](https://dolfiny.uni.lu/units/navier-stokes/).

---

G. Barenblatt, “Scaling,” Cambridge University Press, Cambridge, 2003.
http://dx.doi.org/10.1017/CBO9780511814921