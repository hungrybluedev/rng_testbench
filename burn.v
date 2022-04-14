module main

import time

fn store_burn_results(mut context EvaluationContext) {
	mut sw := time.new_stopwatch()

	for _ in 0 .. burn_iterations {
		context.rng.byte()
	}

	context.burn_duration = sw.elapsed()

	context.logger.info('Burning $burn_iterations bytes took $context.burn_duration.seconds() seconds')
}
