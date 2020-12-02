# Thaliz - Resurrection addon for WoW classic

## What is it

This addon targets a friendly (unreleased) corpse. If there are many corpses, the target will be prioritized in the following order:

- Highest priority to the corpse you are currently targetting (if any)

- then other ressers are resurrected

- then mana users are resurrected

- then warriors are resurrected

- and last the rogues.

If no Warlocks are up, one Warlock will be ressed after ressers are up. The raid leader will get priority just below the ressers, as he is usually also the loot master.

When a corpse is being resurrected (unreleased or not), a random message is displayed on the screen. This can be configured to be either a /SAY, /YELL or in /RAID chat, together with an optional whisper to the target.
 
## How it works

Thaliz scan the raid for corpses. If a corpse is found and eligible for a res, the Thaliz action button will change icon to your current class (Priest, Paladin, Shaman or even Druid for battle res). This means the button is ready for use.

When you click the button, the actual res begins. If there are more than just one corpse, the priorities listed above is used.

## Messages

When a resurrection begins, Thaliz sends messages to a public channel and the private channel (whisp) to indicates that the resurrection is occuring.

By default, the public message is sent to the group or party channel.

The addon ships with 20 pre-configured messages, containing quotes from famous World of Warcraft bosses.

But you can add yours and entirely customize the way you're ressing people!

### Advanced message configuration

Each message can also be configured to be used only if the target being resurrected matches one of the following conditions:
* a character
* a guild
* a class
* a race

If the target being resurrected does not match any of the four conditions above, the messages without conditions will be used instead.

If the "Add messages for everyone to the list of targeted messages" option is checked, then the messages without conditions will always be considered, also even the target may match macros in one or more of the other groups.

And last, the resurrection whisper can now also be customized.

## About the Thaliz character

Thaliz was a raiding priest in <Goldshire Golfclub> on the VanillaGaming.org World of Warcraft server, famous for dying alot. To be honest, we all died while progressing but he just stood out :-)

To recover faster from wipes, I wrote this simple addon to attempt to block "duplicate" resurrections, and respond with random macros while ressing - and that addon was named after the death-seeking priest: Thaliz!

Dying had never been funnier since that!

 
Thaliz (the priest) ultimately died mid 2016 when he deleted his account.

RIP Thaliz.
