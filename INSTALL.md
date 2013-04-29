## Installation

Copy the 'weather' and the 'kite' directories onto your Kindle's SD card.

Adjust the 'downloadIP' in the 'weather.conf' file.

Kite is required to invoke the script from the user interface.

Kite comes from here:

http://www.mobileread.com/forums/showthread.php?t=168270

And please have a look at the projekt 'kite-kindle4nt'.


## Note

All scripts are compatible with the dash and bash shell on your host system.

So you can test your configuration on the host system.

To leave the launcher hit ENTER.

(I use the Ubuntu LTS 12.04.)

Good luck!


## Partial directory structure on your Kindle internal SD card

```
/mnt/us
│
├── kite
│   ├── onboot
│   ├── ondrop
│   └── Weather
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
