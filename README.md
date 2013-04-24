kindle4nt-weather
=================

Note : All scripts are compatible with the dash and bash shell on your host system.
       Output will be written in the '/tmp' directory.
       Adjust the 'downloadIP' in the 'waether.conf' file and you can start.
       I use the Ubuntu LTS 12.04.

Features:

- Doesn't need any crontab usage

- Caches the last successfully downloaded weather file until it expires at 24:00
  (So you can take away your 'weather station' in the pub and show it your friends.)

- Could invoke within a wrapper called 'launcher.sh'

- The download is written in the '/tmp' directory which is a temporary filesystem, living in the memory

Installation:

Copy this directory onto your Kindle's SD card and rename it to 'weather'.

You need 'Kite' to start 'weather.sh'

Kite is available at:

  http://www.mobileread.com/forums/showpost.php?p=2373962&postcount=43

In the Kite directory lives a shell script called 'Weather'.

It contains the following 2 lines:

```bash
#!/bin/sh
/mnt/us/weather/launcher.sh &
```

Good luck!


Partial directory structure on your SD card:

```
/mnt/us
│
├── kite
│   ├── onboot
│   ├── ondrop
│   └── Weather   #!/bin/sh
│                 /mnt/us/weather/launcher.sh &
│
└── weather
    ├── bin
    │   ├── platform.sh
    │   ├── properties.sh
    │   └── weatherProperties.sh
    ├── img
    │   ├── flightmode-on.png
    │   ├── service-unavailable.png
    │   ├── weather-outdated.png
    │   └── wlan-unavailable.png
    ├── launcher.sh
    ├── weather.conf
    └── weather.sh
```