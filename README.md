# Powershell script to both perform cloud sync of KHFM save file AND launch the game via Eipc Store (for DRM)

## Background

Normally copying your save file to a cloud sync service (e.g. Dropbox, Google Backup & Sync, ect.) is how manual save file cloud sync is accomplished these days.  However I personally ran into several instances of the save file getting corrupted during gameplay and erasing one or more of my save slots (and then refusing to make a new save slot) - forcing me to (while the game was still running) re-initialize the save file for the game and save over the new file again.  

This is my "there must be a better way" attempt that replicates, very roughly, how a Steam or GOG cloud sync would work.  The methods in this script are fairly abstracted already and could pretty easily be re-used to do cloud syncing for a multitude of other games that lack a sync feature.

## Features

    - Does a pre game launch check to see if the cloud or local copy are newer than one-another and copies over the newest version to the appropriate location
    - Launches the game from the Epic game store (DRM requirement)
    - Waits for the game to exit (w/out spinlock) so it's compatable with Steam or other global-library launch contols
        - Compatable with GLoSC
    - Does a post game launch check to see if the cloud or local copy are newer than one-another and copies over the newest version to the appropriate location
    - Works with any cloud file sync service that presents a local folder on your system

## How it works

Docs to come

## Limitations

    - You'll need to enable script execution rights for you local user to use this tool
    - Currenlty this is only written to sync KHFM.png (the Kingdom Hearts save file)
        - Support for additional save files coming soon
    - Needs a cloud sync location on the local PC backed by a cloud service (e.g. Dropbox, Google Backup & Sync, ect.)