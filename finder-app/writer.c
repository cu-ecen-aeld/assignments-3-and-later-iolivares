#include <fcntl.h>
#include <sys/types.h>
#include <unistd.h>
#include <string.h>
#include <syslog.h>
#include <errno.h>

int main(int argc, char const *argv[]) {
    openlog("writer", LOG_PID, LOG_USER);

    if (argc < 3) {
        syslog(LOG_ERR, "Usage: %s <file_path> <content>", argv[0]);
        return 1;
    }

    const char *file_path = argv[1];
    const char *content = argv[2];

    int fd;
    fd = open(file_path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd == -1) {
        syslog(LOG_ERR, "Error: opening file %s for writing: %s", file_path, strerror(errno));
        return 1;
    }

    syslog(LOG_DEBUG, "Writing %s to %s", content, file_path);

    int result = 0;

    ssize_t nr;
    nr = write(fd, content, strlen(content));
    if (nr == -1) {
        syslog(LOG_ERR, "Error: writing to file %s: %s", file_path, strerror(errno));
        result = 1;
    }

    if (close(fd) == -1) {
        syslog(LOG_ERR, "Error: closing file %s: %s", file_path, strerror(errno));
        return 1;
    }   

    closelog();

    return result;
}
