+++
date = "2026-07-05"
title = "Sparse Cholesky factorization benchmarks on Apple ARM"
+++

Do you have an Apple Silicon Mac, and you wondered what would be the fastest sparse Cholesky factorization library (on CPU)?
I've prepared a small benchmark suite to try to answer this very question.

---

There exists a number of linear solver benchmark collections, but I did not find any that would satisfy the following goal: _to run the same,
linear elasticity problem on a refined set of meshes, from 1k to 1M degrees of freedom._

For example, the popular [SuiteSparse Matrix Collection](https://sparse.tamu.edu/) has a number of structural 2D/3D matrices,
e.g. the [Janna group](https://sparse.tamu.edu/Janna), but they are too large for my laptop and provide only a coarse set of sizes.

Another benchmark collections worth mentioning:

- [StAnD: A Dataset of Linear Static Analysis Problems,](https://github.com/zurutech/stand)
- [NAFEMS Linear Static Benchmarks](https://help.solidworks.com/2026/english/simtutorialonline/c_nafems_linear_top.htm?id=1.1.0),
- or, if comfortable with traingulated, STL surfaces, [CarHoods10k](https://datadryad.org/dataset/doi%3A10.5061/dryad.2fqz612pt).

So I've set up a simple pipeline that:

1. generates a 3D CAD model of a clevis bracket in [build123d](https://build123d.readthedocs.io/),
2. meshes it for various mesh sizes in [gmsh](https://gmsh.info/),
3. reads the mesh in [FEniCSx](https://fenicsproject.org/) and assembles a linear elasticity problem matrix \(K\) and right-hand side \(f\) into [PETSc](https://petsc.org/release/) data structures,
4. stores the matrix \(K\) and vector \(f\) into a file,
5. and finally reads the matrix \(K\) and vector \(f\) from the file and runs a sparse Cholesky factorization solver benchmark
   for
   $$Ku = f$$
   with various libraries (Apple Accelerate, Cholmod and MUMPS).

All codes used to generate the results in this benchmark are available in my [cholbench-apple-arm](https://github.com/michalhabera/cholbench-apple-arm) repository. If you have an Apple Silicon Mac, I encourage you to clone the repository and run the benchmark yourself!

---

### CAD, mesh and matrix assembly

The clevis bracket is a mechanical part that is used to connect two components, with a base that is usuallly bolted to a surface and two wings perpendicular to the base. Drawing the clevis bracket in `build123d` is very simple, and it provides a nice [export-to-SVG](https://build123d.readthedocs.io/en/latest/import_export.html#d-exporters), see below the clevis bracket CAD model.

{{< figure src="/images/cholbench/clevis_bracket.svg" title="Figure 1" caption="3D CAD model of the clevis bracket generated in build123d." >}}

Once the CAD model is ready, `gmsh` meshes it at a range of sizes, from a coarse mesh with only a few thousand degrees of freedom up to a fine mesh approaching 1M degrees of freedom.

<div style="display: flex; flex-wrap: wrap; gap: 16px;">
  <div style="flex: 1; min-width: 250px;">
{{< figure src="/images/cholbench/clevis_coarse_mesh.png" title="Figure 2" caption="Coarse mesh of the clevis bracket." >}}
  </div>
  <div style="flex: 1; min-width: 250px;">
{{< figure src="/images/cholbench/clevis_fine_mesh.png" title="Figure 3" caption="Fine mesh of the clevis bracket." >}}
  </div>
</div>

The benchmark problem assembles the simplest linear elasticity problem

$$
\int_\Omega \sigma(u) : \epsilon(v) \, dx = \int_\Omega f \cdot v \, dx,
$$

for a piecewise [linear Lagrange finite element space](https://defelement.org/elements/examples/tetrahedron-lagrange-equispaced-1.html) on the tetrahedral cells of the mesh.

---

### Cholesky benchmarks

Benchmarking is difficult, especially when trying to be objective. There are always two extremes: either one tries to make all competitors have the same conditions, or one tries to make each competitor run the best version of it.
The former is disadvantageous for libraries with more parameters to tune and hardware specific optimization. The least I can do is to be transparent about the conditions of the benchmark, and provide the code to reproduce it.

There are three competitors in this benchmark:

1. [Apple Accelerate](https://developer.apple.com/documentation/accelerate), which is a proprietary library that comes with macOS and provides a sparse Cholesky factorization routine. It is optimized for Apple Silicon and uses the `sparse` framework,
2. [Cholmod](https://people.engr.tamu.edu/davis/suitesparse.html), open-source, part of the SuiteSparse collection, providing a supernodal sparse Cholesky factorization routine, and
3. [MUMPS](https://mumps-solver.org/index.php), a general purpose parallel multifrontal solver, which also provides a sparse Cholesky factorization.

Each library exposes a different amount of diagnostic detail about what it actually did under the hood, here is an overview of the versions and methods used:

|                 | Apple Accelerate                                             | CHOLMOD                       | MUMPS                    |
| --------------- | ------------------------------------------------------------ | ----------------------------- | ------------------------ |
| Version         | Command Line Tools SDK 26.5                                  | 5.3.1 (SuiteSparse 7.10.1)    | 5.8.2                    |
| Factorization   | Cholesky (`SparseFactorizationCholesky`)                     | \(LL^T\), supernodal (BLAS-3) | \(LDL^T\), SPD (`SYM=1`) |
| Ordering        | `SparseOrderDefault` (internal AMD/METIS-style, not exposed) | METIS                         | METIS                    |
| Integer indices | 64-bit column starts, 32-bit row indices                     | 64-bit                        | 32-bit                   |

Both MUMPS and CHOLMOD were installed using [pixi](https://pixi.prefix.dev/latest/), which is based on [conda](https://docs.conda.io/projects/conda/en/latest/index.html#).

On Apple ARM it is important to use the [Accelerate BLAS](https://developer.apple.com/documentation/accelerate/blas/), which for Level-3 work with high arithmetic intensity uses ARM's Scalable Matrix Extension (SME) for matrix-matrix SGEMM and DGEMM operations. These have a [measured](https://tnzr.org/sme/micro.html) peak arithemtic intestity of \(\approx 500\) Gflop/s for double precision. In single precision, the peak is \(\approx 2\) Tflop/s.

Another important aspect is the ordering used during the symbolic factorization phase. Apple Accelerate has an internal ordering, while for CHOLMOD and MUMPS I've made sure to use METIS. However, what I've observed, the number of nonzero factors in the factor matrix \(L\) is not the same. One should compute the ordering once,and provide it to both libraries, for fair comparison.

Use of threads is also a potential source of performance difference. I set the number of threads to what the hardware provides, which is 10 on my [Apple M4 Macbook](https://support.apple.com/en-us/121552). Thats how the results were obtained.

---

### Results and discussion

Fastest performing library for small (up to 100k degrees of freedom) problems is the Apple Accelerate. For larger problems, both MUMPS and CHOLMOD start to outperform the Accelerate. Since Accelerate does not expose the ordering, it is difficult to know if the performance difference is due to a better ordering or a better factorization routine. However, it is clear that OpenBLAS version of CHOLMOD is falling behind.

<figure>
  <iframe src="/images/cholbench/sweep_numeric.html" style="width: 100%; height: 400px; border: 0;" loading="lazy"></iframe>
  <figcaption><h4>Figure 4</h4><p>Numeric factorization time across the mesh sweep.</p></figcaption>
</figure>

<figure>
  <iframe src="/images/cholbench/sweep_total.html" style="width: 100%; height: 400px; border: 0;" loading="lazy"></iframe>
  <figcaption><h4>Figure 5</h4><p>Total solve time across the mesh sweep.</p></figcaption>
</figure>

When is comes to throughput, only MUMPS and CHOLMOD are reporting their estimates of flop count. When they both use Accelerate BLAS, throughput is increasing and reaches 250 Gflop/s for the largest problem benchmarked, but still far from the peak of 500 Gflop/s, not yet plateauing. As expected, OpenBLAS is not tuned for Apple Silicon and has throughput 3x lower then Accelerate BLAS.

<figure>
  <iframe src="/images/cholbench/sweep_throughput.html" style="width: 100%; height: 400px; border: 0;" loading="lazy"></iframe>
  <figcaption><h4>Figure 6</h4><p>Factorization throughput across the mesh sweep.</p></figcaption>
</figure>

### Caveats

I know, there are many. Few which I already mentioned, but here is the full list:

- the ordering is not the same for all libraries, and it is not exposed for Apple Accelerate,
- this uses `conda` builds. They are bundled for `osx-arm64`, but the builds might not be optimized for specific M4 microarchitecture,
- I used 10 threads. The M4 CPU has 10 cores of which only 4 are Performance and 6 are Efficiency. Apple Accelerate might be aware of this topology and schedule work differently than CHOLMOD and MUMPS,

In any case, if you have suggestions, or want to contribute, feel free to [open an issue](https://github.com/michalhabera/cholbench-apple-arm/issues) or send [me](/about) an email.
