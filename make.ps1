$blogDir = "C:\Users\z124t\Documents\website\blog"
$current = (Get-Location)
hugo --destination $blogDir
cd $blogDir
git ci -am "Updated blog"
git push -u origin master
cd $current
