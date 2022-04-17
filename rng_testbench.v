module main

import os
import flag
import time
import rand
import rand.mt19937
import rand.musl
import rand.pcg32
import rand.wyrand
import rand.splitmix64
import rand.sys
// import myrngs.cryptorng
// import myrngs.minstd
import myrngs.xoshiro
import myrngs.nothing

const (
	// Experiment parameters
	iterations            = (os.getenv_opt('EXPERIMENT_ITERATIONS') or { '4' }).u64()
	iteration_limit       = iterations + 1
	data_file_bytes_count = (os.getenv_opt('EXPERIMENT_FILE_SIZE') or { '2048' }).int()
	default_block_size    = (os.getenv_opt('EXPERIMENT_BLOCK_SIZE') or { '4096' }).int()

	// Mail Notification
	system_name           = os.getenv_opt('SYSTEM_NAME') or { default_system_name() }
	from_email            = os.getenv_opt('MAIL_FROM') or { 'unset_from_email' }
	recipients            = os.getenv_opt('MAIL_TO') or { 'unset_recipients' }
	api_key               = os.getenv_opt('MAIL_API_KEY') or { 'unset_api_key' }

	// Burn parameters
	burn_iterations       = (os.getenv_opt('EXPERIMENT_BURN_ITERATIONS') or { '5000000' }).u64()

	// Tail end test parameters
	classic_iterations    = (os.getenv_opt('EXPERIMENT_CLASSIC_ITERATIONS') or { '100000' }).int()

	seed_len_map          = {
		'mt19937':  mt19937.seed_len
		'musl':     musl.seed_len
		'sysrng':   sys.seed_len
		'pcg32':    pcg32.seed_len
		'wyrand':   wyrand.seed_len
		'splitmix': splitmix64.seed_len
		'xoshiro':  xoshiro.seed_len
	}
	enabled_generators = [
		'mt19937',
		'musl',
		'sysrng',
		'pcg32',
		'wyrand',
		'splitmix',
		'xoshiro',
		'nothing',
	]
	program_modes      = [
		'report',
		'runall',
		'burn',
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

	mode_str := fp.string('mode', `m`, 'report', 'The mode to run this program in. All valid modes are: ${program_modes.join(', ')}')

	additional_args := fp.finalize() or {
		println('Error: ' + err.str())
		println(fp.usage())
		exit(1)
	}

	if additional_args.len > 0 {
		println('Unprocessed arguments:\n$additional_args.join_lines()')
	}

	mut generators := {
		'musl':     &rand.PRNG(&musl.MuslRNG{})
		'pcg32':    &rand.PRNG(&pcg32.PCG32RNG{})
		// Implementation issues. Enable after fix
		'mt19937':  &rand.PRNG(&mt19937.MT19937RNG{})
		'wyrand':   &rand.PRNG(&wyrand.WyRandRNG{})
		'splitmix': &rand.PRNG(&splitmix64.SplitMix64RNG{})
		// This takes a long time to run, so use smaller sizes on this
		// 'crypto':   &rand.PRNG(&cryptorng.CryptoRNG{})
		'xoshiro':  &rand.PRNG(&xoshiro.X256PlusPlusRNG{})
		'sysrng':   &rand.PRNG(&sys.SysRNG{})
		'nothing':  &rand.PRNG(&nothing.NothingRNG{})
	}

	timestamp := '($time.now().format())'

	match mode_str {
		'report' {
			// Run all the diagnostic functions before or after a full run

			// First, we check if we have any results to display already:
			summaries := os.walk_ext('results', 'csv')
			for summary in summaries {
				println('Sample summary table output: ')
				println(pretty_table_from_csv(summary) ?)
			}

			// Next, we try to send a sample email
			if api_key != 'unset_api_key' {
				send_test_mail() ?
			}
		}
		'runall' {
			println('Running all!')

			run_for_all_generators(generators, timestamp)

			if api_key != 'unset_api_key' {
				send_detail_report_mail(timestamp) ?
			}
		}
		'burn' {
			println('Measuring throughput of all enabled generators...')

			run_burn_for_all_generators(generators, timestamp)

			if api_key != 'unset_api_key' {
				send_detail_report_mail(timestamp) ?
			}
		}
		else {
			println('Invalid mode!')
			println(fp.usage())
			exit(1)
		}
	}
}

fn run_for_all_generators(generators map[string]&rand.PRNG, timestamp string) {
	mut contexts := map[string]&EvaluationContext{}

	for name in enabled_generators {
		for iteration in 1 .. iteration_limit {
			mut context := &EvaluationContext{
				name: name
				iteration: iteration
				rng: generators[name]
			}
			contexts['${name}_$iteration'] = context
			initialize_rng_data(mut context)
			generate_data_file(mut context)
		}

		mut evaluation_threads := []thread{}

		for iteration in 1 .. iteration_limit {
			evaluation_threads << go evaluate_rng_file(mut contexts['${name}_$iteration'])
		}

		evaluation_threads.wait()

		for iteration in 1 .. iteration_limit {
			store_burn_results(mut contexts['${name}_$iteration'])
		}

		for iteration in 1 .. iteration_limit {
			store_classic_test_results(mut contexts['${name}_$iteration'])
		}

		os.rmdir_all('data') or {}
		os.mkdir('data') or {}
	}

	generate_report(contexts, timestamp)
}

fn run_burn_for_all_generators(generators map[string]&rand.PRNG, timestamp string) {
	mut contexts := map[string]&EvaluationContext{}

	for name in enabled_generators {
		for iteration in 1 .. iteration_limit {
			mut context := &EvaluationContext{
				name: name
				iteration: iteration
				rng: generators[name]
			}
			contexts['${name}_$iteration'] = context
			initialize_rng_data(mut context)
		}

		for iteration in 1 .. iteration_limit {
			store_burn_results(mut contexts['${name}_$iteration'])
		}
	}

	output_options := OutputOptions{
		report_ent: false
		report_dhr: false
		report_classic: false
	}

	generate_report(contexts, timestamp, output_options)
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

fn default_system_name() string {
	details := os.uname()
	return '${details.sysname}_$details.machine'
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
		ExternalTool{
			name: 'zip'
			command: 'zip --help'
		},
	]

	for tool in tools {
		result := os.execute(tool.command)
		if result.exit_code != 0 {
			panic('External tool "$tool.name" could not be detected.')
		}
	}
}
