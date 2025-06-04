## Welcome to your new laptop!

Here is a checklist you can quickly follow to get you set up faster:

- Copy all your .env files from your old repos as these are not stored in the git tree of course
```
find . -type f | grep "\/\.env$"
```

- Copy your .ssh folder
- Copy your .aws and .aws-gate folder
- Copy your .oci folder
- Ask for your license keys for gittower and tableplus if you use these apps
- Copy your browser bookmarks and/or other data
- Copy your vscode settings
- Copy your raycast settings
- Copy your database editor settings, tableplus or sequalace both have an export function
- Copy over your notes

You can also try out the script at https://raw.githubusercontent.com/atabix/macbook-install/main/migrate-laptop.sh
Download it to your old laptop and execute it like so:
```
bash migrate-laptop.sh
```
Move the migrate.tar to your new laptop and extract it like so:
```
tar xvf migrate.tar
```
Then move all the folders to their correct locations, if the target folder already exists you can delete it and overwrite it with your backup.