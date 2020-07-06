param(
  [Switch]$NoBrowser
)

if (-Not $NoBrowser) {
  Start-Job {
    Start-Sleep -Seconds 0.3
    Start-Process 'http://localhost:1313/blog/'
  }
}
$hugoPath = "C:\Users\z124t\source\repos\hugo\hugo.exe"
& $hugoPath server -D
