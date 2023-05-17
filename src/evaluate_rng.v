module main

import time
import log
import rand

struct EvaluationContext {
	name        string
	iteration   u64
	buffer_size int = parameters.default_block_size
mut:
	logger        &log.Log
	rng           &rand.PRNG
	data_file     string
	ent_norm      f64
	dhr_pass      int
	dhr_weak      int
	dhr_fail      int
	dhr_score     int
	ent_duration  time.Duration
	dhr_duration  time.Duration
	burn_duration time.Duration
	chisq_pass    int
	kolsmir_pass  int
	serial_pass   int
	classic_score int
	classic_count int
}

fn evaluate_rng_file(mut context EvaluationContext) {
	store_entropy_results(mut context)
	if context.ent_norm < 1.0 {
		store_dieharder_results(mut context)
	}
}
