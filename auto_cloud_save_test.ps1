# Local save file DIR
$local_save_dir = '~\Documents\KINGDOM HEARTS HD 1.5+2.5 ReMIX\Epic Games Store\0d8153b07f0043778a5d3fc0a6f6f6c7'
$local_save = "$local_save_dir\$game_save_file"
# Cloud save file DIR
$cloud_save_dir = '~\Google Drive\Cloud Saves\Manual - KH'
# Save file name (as the game expects and creates it)
$game_save_file = 'KHFM.png'
# Backup save folder name
$save_backups = 'SaveBackups'

Function _cloud_sync {

    if ( Test-Path -Path $cloud_save_dir -PathType Container ) {

        # Find the newest cloud save
        $script:newest_cloud = Get-ChildItem $cloud_save_dir | Sort-Object -Descending LastWriteTime | Select-Object -First 1
        # NOTE: Get-ChildItem returns just the NAME, so the DIR needs to be added back in
        $script:newest_cloud_ts = Get-Date ((Get-ItemProperty -Path "$cloud_save_dir\$newest_cloud").lastWriteTime.DateTime) -UFormat %Y%m%d.%H%M

        Write-Output "Got newest cloud: $newest_cloud"
        Write-Output "  Cloud timestamp: $newest_cloud_ts"
    }

    if ( Test-Path -Path $local_save_dir -PathType Container ) {

        # Figure out when the local save was last updated
        $script:local_save_ts = Get-Date ((Get-ItemProperty -Path "$local_save").lastWriteTime.DateTime) -UFormat %Y%m%d.%H%M

        Write-Output "Got local save: $local_save"
        Write-Output "  Loal timestamp: $local_save_ts"
    }

    # Figure out which is newer
    if ( $newest_cloud_ts -gt $local_save_ts ) {
        Write-Output "Cloud is newer than local - Want to copy to local"
        Write-Output "  Would: Test-Path $local_save_dir/$save_backups"
        Write-Output "  Would: mv $local_save_dir/$game_save_file $local_save_dir/$save_backups/KHFM-$local_save_ts.png"
        Write-Output "  Would: cp $cloud_save_dir/$newest_cloud $local_save_dir"
    }
    elseif ( $local_save_ts -gt $newest_cloud_ts ) {
        Write-Output "Local is newer than cloud - want to copy to cloud"
        Write-Output "  Would: cp $local_save_dir/$game_save_file $cloud_save_dir/KHFM-$local_save_ts.png"
    }
    elseif ( $local_save_ts -eq $newest_cloud_ts) {
        Write-Output "Local is the same as cloud - nothing to do"
    }
}

_cloud_sync