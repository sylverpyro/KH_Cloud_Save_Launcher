# Location of the 'cloud save' folder
## NOTE: This CAN be variable so will need to expand to a detection selector/User settable
$cloud_save_dir='~\Google Drive\Cloud Saves\Manual - KH'

## These are all constants that never change
# The name of the application (when launched)
$epic_app='KINGDOM HEARTS HD 1.5+2.5 ReMIX'
# Full launcher URI com.epicgames.launcher://apps/68c214c58f694ae88c2dab6f209b43e4?action=launch&silent=true
$epic_app_launch_uri='com.epicgames.launcher://apps/68c214c58f694ae88c2dab6f209b43e4?action=launch&silent=true'
# The name of the save file
$KHFM_save_file='KHFM.png'
# Location of the 'local save' folder
## NOTE: This is NEVER variable as this is where KH makes it's save files
$local_save_dir='~\Documents\KINGDOM HEARTS HD 1.5+2.5 ReMIX\Epic Games Store\0d8153b07f0043778a5d3fc0a6f6f6c7'
$local_save = "$local_save_dir\$KHFM_save_file"

# Name of the 'backup' folder used in each location
$save_backups='SaveBackup'
$local_save_backup_dir="$local_save_dir\$save_backups"

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
Function _cloud_sync {
    Write-Output "Starting cloud sync"
    # Check if the CloudSave needs to be imported
    # Find the newest cloud save
    $script:newest_cloud = Get-ChildItem $cloud_save_dir | Sort-Object -Descending LastWriteTime | Select-Object -First 1
    # Special case: If there are no cloud saves yet
    if ( $newest_cloud -eq '' ) {
        # If there's no cloud saves yet - set the cloud save TS to 0 so the local save always wins
        $script:newest_cloud_ts = '0'
    } else {
        # Otherwise get the TS off the newest cloud save
        # NOTE: Get-ChildItem returns just the NAME, so the DIR needs to be added back in
        $script:newest_cloud_ts = Get-Date ((Get-ItemProperty -Path "$cloud_save_dir\$newest_cloud").lastWriteTime) -UFormat %Y%m%d.%H%M
    }
    # Special sub-case - if the local save directory exists BUT no save file is present
    # NOTE: This is TOTALLY OK, we just want to handle this situation
    if ( Test-Path -Path $local_save -PathType Leaf ) {
        # If the save file is there - get the TS off of it
        $script:local_save_ts = Get-Date ((Get-ItemProperty -Path "$local_save").lastWriteTime) -UFormat %Y%m%d.%H%M
    } else {
        # If the save file is NOT there
        # set the local save TS to '0' so the cloud save will always be newer
        $script:local_save_ts = '0'
    }
    
    # Now that all the timestamps have been derived - Figure out which is newer
    #Write-Output "Debug: local TS: $local_save_ts : $local_save"
    #Write-Output "Debug: cloud TS: $newest_cloud_ts : $cloud_save_dir/$newest_cloud"
    if ( $newest_cloud_ts -gt $local_save_ts ) {
        Write-Output "Cloud is newer than local ($newest_cloud_ts > $local_save_ts) - Backing up local and copying down cloud save"
        #Write-Output "  Would: Test-Path $local_save_backup_dir"
        if ( -not(Test-Path -Path "$local_save_backup_dir" -PathType Container) ) {
            # If the local backup save folder is missing, make it
            Write-Output "Making local save backup folder: $local_save_backup_folder"
            #Write-Output "  Would: New-Item -ItemType Directory -Path '$local_save_dir' -Name '$save_backups'"
            New-Item -ItemType Directory -Path "$local_save_dir" -Name "$save_backups"
        }
        #Write-Output "  Would: Move-Item -Path $local_save -Destination $local_save_backup_dir/KHFM-$local_save_ts.png"
        Move-Item -Path "$local_save" -Destination "$local_save_backup_dir/KHFM-$local_save_ts.png"
        #Write-Output "  Would: Copy-Item -Path $cloud_save_dir/$newest_cloud -Destination $local_save"
        Copy-Item "$cloud_save_dir/$newest_cloud" -Destination "$local_save"
    }
    elseif ( $local_save_ts -gt $newest_cloud_ts ) {
        Write-Output "Local is newer than cloud ($local_save_ts > $newest_cloud_ts) - Copying local to cloud"
        #Write-Output "  Would: Copy-Item -Path '$local_save_dir/$game_save_file' -Destination '$cloud_save_dir/KHFM-$local_save_ts.png'"
        Copy-Item "$local_save" -Destination "$cloud_save_dir/KHFM-$local_save_ts.png"
    }
    elseif ( $local_save_ts -eq $newest_cloud_ts) {
        Write-Output "Local is the same as cloud - nothing to do"
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
    _cloud_sync
} else { Write-Output "Cloud Test failed - skiping cloud sync" }
# Start the game
_launch_game
# After the game exits - run the sync again (no need to re-check paths)
if ( $cloud_test -eq 'pass' ) {
    _cloud_sync
} else { Write-Output "Cloud Test failed - skiping cloud sync" }
Write-Output "Closing in 2 seconds"
Start-Sleep -Seconds 2