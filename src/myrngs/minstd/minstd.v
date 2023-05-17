module minstd

import rand.seed

pub const seed_len = 1

pub struct MinStdRNG {
mut:
	seed       int = int(seed.time_seed_32() & 0x7fffffff)
	buffer     int
	bytes_left int
}

const (
	max = 2147483647
	a   = 48271
	q   = 44488
	r   = 3399
)

// seed is used to seed the RNG.
pub fn (mut rng MinStdRNG) seed(seed_data []u32) {
	if seed_data.len != minstd.seed_len {
		panic('seed data must have 1 element')
	}
	rng.seed = int(seed_data[0] & 0x7fffffff)
	rng.bytes_left = 0
	rng.buffer = 0
}

fn (mut rng MinStdRNG) internal_int() int {
	rng.seed = minstd.a * (rng.seed % minstd.q) - minstd.r * (rng.seed / minstd.q)
	rng.seed += if rng.seed < 0 { minstd.max } else { 0 }
	return rng.seed
}

// u8 returns a uniformly distributed pseudorandom 8-bit unsigned positive `u8`.
[inline]
pub fn (mut rng MinStdRNG) u8() u8 {
	if rng.bytes_left >= 1 {
		rng.bytes_left -= 1
		value := u8(rng.buffer)
		rng.buffer >>= 8
		return value
	}
	rng.buffer = rng.internal_int()
	rng.bytes_left = 2
	value := u8(rng.buffer)
	rng.buffer >>= 8
	return value
}

// u16 returns a pseudorandom 16-bit unsigned integer (`u16`).
[inline]
pub fn (mut rng MinStdRNG) u16() u16 {
	if rng.bytes_left >= 2 {
		rng.bytes_left -= 2
		value := u16(rng.buffer)
		rng.buffer >>= 16
		return value
	}
	ans := rng.internal_int()
	rng.buffer = ans >> 16
	rng.bytes_left = 1
	return u16(ans)
}

// u32 returns a pseudorandom 32-bit unsigned integer (`u32`).
[inline]
pub fn (mut rng MinStdRNG) u32() u32 {
	return (u32(rng.internal_int()) << 1) | u32(rng.internal_int() & 1)
}

// u64 returns a pseudorandom 64-bit unsigned integer (`u64`).
[inline]
pub fn (mut rng MinStdRNG) u64() u64 {
	return (u64(rng.u32()) << 32) | rng.u32()
}

// block_size returns the number of bits that the RNG can produce in a single iteration.
pub fn (mut rng MinStdRNG) block_size() int {
	return 32
}

// free should be called when the generator is no longer needed
[unsafe]
pub fn (mut rng MinStdRNG) free() {
	unsafe { free(rng) }
}

// int minstd(void) {
// seed = A * (seed % Q) - R * (seed / Q);
// seed += (seed < 0) ? M : 0;
// return seed;
// }
// double dminstd(void) {
// return minstd() / (double)M;
// }
