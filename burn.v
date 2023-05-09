module main

import time

fn store_burn_results(mut context EvaluationContext) {
	mut sw := time.new_stopwatch()

	for _ in 0 .. burn_iterations {
		context.rng.u8()
	}

	context.burn_duration = sw.elapsed()

	context.logger.info('Burning ${burn_iterations} bytes took ${context.burn_duration.seconds()} seconds')

	output := context.rng.string(10)
	context.logger.info('Sample string after burn: ${output}')
}
