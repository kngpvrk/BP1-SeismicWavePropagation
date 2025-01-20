# Simulation of Seismic Wave Propagation in 2D Elastic Media

## Introduction and Background 📌

This code simulates two-dimensional seismic wave propagation in an elastic medium by employing numerical modeling to analyze wave behavior in a geophysical setting. 
Furthermore, it computes displacement time series at the surface and constructs synthetic seismograms for stations located at varying distances from the source. 
Additionally, it identifies the peaks of P- and S-wave arrivals and calculates their velocities based on the seismograms, comparing them with theoretical values.

### Progamming Tools 

The programming language *Julia* and the *Visual Studio Code editor* were utilized for this purpose. For the visualization, the Julia package *Plots* and *Pyplot*
were used to create graphical plots of the simulation results, while the *Measure* package allowed the customization of the plot layouts.

### Finite Element Method 

The *finite element method* (FEM) was uitilized for the modeling of seismic wave propagation, which allowed the division of the system into discrete
parts, allowing continuous physical equations to be solved numerically.  

### Boundary Conditions

In this project, the *Neuman Boundary Conditions* were applied to define the behavior at the edges of the local domain. These conditions ensure 
zero particle velocity across the edges and as a result confine the wavefield within the domain.

### Initialization of Wave Propagation

The *Gaussian function* was employed to represent a localized disturbance in terms of pressure P and stress τ. This function simulates a disturbance with energy 
source that is both localized and smoothly distributed.

### Time Integration

The 'Courant-Friedrichs-Lewy (CFL)' condition is used, which is a stability criterion for numerical simulations of partial differential equations. By keeping the 
appropriate ratio of the time step to the spatial resolution, it prevents the numerical solution from becoming unstable as it exceeds the relation of order 
of system’s maximum wave speed.

### Synthetic Seismograms

The finite-difference method was employed to update the wave equation velocities and stresses at each time step. Hereby, the values are computed for each grid
cell as time progresses and the average horizontal velocity is extracted from the grid cell, closest to the station. Instantaneous displacements were computed,
by multiplying the velocity by the time step.

## Limitations 📌

While this simulation successfully demonstrates the propagation of elastic seismic waves in a simplified, homogeneous domain, it has many limitations:

- <u>Numerical Artifacts</u> such as distorted wave velocities and arrival times are introduced by numerical dispersion, coarse grid resolution,
  and reflective boundaries.
- <u>Simplistic Assumptions</u> of a homogeneous elastic medium oversimplify the real-world geology: doesn't account for heterogeneities, anisotropy, and layering.
- <u>Restriction to two Dimensions</u> limits application to real-world seismic events, which occur in three dimensions.

 Despite these limitations, the simulation offers a valuable framework for understanding seismic wave behavior under idealized conditions. 

 ## How to Use 📌


