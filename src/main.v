module main

import os
import flag
import rand.splitmix64
import rand.wyrand
import rand.pcg32
import rand.sys
import rand.musl
import rand.mt19937
import myrngs.xoshiro
import time
import rand
import myrngs.nothing
import log
import rand.seed

const (
	// Experiment parameters
	parameters   = get_experiment_parameters()

	seed_len_map = {
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
	fp.application(name)
	fp.version(version)
	fp.description(description)
	fp.skip_executable()

	mode_str := fp.string('mode', `m`, 'report', 'The mode to run this program in. All valid modes are: ${program_modes.join(', ')}')

	additional_args := fp.finalize() or {
		println('Error: ' + err.str())
		println(fp.usage())
		exit(1)
	}

	if additional_args.len > 0 {
		println('Unprocessed arguments:\n${additional_args.join_lines()}')
	}

	timestamp := '(${time.now().format()})'

	match mode_str {
		'report' {
			// Run all the diagnostic functions before or after a full run

			// First, we check if we have any results to display already:
			summaries := os.walk_ext('results', 'csv')
			for summary in summaries {
				println('Contents of ${summary}: ')
				println(pretty_table_from_csv(summary)!)
			}

			dump(parameters)

			// Next, we try to send a sample email
			if parameters.api_key != 'unset_api_key' {
				send_test_mail()!
			}
		}
		'runall' {
			println('Running all!')

			run_for_all_generators(timestamp)!

			if parameters.api_key != 'unset_api_key' {
				send_detail_report_mail(timestamp)!
			}
		}
		'burn' {
			println('Measuring throughput of all enabled generators...')

			run_burn_for_all_generators(timestamp)!

			if parameters.api_key != 'unset_api_key' {
				send_detail_report_mail(timestamp)!
			}
		}
		else {
			println('Invalid mode!')
			println(fp.usage())
			exit(1)
		}
	}
}

fn initialize_directories() {
	keep := ['results']
	directories := ['data', 'results', 'logs']

	for directory in directories {
		if directory !in keep {
			if !parameters.keep_data {
				os.rmdir_all(directory) or {}
			}
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
		ExternalTool{
			name: 'zip'
			command: 'zip --help'
		},
	]

	for tool in tools {
		result := os.execute(tool.command)
		if result.exit_code != 0 {
			println('External tool "${tool.name}" could not be detected. Please install it.')
			exit(1)
		}
	}
}

fn run_for_all_generators(timestamp string) ! {
	mut contexts := map[string]&EvaluationContext{}

	for iteration in 1 .. (parameters.iterations + 1) {
		local_generators := rand.shuffle_clone(enabled_generators) or {
			return error('Internal error: could not shuffle array. Please file a bug report.')
		}

		mut evaluation_threads := []thread{}

		for name in local_generators {
			mut context := &EvaluationContext{
				name: name
				iteration: iteration
				rng: new_generator(name)!
				logger: obtain_logger(name, iteration)
			}
			contexts['${name}_${iteration}'] = context

			evaluation_threads << spawn fn (mut context EvaluationContext) {
				initialize_rng(mut context) or {
					panic('An error occurred while trying to initialise: ${context.name}#${context.iteration}')
				}
				generate_data_file(mut context) or {
					panic('An error occurred while trying to generate data file: ${context.name}#${context.iteration}')
				}

				evaluate_rng_file(mut context)

				store_burn_results(mut context)

				store_classic_test_results(mut context)
			}(mut context)
		}

		evaluation_threads.wait()

		if !parameters.keep_data {
			os.rmdir_all('data') or {}
			os.mkdir('data') or {}
		}
	}
	generate_report(contexts, timestamp)
}

fn run_burn_for_all_generators(timestamp string) ! {
	mut contexts := map[string]&EvaluationContext{}

	for iteration in 1 .. (parameters.iterations + 1) {
		local_generators := rand.shuffle_clone(enabled_generators) or {
			return error('Internal error: could not shuffle array. Please file a bug report.')
		}

		mut evaluation_threads := []thread{}

		for name in local_generators {
			mut context := &EvaluationContext{
				name: name
				iteration: iteration
				rng: new_generator(name)!
				logger: obtain_logger(name, iteration)
			}
			contexts['${name}_${iteration}'] = context

			evaluation_threads << spawn fn (mut context EvaluationContext) {
				initialize_rng(mut context) or {
					panic('An error occurred while trying to initialise: ${context.name}#${context.iteration}')
				}
				store_burn_results(mut context)
				context.logger.flush()
			}(mut context)
		}
		evaluation_threads.wait()
	}

	output_options := OutputOptions{
		report_ent: false
		report_dhr: false
		report_classic: false
	}

	generate_report(contexts, timestamp, output_options)
}

fn new_generator(name string) !&rand.PRNG {
	return match name {
		'musl' {
			&rand.PRNG(&musl.MuslRNG{})
		}
		'pcg32' {
			&rand.PRNG(&pcg32.PCG32RNG{})
		}
		'mt19937' {
			&rand.PRNG(&mt19937.MT19937RNG{})
		}
		'wyrand' {
			&rand.PRNG(&wyrand.WyRandRNG{})
		}
		'splitmix' {
			&rand.PRNG(&splitmix64.SplitMix64RNG{})
		}
		'xoshiro' {
			&rand.PRNG(&xoshiro.X256PlusPlusRNG{})
		}
		'sysrng' {
			&rand.PRNG(&sys.SysRNG{})
		}
		'nothing' {
			&rand.PRNG(&nothing.NothingRNG{})
		}
		else {
			return error('Unsupported generator: ${name}')
		}
	}
}

fn initialize_rng(mut context EvaluationContext) ! {
	seed_len := seed_len_map[context.name]
	if seed_len > 0 {
		seed_data := seed.time_seed_array(seed_len)
		context.rng.seed(seed_data)
		context.logger.info('Seeded ${context.name}#${context.iteration:02} with ${seed_data}')
	}
}

fn obtain_logger(name string, iteration u64) &log.Log {
	mut logger := &log.Log{
		level: .info
		output_label: '${name}${iteration:02}.log'
	}

	logger.set_output_path('logs')
	logger.log_to_console_too()

	return logger
}

fn default_system_name() string {
	details := os.uname()
	return '${details.sysname}_${details.machine}'
}
