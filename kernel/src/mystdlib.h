#ifndef MY_STDLIB
#define MY_STDLIB

#include <stddef.h>
#include <stdint.h>

typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

typedef int8_t i8;
typedef int16_t i16;
typedef int32_t i32;
typedef int64_t i64;

void free(void*);
void* malloc(size_t size);
void* realloc(void*, size_t size);

void* memset(void*, int value, size_t size);
void* memcpy(void *, const void *, size_t size);

#endif
