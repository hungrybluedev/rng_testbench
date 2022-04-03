module main

import os
import rand
import rand.musl
import rand.wyrand
import rand.splitmix64
import cryptorng

const (
	iterations            = 2
	data_file_bytes_count = 2_000_000
)

fn main() {
	initialize_directories()
	check_external_programs_installed()

	mut generators := {
		'musl':     &rand.PRNG(&musl.MuslRNG{})
		'wyrand':   &rand.PRNG(&wyrand.WyRandRNG{})
		'splitmix': &rand.PRNG(&splitmix64.SplitMix64RNG{})
		'crypto':   &rand.PRNG(&cryptorng.CryptoRNG{})
	}

	iteration_limit := iterations + 1

	mut threads := []thread{}

	for name in generators.keys() {
		for iteration in 1 .. iteration_limit {
			mut context := &EvaluationContext{
				name: name
				iteration: iteration
				rng: mut generators[name]
			}
			threads << go evaluate_rng(mut context)
		}
	}

	threads.wait()
}

fn initialize_directories() {
	directories := ['data', 'results', 'logs']

	for directory in directories {
		os.rmdir_all(directory) or {}
		os.mkdir(directory) or {}
	}
}

fn check_external_programs_installed() {
	commands := ['ent -u', 'dieharder --help']

	for command in commands {
		result := os.execute(command)
		if result.exit_code != 0 {
			panic('External command "$command" could not be run.')
		}
	}
}
