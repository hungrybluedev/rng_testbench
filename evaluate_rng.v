module main

import log
import os
import rand
import rand.seed
import time

struct EvaluationContext {
	name        string
	iteration   int
	buffer_size int = default_block_size
mut:
	logger        log.Log
	rng           rand.PRNG
	data_file     string
	ent_norm      f64
	dhr_pass      int
	dhr_weak      int
	dhr_fail      int
	dhr_score     int
	ent_duration  time.Duration
	dhr_duration  time.Duration
	burn_duration time.Duration
}

fn obtain_logger(name string, iteration int) log.Log {
	mut logger := log.Log{
		level: .info
		output_label: '$name${iteration:02}.log'
	}

	logger.set_output_path('logs')
	logger.log_to_console_too()

	return logger
}

fn initialize_rng_data(mut context EvaluationContext) {
	context.logger = obtain_logger(context.name, context.iteration)

	seed_len := seed_len_map[context.name]
	if seed_len > 0 {
		seed_data := seed.time_seed_array(seed_len)
		context.rng.seed(seed_data)
		context.logger.info('Seeded $context.name#${context.iteration:02} with $seed_data')
	}

	generate_data_file(mut context)
}

fn evaluate_rng(mut context EvaluationContext) {
	store_entropy_results(mut context)
	store_dieharder_results(mut context)
	store_burn_results(mut context)
}

fn generate_data_file(mut context EvaluationContext) {
	file_path := 'data/${context.name}_${context.iteration:02}.dat'
	context.data_file = file_path

	mut data_file := os.open_append(file_path) or {
		context.logger.fatal('Could not open $file_path for writing')
		return
	}
	context.logger.info('Writing data to $file_path')

	mut bytes_remaining := data_file_bytes_count

	for bytes_remaining > 0 {
		mut byte_data := context.rng.bytes(if bytes_remaining > context.buffer_size {
			context.buffer_size
		} else {
			bytes_remaining
		}) or {
			context.logger.fatal('Failed to generate data')
			exit(1)
		}

		bytes_remaining -= data_file.write(byte_data) or {
			context.logger.fatal('Failed to write data')
			exit(1)
		}
	}

	context.logger.info('Wrote $data_file_bytes_count bytes to $file_path')

	data_file.close()
}
