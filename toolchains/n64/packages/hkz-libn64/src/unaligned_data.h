/*
 * Calls used to perform unaligned read/writes on N64.
 * Shamelessly copied from ScummVM sourcecode.
 */

#ifndef __UNALIGNED_DATA_ACCESS__
#define __UNALIGNED_DATA_ACCESS__

#include "datatypes.h"

inline Uint16 SAFE_READ_UINT16(const void *ptr) {
	const Uint8 *b = (const Uint8 *)ptr;
	return (b[0] << 8) | b[1];
}
inline Uint32 SAFE_READ_UINT32(const void *ptr) {
	const Uint8 *b = (const Uint8 *)ptr;
	return (b[0] << 24) | (b[1] << 16) | (b[2] << 8) | (b[3]);
}
inline void SAFE_WRITE_UINT16(void *ptr, Uint16 value) {
	Uint8 *b = (Uint8 *)ptr;
	b[0] = (Uint8)(value >> 8);
	b[1] = (Uint8)(value >> 0);
}
inline void SAFE_WRITE_UINT32(void *ptr, Uint32 value) {
	Uint8 *b = (Uint8 *)ptr;
	b[0] = (Uint8)(value >> 24);
	b[1] = (Uint8)(value >> 16);
	b[2] = (Uint8)(value >>  8);
	b[3] = (Uint8)(value >>  0);
}

#endif

