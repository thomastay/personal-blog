param(
  [Switch]$NoBrowser
)

if (-Not $NoBrowser) {
  Start-Job {
    Start-Sleep -Seconds 0.3
    Start-Process 'http://localhost:1313/blog/'
  }
}
hugo server -D
