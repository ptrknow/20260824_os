#ifndef FILE_H
#define FILE_H

#include "pparser.h"

typedef unsigned int FILE_SEEK_MODE;
enum {
    SEEK_SET,
    SEEK_CUR,
    SEEK_END,
};

typedef unsigned int FILE_MODE;
enum {
    FILE_MODE_READ,
    FILE_MODE_WRITE,
    FILE_MODE_APPEND,
    FILE_MODE_INVALID,
};

// Function pointers to be inherited by a particular
// filesystem driver.
struct disk;
typedef void* (*FS_OPEN_FUNCTION)(struct disk* disk,
    struct path_part* path, FILE_MODE mode);
typedef int (*FS_RESOLVE_FUNCTION)(struct disk* disk);

struct filesystem {
    // When VFS layer wants to determine a filesystem,
    // it loops through all registered filesystems and
    // runs resolve.
    // If resolve returns zero, then the filesystem
    // driver is indicating that it understands how to
    // read the given disk.
    FS_RESOLVE_FUNCTION resolve;
    FS_OPEN_FUNCTION open;

    char name[20];
};

struct file_descriptor {
    int index;
    struct filesystem* filesystem;
    void* private;
    struct disk* disk;
};

void fs_init();
int fopen(const char* filename, const char* mode);
void fs_insert_filesystem(struct filesystem* filesystem);
struct filesystem* fs_resolve(struct disk* disk);

#endif
