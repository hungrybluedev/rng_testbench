module main

import log
import math
import rand
import rand.seed
import os

struct EvaluationContext {
	name        string
	iteration   int
	buffer_size int = 2048
mut:
	logger    log.Log
	rng       rand.PRNG
	data_file string
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

fn evaluate_rng(mut context EvaluationContext) {
	context.logger = obtain_logger(context.name, context.iteration)

	seed_len := context.rng.block_size() / 32
	if seed_len > 0 {
		seed_data := seed.time_seed_array(seed_len)
		context.rng.seed(seed_data)
		context.logger.info('Seeded $context.name#${context.iteration:02} with $seed_data')
	}

	generate_data_file(mut context)

	store_entropy_results(mut context)
}

fn generate_data_file(mut context EvaluationContext) {
	file_path := 'data/$context.name${context.iteration:02}.dat'
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

fn store_entropy_results(mut context EvaluationContext) {
	result := os.execute_or_panic('ent $context.data_file')
	context.logger.info('Parsing entropy result...')

	lines := result.output.split_into_lines()

	if lines.len != 11 {
		context.logger.fatal('Unexpected output from ent')
	}

	entropy_value := lines[0][10..].split(' ')[0].f64()
	compression_value := lines[3].split(' ')[6].f64()
	chi_square_value := lines[5].split_any(' ,')[7].f64()
	p_value := lines[6].split(' ')[4].f64() / 100.0
	mean_value := lines[8].split(' ')[7].f64()
	pi_error_value := lines[9].split(' ')[8].f64()
	corr_coef_value := lines[10].split(' ')[4].f64()

	context.logger.info('Entropy per byte: $entropy_value')
	context.logger.info('Compressibility: $compression_value')
	context.logger.info('Chi Square: $chi_square_value')
	context.logger.info('p-value: $p_value')
	context.logger.info('Mean: $mean_value')
	context.logger.info('MC Pi error: $pi_error_value')
	context.logger.info('Correlation coefficient: $corr_coef_value')

	norm := math.sqrt(math.pow(8 - entropy_value, 2) +
		if p_value < 0.05 || p_value > 0.95 { 1 } else { 0 } +
		math.pow(math.abs(mean_value - 127.5) / 127.5, 2) + math.pow(pi_error_value / 100.0, 2) +
		math.abs(corr_coef_value))

	if norm >= 1.0 {
		context.logger.warn('ent vector norm: $norm')
	} else {
		context.logger.info('ent vector norm: $norm')
	}
}
