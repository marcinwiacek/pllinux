# Milestone 5
# Packaging

Let's return to the packaging and versioning topics. Initial proposed naming in the PLLINUX was:

date_version.

Examples:

260510_5.0
260512_5.0
260511_6.0
260514_5.0

As you can, we resolved problem, when concrete version is repackaged with some fixes (for example security).

But how to handle situation, when package has got git repo inside and we don't see version in folder name?

This is unresolved.

And how to handle situation, when we want to have only app from the concrete generation? (in the example above
- how to force system to update apps from the 1.x line and not touch 2.x line?)

One possible solution:

We need extra information, which shows generation, for example:

260510_1_5.0
260512_1_5.0
260511_2_6.0
260514_1_5.0
260515_1_5.1

or

0000001_260510_5.0
0000001_260510_5.1
0000001_260610_5.2
0000002_260410_6.0

But what about situation, when somebody want to package version 4.0 or 3.0? We don't have lower number than 0000001.

Let's return to original naming:

260510_5.0
260512_5.0
260511_6.0
260514_5.0

We just need to have way to say:

1. upgrade app from all lines (in the example 5.x and 6.x)
2. upgrade app to the latest possible version (for example 7.x or higher)
3. app needs to link to the latest possible (greatest) version, very concrete version or all versions from concrete line

Let's concentrate on last point:

PLLINUX is already prepared for latest possible version (we say: link to "current"), with others it's enough to give string

"260510_5.0"

or 

"260510_5.0+"

and implemented few simple rules:

1. paket is later, when has got at least the same date (first six digits) AND
2. when we don't + on the end, we just take all packages with this string OR when we have + on the end:
   1. packet is higher, when some character in some place is higher than our character OR
   2. packet has got the character in all places AND packet has got longer version string

Looks, complicated, but let's compare:

"260510_5.88+"

and

"260510_5.9" - date is the same, but 9 in the end is higher than 0
"260510_5.8a" - date is the same and both 5.0 are the same, but a makes new packet name longer
"260510_5.89" - string is longer
"260510_5.101" - string is longer



Isn't it enough to say: for this app we want all versions or we want all versions starting with 1.

And here we're returning into dependencies marking. Currently PLLINUX allows for saying "we have dep from current or concrete version".
We need to extend it