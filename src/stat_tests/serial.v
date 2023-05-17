module stat_tests

import math
import rand
import util

const serial_bins = 16

fn get_next_bin(mut rng rand.PRNG, skip util.InputType) int {
	return int(f64(util.next(mut rng, skip)) / 256.0 * f64(stat_tests.serial_bins))
}

pub fn serial_chi_sq_val(mut rng rand.PRNG, n int, skip util.InputType) f64 {
	mut b := []int{len: stat_tests.serial_bins * stat_tests.serial_bins}

	p := 1.0 / f64(stat_tests.serial_bins * stat_tests.serial_bins)

	for _ in 0 .. n {
		b0 := get_next_bin(mut rng, skip)
		b1 := get_next_bin(mut rng, skip)
		b[b0 * stat_tests.serial_bins + b1]++
	}

	mut v := 0.0
	np := f64(n) * p

	for f in b {
		v += math.pow(f64(f) - np, 2) / np
	}

	return v
}

pub fn serial_chi_sq_p(value f64) f64 {
	return chi_square_p(value, stat_tests.serial_bins * stat_tests.serial_bins - 1)
}
