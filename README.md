# simple-linux-backup-script

A simple backup script for linux, made to run in bash, using zenity and crontab. It allows the user to easily define which items to backup, in a window interface. Options include compression and periodic copies.

Made as an university assignment for "Operating Systems" class.

### Included files:

- **backup.sh** - the main script, which guides the user through a user-friendly creator. Allows for easy item selection and saving the settings for future use.
- **backup_cron.sh** - designed to be called from crontab, which executes a backup previously planned by the user.
- **backup.man** - the manual page for the script.
