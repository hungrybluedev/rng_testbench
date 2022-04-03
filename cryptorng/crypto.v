module cryptorng

import crypto.rand as crand

pub struct CryptoRNG {
}

pub fn (mut rng CryptoRNG) seed(seed_data []u32) {
	// We do nothing
}

[direct_array_access]
pub fn (mut rng CryptoRNG) byte() byte {
	temp := crand.bytes(1) or { [byte(0)] }
	return temp[0]
}

[inline]
pub fn (mut rng CryptoRNG) u16() u16 {
	temp := crand.bytes(2) or { [byte(0), 0] }
	return (u16(temp[0])) | (u16(temp[1]) << 8)
}

[inline]
pub fn (mut rng CryptoRNG) u32() u32 {
	temp := crand.bytes(4) or { [byte(0), 0, 0, 0] }
	return (u32(temp[0])) | (u32(temp[1]) << 8) | (u32(temp[2]) << 16) | (u32(temp[3]) << 24)
}

[inline]
pub fn (mut rng CryptoRNG) u64() u64 {
	temp := crand.bytes(8) or { [byte(0), 0, 0, 0, 0, 0, 0, 0] }
	return (u64(temp[0])) | (u64(temp[1]) << 8) | (u64(temp[2]) << 16) | (u64(temp[3]) << 24) | (u64(temp[4]) << 32) | (u64(temp[5]) << 40) | (u64(temp[6]) << 48) | (u64(temp[7]) << 56)
}

[inline]
pub fn (mut rng CryptoRNG) block_size() int {
	return 0
}

[unsafe]
pub fn (mut rng CryptoRNG) free() {
	unsafe { free(rng) }
}
