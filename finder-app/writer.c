#include <stdio.h>
#include <fcntl.h>
#include <sys/types.h>
#include <unistd.h>
#include <string.h>

int main(int argc, char const *argv[]) {
    if (argc < 3) {
        // @todo replace with syslog
        printf("Usage: %s <file_path> <content>\n", argv[0]);
        return 1;
    }

    const char *file_path = argv[1];
    const char *content = argv[2];

    int fd;
    fd = open(file_path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd == -1) {
        // @todo replace with syslog
        printf("Error opening file %s for writing\n", file_path);
        return 1;
    }

    printf("Writing %s to %s\n", content, file_path);

    int result = 0;

    ssize_t nr;
    nr = write(fd, content, strlen(content));
    if (nr == -1) {
        // @todo replace with syslog
        printf("Error writing to file %s\n", file_path);
        result = 1;
    }

    if (close(fd) == -1) {
        // @todo replace with syslog
        printf("Error closing file %s\n", file_path);
        return 1;
    }   

    return result;
}
