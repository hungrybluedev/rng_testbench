module xoshiro

import rand.seed

pub const seed_len = 8

pub struct X256PlusPlusRNG {
mut:
	state [4]u64 = [seed.time_seed_64(), seed.time_seed_64(), seed.time_seed_64(),
	seed.time_seed_64()]!
	buffer     u64
	bytes_left int
}

// seed is used to seed the RNG.
pub fn (mut rng X256PlusPlusRNG) seed(seed_data []u32) {
	if seed_data.len != xoshiro.seed_len {
		panic('seed data must have 8 elements')
	}
	rng.state[0] = u64(seed_data[0]) ^ (u64(seed_data[1]) << 32)
	rng.state[1] = u64(seed_data[2]) ^ (u64(seed_data[3]) << 32)
	rng.state[2] = u64(seed_data[4]) ^ (u64(seed_data[5]) << 32)
	rng.state[3] = u64(seed_data[6]) ^ (u64(seed_data[7]) << 32)
	rng.bytes_left = 0
	rng.buffer = 0
}

// byte returns a uniformly distributed pseudorandom 8-bit unsigned positive `byte`.
[inline]
pub fn (mut rng X256PlusPlusRNG) byte() byte {
	if rng.bytes_left >= 1 {
		rng.bytes_left -= 1
		value := byte(rng.buffer)
		rng.buffer >>= 8
		return value
	}
	rng.buffer = rng.u64()
	rng.bytes_left = 7
	value := byte(rng.buffer)
	rng.buffer >>= 8
	return value
}

// u16 returns a pseudorandom 16-bit unsigned integer (`u16`).
[inline]
pub fn (mut rng X256PlusPlusRNG) u16() u16 {
	if rng.bytes_left >= 2 {
		rng.bytes_left -= 2
		value := u16(rng.buffer)
		rng.buffer >>= 16
		return value
	}
	ans := rng.u64()
	rng.buffer = ans >> 16
	rng.bytes_left = 6
	return u16(ans)
}

// u32 returns a pseudorandom 32-bit unsigned integer (`u32`).
[inline]
pub fn (mut rng X256PlusPlusRNG) u32() u32 {
	if rng.bytes_left >= 2 {
		rng.bytes_left -= 2
		value := u32(rng.buffer)
		rng.buffer >>= 32
		return value
	}
	ans := rng.u64()
	rng.buffer = ans >> 32
	rng.bytes_left = 4
	return u32(ans)
}

// u64 returns a pseudorandom 64-bit unsigned integer (`u64`).
[direct_array_access; inline]
pub fn (mut rng X256PlusPlusRNG) u64() u64 {
	result := rotl(rng.state[0] + rng.state[3], 23) + rng.state[0]

	t := rng.state[1] << 17

	rng.state[2] ^= rng.state[0]
	rng.state[3] ^= rng.state[1]
	rng.state[1] ^= rng.state[2]
	rng.state[0] ^= rng.state[3]

	rng.state[2] ^= t

	rng.state[3] = rotl(rng.state[3], 45)

	return result
}

fn rotl(x u64, k int) u64 {
	return (x << k) | (x >> (64 - k))
}

// block_size returns the number of bits that the RNG can produce in a single iteration.
pub fn (mut rng X256PlusPlusRNG) block_size() int {
	return 64
}

// free should be called when the generator is no longer needed
[unsafe]
pub fn (mut rng X256PlusPlusRNG) free() {
	unsafe { free(rng) }
}
