# Group Velocity Simulations : Gridded

Script for collecting group velocity estimates by tx/rx location sets,
based on ICEX 2020 modem test navigation data, and BELLHOP for acoustic
propagation models. Results were run using two variants of the group
velocity estimate:

1. Original approach:
  - Related to Henrik's calculation in uSimModemNetwork.
  - This approach filters the arrival data from BELLHOP by prioritizing the
  least number of cumulative bounces available. Simulations showed some
  cases where the resulting one-way travel time disagreed significantly
  with the field measurement.
  - These results are given by `<env-name>-old.csv`, with the following headers:
    > `index , must_bnc , n_bnc , owtt , must_bnc0 , n_bnc0 , owtt0`
  - `owtt` is the 11x11 grid overall solution to the group velocity equation
  - `owtt0` is the single-point solution, for the vehicle location at the
  center of the grid

2. Expanded approach:
  - Rather than filtering the solution by enforcing the minimum number of
  cumulative bounces, the expanded approach evaluates up to 5 bounce
  scenarios by count, starting with the direct path arrivals, and moving
  up to a max of 4 bounces total.
  - These results are given by `<env-name>-gridded.csv` and `<env-name>-center.csv`,
    which capture the 11x11 grid solution and the single-point solution respectively.
  - The data headers convey the number of bounces for each column, as:
    > `index , owtt_0_bounce , ... , owtt_4_bounce`
