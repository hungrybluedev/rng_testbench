module stat_tests

import math
import rand
import util

pub fn chi_square_value(mut rng rand.PRNG, n int, skip util.InputType) f64 {
	mut bins := [256]int{}

	for _ in 0 .. n {
		bins[util.next(mut rng, skip)]++
	}

	mut v := 0.0
	p := 1.0 / 256.0
	np := f64(n) * p

	for frequency in bins {
		v += math.pow(frequency - np, 2) / np
	}

	return v
}

pub fn chi_square_p(cv f64, dof int) f64 {
	k := f64(dof) / 2.0
	x := cv / 2.0

	if (cv < 0) || dof < 1 {
		return 0.0
	}
	if dof == 2 {
		return math.exp(-x)
	}
	return igf(k, x) / math.gamma(k)
}

fn igf(k f64, x f64) f64 {
	mut s := k
	mut z := x
	mut sc := 1.0 / s
	mut sum := 1.0
	mut num := 1.0
	mut denom := 1.0
	if z < 0.0 {
		return 0.0
	}
	sc *= math.pow(z, s)
	sc *= math.exp(-z)
	for _ in 0 .. 60 {
		num *= z
		s++
		denom *= s
		sum += (num / denom)
	}
	return sum * sc
}
