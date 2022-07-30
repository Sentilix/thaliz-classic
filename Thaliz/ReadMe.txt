
Author:			Mimma
Create Date:	05/10/2015 17:50:57

The latest version of Thaliz can always be found at Curse:
https://www.curseforge.com/wow/addons/thaliz-rez-dem-deads

The source code can be found at Github:
https://github.com/Sentilix/thaliz-classic



About the Thaliz Project:
-------------------------
This addon will target a random friendly (unreleased) corpse, if any.
The target will be prioritized in the following order:

	* Highest priority to the corpse you are currently targetting (if any)
	* The Master looter (if any)
	* Then other ressers are resurrected
	* Then mana users are resurrected
	* Then warriors are resurrected
	* And then the rest (rogues).
	
If no Warlocks are up, one Warlock will be ressed after ressers are up.

When a corpse is being resurrected (unreleased or not), a random message is
displayed on the screen. This can be configured to be either a /SAY, /YELL
or in /RAID chat, together with an optional whisper to the target.

Up to 200 random messages in total can be configured. The addon ships with
20 pre-configured messages; mostly with quotes from famous World of Warcraft
bosses.

Messages - or macros - can be grouped into one of five different groups:
GUILD, CHARACTER, CLASS, RACE and DEFAULT.

When a macro is in the GUILD group, the macro can only be used if the target
belongs to the guild name, configured together with that macro.

Same goes for the CHARACTER group, where the macro can only be used if the
configured name matches the target character's name. CLASS and RACE works in
a similar way.

If the target being resurrected does not match any of the four above groups,
the macro's in the DEFAULT group will be used instead.

All pre-configured macros are in the DEFAULT group, but you can click on a
macro and reconfigure it as you like.

If the "Include Defaults in filtered macros" option is checked, then the
default macro list will always be considered, also even the target may match
macros in one or more of the other groups.


Message formatting:
-------------------
A resurrection message is a raw text string with a few extra codes to control
the final output.
The codes are:
 * %s - target name (without realm name) being resurrected.
 * %c - target class.
 * %r - target race.
 * %m - used for male/female specific texts, see below.


Male/female specific texts:
Imagine you have this resurrection string: "%s don't know what hit him!".
It works fine on male characters. But what if we could change the "him" to
"her" when resurrecting female characers? We can by using the %m code.

The %m code takes two parameters: a male text and a female text. When a male
is resurrected, the male text will be used and vice versa. The macro can now
be changed to "%s don't know what hit %m{him:her}!", and Thaliz will runtime
replace the %m macro with the "him" or "her" text.



About Thaliz:
-------------
Thaliz was a raiding priest in <Goldshire Golfclub> on the VanillaGaming.org
World of Warcraft server, famous for dying alot. To be honest, we all died
while progressing but he just stood out :-)

To recover faster from wipes, I wrote this simple addon to attempt to block
"duplicate" resurrections, and respond with random macros while ressing - and
that addon was named after the death-seeking priest: Thaliz!

Dying had never been funnier since that!


Thaliz (the priest) ultimately died mid 2016 when he deleted his account.

RIP Thaliz.



Thaliz Versions
---------------
Version 3.1.3
* Added command to reset the rez button position: "/thaliz resetbutton".
* Added support for Wrath of the Lich King Classic.
* Bugfix: Fixed a LUA error when doing "/thaliz version".


Version 3.1.2
* Update: UI made a little bigger (again), so messages are now shown correct.
* Bugfix: Added a typecheck on imported profiles (thanks to Exoridus)
* Cleanup: some dirty old code handling the spellnames<->spellid refactored.


Version 3.1.1
* Bugfix: Due to a failed merge the TOC file was broken in 3.1.0 - fixed


Version 3.1.0
* Added option to copy/merge profiles
* Update: UI has been refreshed.
* Update: Config menu can now be opened by right-clicking the Rezz button.


Version 3.0.6
* Bugfix: using master loot in a 5 man party made Thaliz throw a LUA error.


Version 3.0.5
* Update: minor fixes to avoid taint.


Thaliz 3.0.4:
* Updated for 9.2.5 client.


Thaliz 3.0.3:
* Added Wago ID to TOC. No functional changes.


Thaliz 3.0.2:
* Added CurseForce and WowInterface ID to TOC. No functional changes.


Thaliz 3.0.1:
* Fixed a bug in TBC where other peoples resses caused YOU to fire a ressing macro.

