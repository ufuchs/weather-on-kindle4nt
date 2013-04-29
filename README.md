weather-on-kindle4nt
=====================

## Features

- Doesn't need any crontab usage

- Caches the last successfully downloaded weather file until it expires at 24:00
  (So you can take away your 'weather station' in the pub and show it all your friends.)

- Could invoke within a wrapper called 'launcher.sh'

- The download is written in the '/tmp' directory which is a temporary filesystem(32M), living in the memory
