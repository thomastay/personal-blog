param(
  [Parameter(Mandatory = $true)][string]$message
)
$blogDir = "C:\Users\z124t\Documents\website\blog"
$current = (Get-Location)
hugo --destination $blogDir
Set-Location $blogDir
git add . -A
git ci -m $message
git push -u origin master
Set-Location $current
