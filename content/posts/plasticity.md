+++
date = "2026-05-01"
title = "Plasticity in FEniCSx"
+++

In a series of posts I'd like to introduce you to a (growing) number of documented demos for the
package "dolfiny", that we develop with Andreas and Paul T. Kühner.

- Website: [dolfiny.uni.lu](https://dolfiny.uni.lu)
- Repository: [github.com/fenics-dolfiny/dolfiny](https://github.com/fenics-dolfiny/dolfiny)

---

A typical question you see when it comes to solid mechanics in FEniCS/FEniCSx is:

*"Neo-Hooke is cute, but can you do plasticity?"*

Historically, at least as far as my experience with the project dates (2016-), the first approach
for plasticity was pioneered by Garth Wells and Kristian in their [FEniCS Solid Mechanics package](https://bitbucket.org/fenics-apps/fenics-solid-mechanics/src). This
project is now very outdated and abandoned, but the nice thing it brought was the notion of
"Quadrature" elements, see [this chapter](https://link.springer.com/chapter/10.1007/978-3-642-23099-8_26)
in the FEniCS book, that should be in the vocabulary of each FEniCS user. The rumor also has it
that one of the reasons for starting with FEniCSx is how difficult it was to do "plasticity" models
in legacy FEniCS.

A different approach, that bundles better with the symbolic UFL nature, is based on the notion of
ExternalOperator that was introduced by David Ham in Firedrake. The adaptation to FEniCSx and
plasticity examples is the work of Andrey Latyshev (PhD candidate), Jérémy Bleyer, Jack S. Hale and
Corrado Maurini, see [dolfinx-external-operators](https://a-latyshev.github.io/dolfinx-external-operator/)
and [related publication](https://jtcam.episciences.org/16616) in JTCAM.

---

And now to the dolfiny: At FEniCS 2022 in San Diego, we presented an approach based on what we call
a "Nonlinear local solver", see my [slides](https://orbilu.uni.lu/handle/10993/54223).
In essence, it is a technique to use C kernels generated from FFCx and stack them together,
such that unknowns that have no inter-element continuity can be eliminated from the global system.
Like a static condensation (hybridization, Schur complement, you name it) but with the local problem being nonlinear.
This is the standard way plasticity and similar material models are handled in other codes for decades. It just was not
possible to merge with the typical FEniCSx/FFCx codegen workflow.

The demo that demonstrates the nonlinear local solver is the Rankine (max. principal stress)
plasticity demo, see [Rankine demo](https://dolfiny.uni.lu/plasticity/rankine/).

There is also the monolithic approach applied to the ISO 6892 dog-bone test. That uses the simpler
von Mises yield surface, but has to solve a larger global system, as the local fields (plastic
strain and hardening variables) are not eliminated, see [von Mises demo](https://dolfiny.uni.lu/plasticity/j2-monolithic/).
