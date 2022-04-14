# RNG Test Bench

## Brief Summary

Order of operations:

1. Generate a ~700MB file of random bytes for each generator, for each iteration.
2. Run `ent` on the file.
3. Run all specified `dieharder` tests on the file.
4. Burn ~5 billion bytes from each generator, for each iteration. Record the timings and calculate throughput.
5. Run one final suite of classical tests on the generator.

## Prerequisites

1. It needs to be run on a Linux system.
2. Make sure that `ent` and `dieharder` are installed.
3. Modify `.env.sample` to create an `.env` file. Then run `source .env` to load the environment variables.

## Usage

### Testing all generators

It is recommended to use `v -gc boehm -prod .` to compile the program.

Then run it using `time ./rng_testbench`

### Showing the summary/summaries

Just run `v run .`