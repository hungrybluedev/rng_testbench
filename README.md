# RNG Test Bench

## Brief Summary

Order of operations:

1. Generate a ~700MB file of random bytes for each generator, for each
   iteration.
2. Run `ent` on the file.
3. Run all specified `dieharder` tests on the file if `ent` passes.
4. Burn 5 billion bytes from each generator, for each iteration. Record the
   timings and calculate throughput.
5. Run one final suite of classical tests on the generator.

## Prerequisites

1. It needs to be run on a system that can install `ent` and `dieharder`.
   `time` is also recommended, but not necessary.
2. Install `ent` and `dieharder` from the package manager if available.
   Otherwise, refer to their respective repositories:
   [ent](https://github.com/jj1bdx/ent) and
   [dieharder](https://github.com/seehuhn/dieharder).
3. Optionally create a config.toml file based on the sample provided if
   any of the settings need to be changed.

## Usage

### Testing all generators

Uncomment the required generators in the `enabled_generators` array in
`rng_testbench.v`.

It is recommended to use `v -prod .` to compile the program.

Then run it using `time ./rng_testbench --mode runall`

**NOTE:** If all iterations are set, each RNG takes over 10 minutes to test
(using `-prod`).

If the email API key is set, it will attempt to send an email after the test
has concluded.

### Showing the summary/summaries

Just run `v run .` after at least one test is run.
