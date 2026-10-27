[Prev page](file_yn_milestone12.md) [Next page](file_zz_milestone.md)

# Milestone 14

# Wayland or X11 ?

I don't want to join saint war and definitely be on one of sides - I have used X.Org for years (and I know about XLibre of course) and in some situations had
hard time with it (problems with Midnight Commander), from the other I had hard time with Wayland too (lack of gamma correction).

In 2026 I decided to look first on Hyprland, when will not work, move to XLibre.

On top of it there will be some lighter graphic environment - something with Start button, file manager, desktop wallpaper and some basic apps.

Status for now (24 Oct):

1. all packages (excluding Hyprland) are compiled. Problem is in this, that they use latest GCC and C++ and Debian Trixie is using older one (in some forum
somebody said, that they don't care). There were some code changes required, currently I'm stuck with "Cannot load proto" error. Non intuitive, non-user friendly.
2. xlibre-xserver compiled just like that, currently I'm just adding required deps. No problems.

Do you see difference? (and please don't start explaining, that Wayland and all related things are new and fresh - [things started around 2008?](https://en.wikipedia.org/wiki/Wayland_(protocol)))

Anyway, practically during second day I have first rendering with XLibre:

![Alt text](2026/oct_startx.png)

Not too much (no keyboard input, etc.), but it reminds me time, when I was young and preparing my first XWindows (it was XFree86). 
I hope to find way to separate and configure components and make it working at least in minimal way. Let's do it a little bit parallel with
some sensible Wayland implementation:

With Hyprland there are porting/proto issues, let's take for example Wayfire int that case -
seems to be very cool (and has got support for [wlr gamma control](https://wayland.app/protocols/wlr-gamma-control-unstable-v1))... but



    wlroots_base_version = '0.20'
    if get_option('vulkan_effects')
       wlroots_dep_name = 'wlroots-vkfx-' + wlroots_base_version
       wlroots_subproject_name = 'wlroots-vkfx'
    else
      wlroots_dep_name = 'wlroots-' + wlroots_base_version
      wlroots_subproject_name = 'wlroots'
    endif

They seems to take wlroots from 2022, when are using vulkan_effects option... nice, isn't it? And they need at least 0.20, which seems to return
compilation errors with WP_COLOR_MANAGER_V1...:

    ../types/wlr_color_management_v1.c:1128:17: error: ‘WP_COLOR_MANAGER_V1_TRANSFER_FUNCTION_COMPOUND_POWER_2_4’ undeclared (first use in this function); did you mean ‘WP_COLOR_MANAGER_V1_TRANSFER_FUNCTION_ST2084_PQ’?
     1128 |                 WP_COLOR_MANAGER_V1_TRANSFER_FUNCTION_COMPOUND_POWER_2_4,
         |                 ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
         |                 WP_COLOR_MANAGER_V1_TRANSFER_FUNCTION_ST2084_PQ

 Why is that? Maybe I should try Sway in that case? Or woodland? Or labwc? The "Wayland" race has just started - the winner takes it all :D

[Prev page](file_yn_milestone12.md) [Next page](file_zz_milestone.md)
