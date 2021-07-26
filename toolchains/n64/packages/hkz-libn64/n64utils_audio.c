#include "n64utils.h"
#include "datatypes.h"
#include "N64sys.h"
#include "AI.h"
#include "MI.h"

#include <malloc.h>
#include <string.h>

#define BUFFERS 2

static Uint8 *snd_buffers[BUFFERS];

static Uint32 buffer_size = 0;

static volatile Uint8 writingBuffer = 0;

void initAudioInterface(Uint32 clockrate, Uint32 frequency, Uint8 bitsPerSample, Uint32 bufferSize) {
	set_AI_interrupt(0);
	AI_set_frequency(frequency, clockrate, bitsPerSample);
	set_AI_interrupt(1);

	bufferSize = bufferSize + (8 - (bufferSize % 8));

	buffer_size = bufferSize;

	writingBuffer = 0;

	for (int bufn = 0; bufn < BUFFERS; bufn++) {
		if (snd_buffers[bufn]) free(snd_buffers[bufn]);

		snd_buffers[bufn] = memalign(8, bufferSize);
	}

	for (int bufn = 0; bufn < BUFFERS; bufn++)
		memset(UncachedAddr(snd_buffers[bufn]), 0, bufferSize);
}

Uint32 getAIBufferSize(void) {
	return buffer_size;
}

Uint8*  getAIBuffer() {
	return UncachedAddr(snd_buffers[writingBuffer]);
}

void putAIBuffer(void) {
	AI_add_buffer((Sint16*)snd_buffers[writingBuffer], buffer_size);
	writingBuffer = (writingBuffer + 1) % BUFFERS;
}

