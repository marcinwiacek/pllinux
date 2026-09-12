[Prev page](file_yq_milestone9.md) [Next page](file_zz_milestone.md)

# Milestone 10

# Logging

PLLinux should be user friendly. There was longer time spent on extending **pllinux** and currently (11 Sep 2026) it's main menu looks this way:

![Alt text](2026/sep_pllinux_main.jpg)

When we speak about logging - in theory system could implement logging in the syslog standard and done (kernel log saved with **dmesg** should have redirection possibility, the same services created with **dinit** could have private logs or could be redirected, etc.)

I started with using **syslogd** from **busybox**. It should support very standard format ([according to the example](https://github.com/brgl/busybox/blob/master/docs/syslog.conf.txt)). After some tries it was found, that operators ! and != don't work like in the example and syslog.conf end with these context:

    kern.* /log/tmp/kernel
    daemon.* /log/tmp/services
    auth.* /log/tmp/auth
    syslog.* /log/tmp/syslog
    cron.* /log/tmp/cron

And... kernel messages are not logged, the same these from cron (could be some config mistake) and from the daemon/dinit (it was naturally extra configured to redirect everything).

This was time to check alternatives. syslog-ng has got other config, rsyslog seems to be used widely and seems to have compatiblity with old syslog format.
After some steps it was compiled and installed... it's recognizing config, doesn't show any error and doesn't save anything to log files.

Conversion from busybox's syslogd is not plug-and-plug. But why?

# Scheduler

[Prev page](file_yq_milestone9.md) [Next page](file_zz_milestone.md)
