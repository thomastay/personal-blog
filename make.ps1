param(
  [Parameter(Mandatory = $true)][string]$message,
  [Switch]$localHugo,
  [Switch]$NoPush
)
$hugoPath = "C:\Users\z124t\scoop\shims\hugo.exe" 
if ($localHugo) {
  $hugoPath = "C:\Users\z124t\source\repos\hugo\hugo.exe"
}
$blogDir = "C:\Users\z124t\Documents\website\blog"
$current = (Get-Location)
Start-Process -FilePath $hugoPath -ArgumentList "--destination $blogDir" -NoNewWindow
Set-Location $blogDir
git add . -A
git ci -m $message
if (-Not $NoPush) {
  git push -u origin master
}
Set-Location $current
