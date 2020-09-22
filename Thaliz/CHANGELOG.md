# classic-0.6.0 (2020-xx-xx)

* The addon now works with the 8 following localized clients: brazilian portuguese, chinese, english, french, german, korean, russian, spanish
* The configuration panel and the CLI has been reworked:
  * Every configuration setting can be set either by the configuration panel or the CLI
  * The configuration panel is now available in the dedicated _Addons_ tab from the Blizzard _Interface_ menu (or by using the `/thaliz config` command)
  * The `/thaliz` command is now the only one available (`/thalizversion` and others concatenated commands have been removed).
  * The `/thaliz debug` command is now hidden from the UI and the CLI help, as it should be used by advanced users only

# classic-0.3.0
--------------------------
* Fixed lua bug when not in raid/party
* Fixed nil player names
* Added target name to button (lets see if it works out)
* Bugfix: Blacklisting of players works now.
