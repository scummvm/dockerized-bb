#include "n64utils.h"
#include "N64sys.h"

#include <stdlib.h>

typedef void (*func_ptr)(void);

/* These are defined in the linker script */
extern func_ptr __CTOR_LIST__[];
extern func_ptr __CTOR_END__[];

void __do_global_ctors() {
	Uint32 tot_constructors = *(Uint32*)(__CTOR_LIST__);
	for (void (**f)(void) = (void (**)(void))(__CTOR_LIST__ + 1); tot_constructors > 0; tot_constructors--, f++)
		(**f)();

	//*(Uint32*)(__CTOR_LIST__) = 0xFFFF;
}

extern Uint8 __data_start;
extern Uint8 __data_end;
extern Uint8 __text_start;
extern Uint8 __text_end;

void __commit_data_and_text(void) {
	inst_cache_writeback_invalidate(&(__text_start), ((Uint32)&__text_end - (Uint32)&__text_start));
	data_cache_writeback_invalidate(&(__data_start), ((Uint32)&__data_end - (Uint32)&__data_start));
}


extern Uint8 __sbss_start;
extern Uint8 __sbss_end;
extern Uint8 __bss_start;
extern Uint8 __bss_end;

void __clean_bss(void) {
	Uint8* dst;

	for (dst = (Uint8 *)UncachedAddr(&__bss_start); dst < (Uint8 *)UncachedAddr(&__bss_end); dst++)
		*dst = 0;
	data_cache_writeback_invalidate(&(__bss_start), ((Uint32)&__bss_end - (Uint32)&__bss_start));

	for (dst = (Uint8 *)UncachedAddr(&__sbss_start); dst < (Uint8 *)UncachedAddr(&__sbss_end); dst++)
		*dst = 0;
	data_cache_writeback_invalidate(&(__sbss_start), ((Uint32)&__sbss_end - (Uint32)&__sbss_start));
}

void alive_and_well(void);

extern int main(void);

// Do necessary initializaitons before calling program main
void __init(void) {
	// Purge cache for data and text sections
	//__commit_data_and_text();

	// Clear the bss sections
	//__clean_bss();

	// Initialization of global constructors
	__do_global_ctors();

	// Call the app entry point ...
	main();
}

