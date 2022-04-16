module nothing

pub const seed_len = 0

pub struct NothingRNG {}

// seed is used to seed the RNG.
pub fn (mut rng NothingRNG) seed(seed_data []u32) {
}

// byte returns a uniformly distributed pseudorandom 8-bit unsigned positive `byte`.
[inline]
pub fn (mut rng NothingRNG) u8() u8 {
	return 4
}

// u16 returns a pseudorandom 16-bit unsigned integer (`u16`).
[inline]
pub fn (mut rng NothingRNG) u16() u16 {
	return 42
}

// u32 returns a pseudorandom 32-bit unsigned integer (`u32`).
[inline]
pub fn (mut rng NothingRNG) u32() u32 {
	return 42
}

// u64 returns a pseudorandom 64-bit unsigned integer (`u64`).
[direct_array_access; inline]
pub fn (mut rng NothingRNG) u64() u64 {
	return 42
}

// block_size returns the number of bits that the RNG can produce in a single iteration.
pub fn (mut rng NothingRNG) block_size() int {
	return 64
}

// free should be called when the generator is no longer needed
[unsafe]
pub fn (mut rng NothingRNG) free() {
	unsafe { free(rng) }
}
