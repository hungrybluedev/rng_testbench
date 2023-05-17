module stat_tests

import rand
import util
import math

const (
	e_max   = 100
	e_max_f = f64(e_max)
)

pub fn kolsmir(mut rng rand.PRNG, n int, skip util.InputType) (f64, f64) {
	mut z := [stat_tests.e_max]int{}
	mut ps := []f64{cap: n}

	for _ in 0 .. n {
		ps << f64(util.next(mut rng, skip)) / 256.0
	}

	for i in 0 .. stat_tests.e_max {
		for p in ps {
			if p <= (f64(i) / stat_tests.e_max_f) {
				z[i]++
			}
		}
	}

	mut dp := -1.0
	mut dm := -1.0

	for i in 0 .. stat_tests.e_max {
		d := (f64(z[i]) / f64(n)) - (f64(i) / stat_tests.e_max_f)
		if d > 0 {
			dp = math.max(dp, d)
		}
		if d < 0 {
			dm = math.max(dm, math.abs(d))
		}
	}

	sqrt_n := math.sqrt(f64(n))

	return dp * sqrt_n, dm * sqrt_n
}
