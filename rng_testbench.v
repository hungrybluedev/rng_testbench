module main

import os
import flag
import time
import rand
import rand.musl
import rand.pcg32
import rand.wyrand
import rand.splitmix64
// import myrngs.cryptorng

const (
	// Experiment parameters
	iterations            = (os.getenv_opt('EXPERIMENT_ITERATIONS') or { '1' }).int()
	data_file_bytes_count = (os.getenv_opt('EXPERIMENT_FILE_SIZE') or { '2048' }).int()
	default_block_size    = (os.getenv_opt('EXPERIMENT_BLOCK_SIZE') or { '2048' }).int()

	// Mail Notification parameters
	from_email            = os.getenv_opt('MAIL_FROM') or { panic('Please set the sender email.') }
	recipients            = os.getenv_opt('MAIL_TO') or {
		panic('Please set the recipient email(s).')
	}
	api_key               = os.getenv_opt('MAIL_API_KEY') or {
		panic('Please an environment variable: MAIL_API_KEY')
	}

	seed_len_map          = {
		'musl':     musl.seed_len
		'pcg32':    pcg32.seed_len
		'wyrand':   2
		'splitmix': splitmix64.seed_len
	}
	enabled_generators = [
		'musl',
		'pcg32',
		'wyrand',
		'splitmix',
		// 'cryptorng',
	]
	program_modes      = [
		'default',
		'runall',
		'target',
	]
)

fn main() {
	initialize_directories()
	check_external_programs_installed()

	mut fp := flag.new_flag_parser(os.args)
	fp.application('rng_testbench')
	fp.version('0.0.1')
	fp.description('A reliable CLI utility to measure the performance of various random number generators.')
	fp.skip_executable()

	mode_str := fp.string('mode', `m`, 'default', 'The mode to run this program in. All valid modes are: ${program_modes.join(', ')}')

	generator_str := fp.string('generator', `g`, 'all', 'The generator to use. All valid generators are: ${enabled_generators.join(', ')}, all')

	additional_args := fp.finalize() ?

	if additional_args.len > 0 {
		println('Unprocessed arguments:\n$additional_args.join_lines()')
	}

	match mode_str {
		'default' {
			println(pretty_table_from_csv('results/summary.csv') ?)
		}
		'runall' {
			println('Running all!')

			timestamp := '($time.now().format())'

			run_for_all_generators(timestamp)
			send_mail(timestamp) ?
		}
		'target' {
			println('Running target!')
		}
		else {
			println('Invalid mode!')
		}
	}

	println(generator_str)
}

fn run_for_all_generators(timestamp string) {
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

	mut contexts := map[string]&EvaluationContext{}

	for iteration in 1 .. iteration_limit {
		for name in enabled_generators {
			mut context := &EvaluationContext{
				name: name
				iteration: iteration
				rng: generators[name]
			}
			contexts['${name}_$iteration'] = context
			initialize_rng_data(mut context)
		}
	}

	mut evaluation_threads := []thread{}

	for name in enabled_generators {
		for iteration in 1 .. iteration_limit {
			evaluation_threads << go evaluate_rng(mut contexts['${name}_$iteration'])
		}
	}

	evaluation_threads.wait()

	generate_report(contexts, timestamp)
}

fn initialize_directories() {
	keep := ['results']
	directories := ['data', 'results', 'logs']

	for directory in directories {
		if directory !in keep {
			os.rmdir_all(directory) or {}
		}
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
