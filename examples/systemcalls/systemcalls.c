#include "systemcalls.h"
#include <sys/types.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>


/**
 * @param cmd the command to execute with system()
 * @return true if the command in @param cmd was executed
 *   successfully using the system() call, false if an error occurred,
 *   either in invocation of the system() call, or if a non-zero return
 *   value was returned by the command issued in @param cmd.
 */
bool do_system(const char *cmd)
{

    /*
     * TODO  add your code here
     *  Call the system() function with the command set in the cmd
     *   and return a boolean true if the system() call completed with success
     *   or false() if it returned a failure
     */
    int status = system(cmd);
    if (status == -1) return false;

    return (WIFEXITED(status) && WEXITSTATUS(status) == EXIT_SUCCESS);
}

/**
 * @param count -The numbers of variables passed to the function. The variables are command to execute.
 *   followed by arguments to pass to the command
 *   Since exec() does not perform path expansion, the command to execute needs
 *   to be an absolute path.
 * @param ... - A list of 1 or more arguments after the @param count argument.
 *   The first is always the full path to the command to execute with execv()
 *   The remaining arguments are a list of arguments to pass to the command in execv()
 * @return true if the command @param ... with arguments @param arguments were executed successfully
 *   using the execv() call, false if an error occurred, either in invocation of the
 *   fork, waitpid, or execv() command, or if a non-zero return value was returned
 *   by the command issued in @param arguments with the specified arguments.
 */

bool do_exec(int count, ...)
{
    va_list args;
    va_start(args, count); // count is the last named parameter before the variable argument list
    char *command[count + 1];
    int i;
    for (i = 0; i < count; i++)
    {
        command[i] = va_arg(args, char *); // Get each argument from the variable argument list
    }
    command[count] = NULL; // end of the command list
    // this line is to avoid a compile warning before your implementation is complete
    // and may be removed
    command[count] = command[count];
    va_end(args); // Clean up the variable argument list

    /*
     * TODO:
     *   Execute a system command by calling fork, execv(),
     *   and wait instead of system (see LSP page 161).
     *   Use the command[0] as the full path to the command to execute
     *   (first argument to execv), and use the remaining arguments
     *   as second argument to the execv() command.
     *
     */
    pid_t pid = fork();
    if (pid == -1)
    {
        return false; // fork call failed
    }
    else if (pid == 0)
    {
        // In the child process
        execv(command[0], command); // Child process executes the command. Returns only if execv call fails
        exit(EXIT_FAILURE);                   
    }

    // Parent process waits for the child to finish
    int status;
    if (waitpid(pid, &status, 0) == -1)
    {
        return false; // If waitpid call fails
    }
    else if (WIFEXITED(status))
    {
        // Check child return status. If the command passed in execv fails, the exit status will be non-zero,
        // e.g. when a command doesn't specify the full path.
        return WEXITSTATUS(status) == EXIT_SUCCESS; 
    }

    return false; // If the child did not exit normally
}

/**
 * @param outputfile - The full path to the file to write with command output.
 *   This file will be closed at completion of the function call.
 * All other parameters, see do_exec above
 */
bool do_exec_redirect(const char *outputfile, int count, ...)
{
    va_list args;
    va_start(args, count);
    char *command[count + 1];
    int i;
    for (i = 0; i < count; i++)
    {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;
    // this line is to avoid a compile warning before your implementation is complete
    // and may be removed
    command[count] = command[count];
    va_end(args);

    /*
     * TODO
     *   Call execv, but first using https://stackoverflow.com/a/13784315/1446624 as a refernce,
     *   redirect standard out to a file specified by outputfile.
     *   The rest of the behaviour is same as do_exec()
     *
     */
    int fd = open(outputfile, O_WRONLY | O_TRUNC | O_CREAT, 0644);
    if (fd < 0)
    {
        return false; // If opening the file fails, return false
    }

    pid_t pid = fork();
    if (pid == -1)
    {
        return false;
    }
    else if (pid == 0)
    {
        if (dup2(fd, 1) < 0) // Redirect standard output to the file descriptor
        {
            close(fd);
            exit(EXIT_FAILURE);
        }
        close(fd); // you can close the file descriptor after duplicating it

        execvp(command[0], command);
        exit(EXIT_FAILURE);
    }
    close(fd);

    int status;
    if (waitpid(pid, &status, 0) == -1)
    {
        return false;
    }
    else if (WIFEXITED(status))
    {
        return WEXITSTATUS(status) == EXIT_SUCCESS;
    }

    return false;
}
