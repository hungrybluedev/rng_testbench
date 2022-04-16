module util

import rand

pub fn next(mut rng rand.PRNG, skip InputType) u8 {
	match skip {
		.one_byte {
			return rng.u8()
		}
		.upper_u32 {
			return u8(rng.u32() >> 24)
		}
		.upper_u64 {
			return u8(rng.u64() >> 56)
		}
		.fraction {
			return u8(rng.f64() * 256)
		}
	}
}
