#ifndef DISK_H
#define DISK_H

#include "fs/file.h"

typedef unsigned int DISK_TYPE;

// type of hard disk
#define DISK_TYPE_REAL 0
// TODO: implement DISK_TYPE_VIRTUAL

struct disk {
    DISK_TYPE type;
    int sector_size;
    struct filesystem* filesystem;
    int id; // ID of mounted disk
    void* fs_private;
};

void disk_search_and_init();
struct disk* disk_get(int index);

int disk_read_block(struct disk* idisk, unsigned int lba,
    int total, void* buf);

#endif
