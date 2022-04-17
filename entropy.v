module main

import math
import os
import time

fn store_entropy_results(mut context EvaluationContext) {
	mut sw := time.new_stopwatch()

	cmd := 'ent $context.data_file'
	context.logger.info('Running ent: $cmd')
	result := os.execute_or_panic(cmd)

	context.ent_duration = sw.elapsed()

	context.logger.info('Entropy calculation took $context.ent_duration.seconds() seconds')
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

	context.ent_norm = norm
}
