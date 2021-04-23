# Location of the 'cloud save' folder
# NOTE: This CAN be variable so will need to expand to a detection selector/User settable
$cloud_save_dir='~\Google Drive\Cloud Saves\Kingdom Hearts 1.5+2.5 ReMix'

## These are all constants that never change
# The name of the application (when launched)
$epic_app='KINGDOM HEARTS HD 1.5+2.5 ReMIX'
# Full launcher URI com.epicgames.launcher://apps/68c214c58f694ae88c2dab6f209b43e4?action=launch&silent=true
$epic_app_launch_uri='com.epicgames.launcher://apps/68c214c58f694ae88c2dab6f209b43e4?action=launch&silent=true'
# The name of the save files
$KHFM_save_file='KHFM.png'
$KHCoM_save_file='KHCoM.png'

# Location of the 'local save' folder
# NOTE: This is NEVER variable as this is where KH is designed to make it's save files
$local_save_dir='~\Documents\KINGDOM HEARTS HD 1.5+2.5 ReMIX\Epic Games Store\0d8153b07f0043778a5d3fc0a6f6f6c7'

# Name of the 'backup' folder used in each location
$save_backups='SaveBackup'
$local_save_backup_dir="$local_save_dir\$save_backups"

_cloud_sync_file($save_file){
    # Derive some handles so we don't need to do these over and over
    $folder_name = $save_file.TrimEnd(".png")
    $save_basename = $folder_name
    $save_folder_cloud = $cloud_save_dir/$folder_name
    $local_save = $local_save_dir/$save_file
    $local_backup_folder = $local_save_dir/$save_backups/$folder_name

    # Say what we are doing in the launcher output
    Write-Output "Starting cloud sync"

    ## Get the time stamp of the newest cloud save
    # Check if the save folder exists on the cloud
    if ( Test-Path -Path $save_folder_cloud -PathType Container) {
            # If it does, find newest cloud save
            $newest_cloud = Get-ChildItem $save_folder_cloud | Sort-Object -Descending LastWriteTime | Select-Object -First 1
            # Otherwise just set the newest_cloud to '' (empty)
    } else { $newest_cloud = '' }
    # If there are no cloud saves yet (Folder does not exists OR exists but no items are in it)
    if ( $newest_cloud -eq '' ) {
        # Set the cloud save TS to 0 so the local save always wins
        $newest_cloud_ts = '0'
    } else {
        # Otherwise get the TS off the newest cloud save
        # NOTE: Get-ChildItem returns just the NAME, so the DIR needs to be added back in
        $newest_cloud_ts = Get-Date ( (Get-ItemProperty -Path $save_folder_cloud\$newest_cloud).lastWriteTime ) -UFormat %Y%m%d.%H%M
    }

    ## Get the time stamp off the local save file
    # If the save file exists
    if ( Test-Path -Path $local_save -PathType Leaf ) {
        # Get the TS off of it
        $local_save_ts = Get-Date ( (Get-ItemProperty -Path "$local_save").lastWriteTime) -UFormat %Y%m%d.%H%M
    } else {
        # If the save file is NOT there at all - this is OK, just
        # set the local save TS to '0' so the cloud save will always be newer
        $local_save_ts = '0'
    }

    ## Now that all the timestamps have been derived - Figure out which is newer
    if ( $newest_cloud_ts -gt $local_save_ts ) {
        Write-Output "Cloud is newer than local ($newest_cloud_ts > $local_save_ts) - Backing up local and copying down cloud save"
        
        # If the local backup folder is missing
        if ( -not(Test-Path -Path $local_backup_folder -PathType Container) ) {
            # Make it
            Write-Output "Making local save backup folder: $local_save_backup_folder"
            New-Item -ItemType Directory -Path $local_backup_folder
        }
        # Move the current local save to the backup and date stamp it
        Move-Item -Path "$local_save" -Destination "$local_backup_folder/$save_basename-$local_save_ts.png"
        # Copy the newest cloud save to the local save slot
        Copy-Item "$save_folder_cloud/$newest_cloud" -Destination "$local_save"
    }
    # If the local save is newer than the cloud
    elseif ( $local_save_ts -gt $newest_cloud_ts ) {
        # Check first if the save file's folder exists in the cloud, and make it if it's missing
        if ( -not(Test-Path -Path $save_folder_cloud -PathType Container) ) {
            # Make the missing game save folder in the cloud organizer folder
            New-Item -ItemType Directory -Path $cloud_save_dir -Name $folder_name
        }

        # Copy the local save file to the cloud folder and date-stamp it
        Write-Output "Local is newer than cloud ($local_save_ts > $newest_cloud_ts) - Copying local to cloud"
        Copy-Item "$local_save" -Destination "$save_folder_cloud/$save_basename-$local_save_ts.png"
    }
    # If the local and cloud files hae the same datestamp
    elseif ( $local_save_ts -eq $newest_cloud_ts) {
        # Do nothing
        Write-Output "Local is the same as cloud - nothing to do"
    }

}

Function _test_cloud_sync_paths {
    $script:cloud_test='pass'
    if ( Test-Path -Path $cloud_save_dir -PathType Container ) {
        # Nothing to do
    } else {
        Write-Output "WARNING: Could not find Cloud save file location $cloud_save_dir"
        Write-Output "  Skipping cloud sync"
        $script:cloud_test='fail'
    }

    if ( Test-Path -Path $local_save_dir -PathType Container ) {
        # Nothing to do
    } else {
        Write-Output "WARNING: Could not find Local save file location $local_save_dir"
        Write-Output "  Skipping cloud sync"
        $script:cloud_test='fail'
    }
}

Function _launch_game {
    # Launch the app
    Write-Output "Launching: $epic_app_launch_uri"
    Write-Output "  Waiting for $epic_app to complete"
    Start-Process $epic_app_launch_uri
    Start-Sleep -Seconds 20
    Wait-Process $epic_app

    # After it exits report that it's closed
    Write-Output " $epic_app has exited - Checking if there's a new save to sync"
}

# Test that all the paths needed for cloud syncing are present
_test_cloud_sync_paths
if ( $cloud_test -eq 'pass' ) {
    # If so - do a cloud sync before starting the game
    foreach ($_save in @($KHFM_save_file, $KHCoM_save_file) ) {
        _cloud_sync_file $_save
    }
} else { Write-Output "Cloud Test failed - skiping cloud sync" }
# Start the game
_launch_game
# After the game exits - run the sync again (no need to re-check paths)
if ( $cloud_test -eq 'pass' ) {
    foreach ($_save in @($KHFM_save_file, $KHCoM_save_file) ) {
        _cloud_sync_file $_save
    }
} else { Write-Output "Cloud Test failed - skiping cloud sync" }
Write-Output "Closing in 2 seconds"
Start-Sleep -Seconds 2