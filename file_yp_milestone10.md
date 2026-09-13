[Prev page](file_yq_milestone9.md) [Next page](file_zz_milestone.md)

# Milestone 10

# Logging

PLLinux should be user friendly. There was longer time spent on extending **pllinux** and currently (11 Sep 2026) it's main menu looks this way:

![Alt text](2026/sep_pllinux_main.jpg)

When we speak about logging - in theory system could implement logging in the syslog standard and done (kernel log saved with **dmesg** should have redirection possibility, the same services created with **dinit** could have private logs or could be redirected, etc.)

I started with using **syslogd** from **busybox**. It should support very standard format ([according to the example](https://github.com/brgl/busybox/blob/master/docs/syslog.conf.txt)). After some tries it was found, that operators ! and != don't work like in the example and syslog.conf end with this content:

    kern.* /log/tmp/kernel
    daemon.* /log/tmp/services
    auth.* /log/tmp/auth
    syslog.* /log/tmp/syslog
    cron.* /log/tmp/cron

And... kernel messages are not logged, the same these from cron (could be some config mistake) and from the daemon/dinit (it was naturally extra configured to redirect everything).

This was time to check alternatives. syslog-ng has got other config, rsyslog seems to be used widely and seems to have compatiblity with old syslog format. After some steps it was compiled and installed... it's recognizing config, doesn't show any error and doesn't save anything to log files.

Conversion from busybox's syslogd is not plug-and-plug. But why?

Helps comes from the **strace** - when started with **rsyslogd**, it shows, that this daemon is searching for /dev/log device.

But shouldn't be, that logging daemon is creating everything when has got rules already? Shouldn't **rsyslogd** show itself, that device is not found or something? (and here we are again going into this, that Open Source is many times overcomplicated or full of unclear or even stupid things)

Offtopic: [I don't care for Gnome](https://woltman.com/gnome-bad/) - this page is quite good confirming, that problems are visible even with "the greatest", the most "user friendly" and most advertised and pushed for everybody GUI.

Anyway, what can be done with the problem with /dev/log?

    module(load="imuxsock") #local system logging
    module(load="imkmsg") #kernel boot messages (from ring buffer and /dev/kmsg). Cannot be used with imklog module

These two magic lines in **syslog.conf** (named here by default **rsyslog.conf**) made, that **rsyslog** finally started collecting messages. For people saying "RTFM" I would answer - it could show message "no data collecting modules" or modules should be loaded automagically when all these rules with filenames are already in config file.

With modules I was able to get authentication info (but only for root), something from **cron**, boot messages from kernel and **rsyslog** itself. Quite everything was collected when **rsyslog** was started & restarted as service (but why?). And I haven't seen **dinit** messages = there is still a lot of todo, but at least progress is visible.

Offtopic: what about journald service?

Answer: Collecting logs from different sources is generally good idea, from the other hand somebody created syslog and then duplicated it "a little" bit. 
Right now (on the VDI machine, where I write these words) my logs files have >600MB. Normal users don't know about things like this 
and they naive think, that Linux is small and fast... but standard installations are becoming bloated like Windows. 
PLLinux will make for now logs just with **rsyslogd** to avoid duplicates + centralized solution in the future cannot make duplicates + 
standard setup will write majority of logs into tmpfs by default (disclaimer: how many times were you looking into them in the home machine? 
Do you really need log from every boot? Or every start of your printer daemon or similar stuff?)

Returning to the logging problems - the solution was changing services starting order:

1. service **boot** is starting (new) **bootsh** and (old) **syslogd**, **crond**, **tty1**, etc.
2. **syslogd** is waiting for start completion for **bootsh**
3. other services (**crond**, **tty1**, etc.) are waiting for start completion for **syslogd**

Currently:

1. **dinitctl** can stop or restart **bootsh** (it this problem?)
2. logging non-admin users is not saved in logs (is it busybox's **login** command limit?)
3. boot screen finally looks clean

# Scheduler

Background tasks could be started in two ways:

1. on the specified time (but should happen, when this is missed?)
2. after some specified time (for example once a day)

PLLinux will start from this - this is classical **cron**.

[Prev page](file_yq_milestone9.md) [Next page](file_zz_milestone.md)
