# Bitwarden logins and secrets to environment variables and docker secrets.

Make script executable `chmod +X bitwarden2conf.sh`

To run: `. ./bitwarden2conf.sh <folder-name>` ommit folder-name to move logins and notes in "no folder" category.

Notice `. ./bit..` dot space path. This is shortcut to `source ./bitw...sh` this id done to set environment variables in your shell and not just in the scope of the script.


## Details

This script will read the logins and notes from bitwarden (folder) and populate environment variables in the format:
```
export [login-name]_password=[password]
export [login-name]_username=[username>
export [login-name]=[notes]
```
Important to note, the translation of login name to environment variable requires proper naming - no special characters like `.` etc.

Thes script will also read secure notes from the folder and downloads there attachments into `./secrets` folder so they can be used as 
docker secrets. The file name is the same as file attachment name.

## Demonstration

The folder has been created in bitwarden `git/swimlane/swimlane` for storing the secrets.

This project also includes docker-compose file and init script for mongo. You will notice the environment variables were moved from
.env files and are interpolated in compose file. It will bring api and mongo up and you can check connectivity and configuration on 
containers.
