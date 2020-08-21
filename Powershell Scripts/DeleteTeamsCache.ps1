#Deletes Teams Application Data and Cache

Write-Host "Deleting Teams Cache and Application Data" -ForegroundColor Cyan
[string] $teamsAppData = $env:APPDATA + '\Microsoft\Teams\'
$paths = New-Object Collections.Generic.List[String]
$paths.Add($teamsAppData + 'Application Cache\')
$paths.Add($teamsAppData + 'Blob_storage\')
$paths.Add($teamsAppData + 'Cache\')
$paths.Add($teamsAppData + 'databases\')
$paths.Add($teamsAppData + 'GPUCache\')
$paths.Add($teamsAppData + 'IndexedDB\')
$paths.Add($teamsAppData + 'Local Storage\')
$paths.Add($teamsAppData + 'tmp\')

Stop-Process -Name "Teams" -ErrorAction SilentlyContinue

ForEach ($path in $paths)
{
    cd $path -ErrorAction SilentlyContinue
    Remove-Item * -Recurse -ErrorAction SilentlyContinue
}
#[string] $teamsPath = $env:LOCALAPPDATA + '\Microsoft\Teams\'
#cd $teamsPath
#Start-Process -FilePath "Update.exe"
Write-Host "Complete. Feel free to launch Teams now." -ForegroundColor Green
cmd /c Pause