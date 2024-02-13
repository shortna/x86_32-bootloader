#include "mystdlib.h"

#define VGA_MEMORY_ADDRESS (0xA0000)

#define SCREEN_WIDTH (320)
#define SCREEN_HEIGHT (200)

#define MEMORY_MAP_ADDRESS (0xF000)

typedef struct {
  u64 base;
  u64 length;
  u32 type;
  u32 attrs;
} MemoryMapEntry;

void kernel_main(void) __attribute__((section(".start")));

void drawPixel(u16 x, u16 y, u8 color) {
  u8 *address = (u8 *)VGA_MEMORY_ADDRESS + SCREEN_WIDTH * y + x;
  *address = color;
}

void drawSquare(u16 x, u16 y, u16 size, u8 color) {
  u16 x_end = x + size < SCREEN_WIDTH ? x + size : SCREEN_WIDTH;
  u16 y_end = y + size < SCREEN_HEIGHT ? y + size : SCREEN_HEIGHT;
  for (u16 i = x; i < x_end; i++) {
    for (u16 j = y; j < y_end; j++) {
      drawPixel(i, j, color);
    }
  }
}

// returns sorted buffer with available chunks
// buffer must contain (*(u16*)MEMORY_MAP_ADDRESS) elements
u16 getMemoryMap(MemoryMapEntry *buffer) {
  MemoryMapEntry *entries = (void *)MEMORY_MAP_ADDRESS + 0x10;
  u16 n_entries = *(u16*)MEMORY_MAP_ADDRESS;

  u16 n_available = 0;
  for (u16 i = 0; i < n_entries; i++) {
    if (entries->type == 0x1) {
      buffer[i] = *entries;
      n_available++;
    }
    else {
      buffer[i] = (MemoryMapEntry) {0};
    }
    entries++;
  }

  for (u16 i = 0; i < n_entries; i++) {
    for (u16 j = 1; j < n_entries - (i + 1); j++) {
      if (buffer[j].length < buffer[i].length) {
        MemoryMapEntry tmp = buffer[i];
        buffer[i] = buffer[j];
        buffer[j] = tmp;
      }
    }
  }
  return n_available; 
}

void kernel_main(void) {
  u16 n_entries = *(u16*)MEMORY_MAP_ADDRESS;

  MemoryMapEntry buf[n_entries];
  u16 n_available = getMemoryMap(buf);
  drawSquare(0, 0, 50, 0x50);
  while (1) {
  };
}
