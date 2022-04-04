module main

import os
import rand
import rand.musl
import rand.pcg32
import rand.wyrand
import rand.splitmix64
// import myrngs.cryptorng

const (
	iterations            = 10
	data_file_bytes_count = 1024 * 1024 * 1024
	seed_len_map          = {
		'musl':     musl.seed_len
		'pcg32':    pcg32.seed_len
		'wyrand':   2
		'splitmix': splitmix64.seed_len
	}
)

fn main() {
	initialize_directories()
	check_external_programs_installed()

	mut generators := {
		'musl':     &rand.PRNG(&musl.MuslRNG{})
		'pcg32':    &rand.PRNG(&pcg32.PCG32RNG{})
		// Implementation issues. Enable after fix
		// 'mt19937': &rand.PRNG(&mt19937.MT19937RNG{})
		'wyrand':   &rand.PRNG(&wyrand.WyRandRNG{})
		'splitmix': &rand.PRNG(&splitmix64.SplitMix64RNG{})
		// This takes a long time to run, so use smaller sizes on this
		// 'crypto':   &rand.PRNG(&cryptorng.CryptoRNG{})
	}

	iteration_limit := iterations + 1

	mut threads := []thread{}

	for name in generators.keys() {
		for iteration in 1 .. iteration_limit {
			mut context := &EvaluationContext{
				name: name
				iteration: iteration
				rng: generators[name]
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

struct ExternalTool {
	name    string
	command string
}

fn check_external_programs_installed() {
	tools := [
		ExternalTool{
			name: 'ent'
			command: 'ent -u'
		},
		ExternalTool{
			name: 'dieharder'
			command: 'dieharder --help'
		},
	]

	for tool in tools {
		result := os.execute(tool.command)
		if result.exit_code != 0 {
			panic('External tool "$tool.name" could not be detected.')
		}
	}
}
