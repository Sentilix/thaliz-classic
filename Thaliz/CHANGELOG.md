# classic-0.6.0 (2020-xx-xx)

* The configuration panel and the CLI has been reworked:
  * The configuration panel is now available in the dedicated _Addons_ tab from the Blizzard _Interface_ menu (or by using the `/thaliz config` command)
  * UI settings are now grouped in different tabs according to their objectives
  * The number of messages is no more limited to 200
  * You can now enable the private message (whisp) independently from the public ones (raid/party, say or yell)
  * The `/thaliz` command is now the only one available (`/thalizversion` and others concatenated commands have been removed).
  * The `/thaliz debug` command is now hidden from the UI and the CLI help, as it should be used by advanced users only
* Removed the message displayed in chat when enabling/disabling the resurrection messages feature
* Standardized the wording about the messages send when rezing someone: these are now only called "messages" (not macros or announcements)

# classic-0.3.0
--------------------------
* Fixed lua bug when not in raid/party
* Fixed nil player names
* Added target name to button (lets see if it works out)
* Bugfix: Blacklisting of players works now.
