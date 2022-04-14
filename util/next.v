module util

import rand

pub fn next(mut rng rand.PRNG, skip InputType) byte {
	match skip {
		.one_byte {
			return rng.byte()
		}
		.upper_u32 {
			return byte(rng.u32() >> 24)
		}
		.upper_u64 {
			return byte(rng.u64() >> 56)
		}
		.fraction {
			return byte(rng.f64() * 256)
		}
	}
}
