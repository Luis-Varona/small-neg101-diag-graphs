# Small {-1,0,1}-Diagonalizable Graphs: A Computational Survey

![License: MIT](https://img.shields.io/badge/License-MIT-pink.svg)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/JuliaDiff/BlueStyle)
[![DOI](https://zenodo.org/badge/1239328776.svg)](https://doi.org/10.5281/zenodo.21114288)

This is a computational survey of small $\\{-1,0,1\\}$-diagonalizable (and Laplacian integral) graphs for the paper "Enumeration of Laplacian integral and $\\{-1,0,1\\}$-diagonalizable graphs" by Nathaniel Johnston, Sarah Plosker, and Luis M. B. Varona.

Code used to generate this data is present in `src/`, computational results are stored in Apache Arrow format in `data/`, and the job scripts used to run this survey on the Nibi cluster at the University of Waterloo are present in `jobs/`. (The `benchmarks/` directory contains, for convenient reference, records of walltime and RAM required to run said jobs.)

`data/3_regular_diagonalizations.txt` contains data on 3-regular $\\{-1,0,1\\}$-diagonalizable of select graphs independently produced by Nathaniel Johnston using similar computational methods, also referenced by the paper.

The authors thank Matthew Betti and the Digital Research Alliance of Canada for providing computational resources that were necessary to carry out this work.
