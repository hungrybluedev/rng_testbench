module main

import os
import time

struct DieHarderTestCase {
	number      int
	description string
}

const dieharder_test_cases = [
	DieHarderTestCase{
		number: 0
		description: 'Diehard "Birthdays" test (modified)'
	},
	DieHarderTestCase{
		number: 1
		description: 'Diehard Overlapping 5-Permutations Test'
	},
	DieHarderTestCase{
		number: 2
		description: 'Diehard 32x32 Binary Rank Test'
	},
	DieHarderTestCase{
		number: 3
		description: 'Diehard 6x8 Binary Rank Test'
	},
	DieHarderTestCase{
		number: 4
		description: 'Diehard Bitstream Test'
	},
	DieHarderTestCase{
		number: 5
		description: 'Diehard Overlapping Pairs Sparse Occupancy (OPSO)'
	},
	DieHarderTestCase{
		number: 6
		description: 'Diehard Overlapping Quadruples Sparse Occupancy (OQSO) Test'
	},
	DieHarderTestCase{
		number: 7
		description: 'Diehard DNA Test'
	},
	DieHarderTestCase{
		number: 8
		description: 'Diehard Count the 1s (stream) (modified) Test'
	},
	DieHarderTestCase{
		number: 9
		description: 'Diehard Count the 1s (byte) (modified) Test'
	},
	DieHarderTestCase{
		number: 10
		description: 'Diehard Parking Lot Test (modified)'
	},
	DieHarderTestCase{
		number: 11
		description: 'Diehard Minimum Distance (2d Circle) Test'
	},
	DieHarderTestCase{
		number: 12
		description: 'Diehard Minimum Distance (3d Sphere) Test'
	},
	DieHarderTestCase{
		number: 13
		description: 'Diehard Squeeze Test'
	},
	DieHarderTestCase{
		number: 15
		description: 'Diehard Runs Test'
	},
	DieHarderTestCase{
		number: 16
		description: 'Diehard Craps Test'
	},
	DieHarderTestCase{
		number: 100
		description: 'STS Monobit Test'
	},
	DieHarderTestCase{
		number: 101
		description: 'STS Runs Test'
	},
	DieHarderTestCase{
		number: 202
		description: 'RGB Permutations Test'
	},
	DieHarderTestCase{
		number: 203
		description: 'RGB Lagged Sum Test'
	},
	DieHarderTestCase{
		number: 204
		description: 'RGB Kolmogorov-Smirnov Test'
	},
	DieHarderTestCase{
		number: 205
		description: 'DAB Byte Distribution Test'
	},
	DieHarderTestCase{
		number: 206
		description: 'DAB DCT Test'
	},
	DieHarderTestCase{
		number: 209
		description: 'DAB Monobit 2 Test'
	},
]

fn store_dieharder_results(mut context EvaluationContext) {
	mut sw := time.new_stopwatch()

	for test_case in dieharder_test_cases {
		cmd := 'dieharder -g 201 -f ${context.data_file} -d ${test_case.number}'
		context.logger.info('run dieharder with: ${cmd}')
		result := os.execute_or_panic(cmd)
		context.logger.info('Parsing dieharder result for ${test_case.description}...')

		lines := result.output.split_into_lines()

		if lines.len < 9 {
			for idx, line in lines {
				context.logger.info('> line ${idx}: ${line}')
			}
			context.logger.fatal('Unexpected output from dieharder')
		}

		result_lines := lines.filter(it.contains('PASSED') || it.contains('FAILED')
			|| it.contains('WEAK'))

		for result_line in result_lines {
			tokens := result_line.split('|').map(it.trim(' '))
			p_value := tokens[4].f64()
			outcome := tokens[5]

			context.logger.info(result_line)
			if outcome == 'PASSED' {
				context.logger.info('${test_case.description}: PASSED (${p_value})')
				context.dhr_pass += 1
			} else {
				context.logger.warn('${test_case.description}: ${outcome} (${p_value})')
				for output_line in lines {
					context.logger.warn(output_line)
				}
				if outcome == 'WEAK' {
					context.dhr_weak += 1
				} else {
					context.dhr_fail += 1
				}
			}
		}
	}

	context.dhr_duration = sw.elapsed()

	context.logger.info('Dieharder test suite took ${context.dhr_duration.seconds()} seconds')

	context.logger.info('dhr pass: ${context.dhr_pass}')
	context.logger.info('dhr weak: ${context.dhr_weak}')
	context.logger.info('dhr fail: ${context.dhr_fail}')

	score := 2 * context.dhr_pass + context.dhr_weak - 2 * context.dhr_fail
	context.logger.info('dhr score: ${score}')
	context.dhr_score = score
}
