# thaliz-classic
Thaliz - Resurrection addon


# The Thaliz Project
 

## 1. About the Thaliz Project
This addon will target a random friendly (unreleased) corpse, if there are many corpses, the target will be prioritized in the following order:

- Highest priority to the corpse you are currently targetting (if any)
- then master looter is resurrected (if any)
- then other ressers are resurrected
- then mana users are resurrected
- then warriors are resurrected
- and last the rogues.

 

If no Warlocks are up, one Warlock will be ressed after ressers are up. The raid leader will get priority just below the ressers, as he is usually also the loot master.
When a corpse is being resurrected (unreleased or not), a random message is displayed on the screen. This can be configured to be either a /SAY, /YELL or in /RAID chat, together with an optional whisper to the target.

Thaliz works in both Classic ERA/SOM, Burning Crusade and Retail. In theory also Wrath of the Lich King Classic, but that remains to be seen.

 
## 1.1. How Thaliz works 
Thaliz scan the raid for corpses. If a corpse is found and eligible for a res, the Thaliz action button will change icon to your current class (Priest, Paladin, Shaman, and in retail also Druid and Monk). This means the button is ready for use.

When you click the button, the actual res will begin. If there are more than just one corpse, the priorities listed above will be used.

Thaliz monitors the log and checks if others are ressing the same target, so if there are unreleased corpses around you but the button is not lit up, this means that either someone else casted a resurrection on that corpse, or the corpse is out of range.


## 1.2. Messages
Up to 200 random messages in total can be configured. The addon ships with 20 pre-configured messages, containing quotes from famous World of Warcraft bosses.
 

## 1.3. Advanced messages
All messages - or macros - can be grouped into one of five different groups: GUILD, CHARACTER, CLASS, RACE and DEFAULT.

When a macro is in the GUILD group, the macro can only be used if the target belongs to the guild name, configured together with that macro.
Same goes for the CHARACTER group, where the macro can only be used if the configured name matches the target character's name. CLASS and RACE works in a similar way.

If the target being resurrected does not match any of the four above groups, the macro's in the DEFAULT group will be used instead.

All pre-configured macros are in the DEFAULT group, but you can click on a macro and reconfigure it as you like.

 

If the "Include Defaults in filtered macros" option is checked, then the default macro list will always be considered, also even the target may match macros in one or more of the other groups.

And last, the resurrection whisper can now also be customized.



## About Thaliz
Thaliz was a raiding priest in <Goldshire Golfclub> on the VanillaGaming.org World of Warcraft server, famous for dying alot. To be honest, we all died while progressing but he just stood out :-)

 

To recover faster from wipes, I wrote this simple addon to attempt to block "duplicate" resurrections, and respond with random macros while ressing - and that addon was named after the death-seeking priest: Thaliz!

Dying had never been funnier since that!

 

Thaliz (the priest) ultimately died mid 2016 when he deleted his account.

RIP Thaliz.
