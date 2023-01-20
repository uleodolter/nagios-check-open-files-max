# nagios-check-open-files-max

Nagios-check to verify if number of open files for specific user and process is near system limits.
The process having the most open files is automatically detected and used to check against user limits.

## Installation

Add the following to the sudoers file to grant permissions to lsof and to read the file limits from /proc/PID/limits.

```
Cmnd_Alias CHECK_OPEN_FILES_MAX = /bin/cat /proc/*/limits, /sbin/lsof -u *

nagios    ALL=(ALL) NOPASSWD: CHECK_OPEN_FILES_MAX
```

## Usage

```
./check_open_files_max.sh <username>
```
Example:
```
./check_open_files_max.sh apache
```
