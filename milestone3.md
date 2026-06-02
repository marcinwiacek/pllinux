# Milestone 3
# App folder structure

/app1/version1
/app1/version2
/app1/current
/app2/version1
/app2/version2
/app2/current

In current implementation we make links from current app version to the current and we use current in many scripts, additionally normally directories with version are created using pattern "YYMMDD_version_from_the_app", where YYMMDD is year, month and day of creating package (in the future date will be eventually removed)

Every version should contain in own root readme.md file with info about package, source, license, system services, man pages, etc.

But where is the revolution?

Every operation on these files are done from system script and app installer itself doesn't have rights (additionally script for changing
something in app folder during installation will be running in sandbox created by Bubblewrap)

# Operating from root
(etc,
