---
title: Control MPD and myMPD with buttons
---

myGPIOd supports natively MPD and myMPD.

All the examples are enabling the internal pull-up resistors, there is no need for an external one. Simply connect one side of the button to the pin and the other to ground. Debouncing is done through libgpiod (1000 ns debounce period).

## Control MPD

The `mpc` action can execute all available [MPD protocol](https://mpd.readthedocs.io/en/latest/protocol.html) commands.

In this example GPIO number 19 is used to go to the next song in the queue.

**/etc/mygpiod.d/19.in**

```ini
event_request = falling
bias = pull-up
debounce = 1000
action_falling = mpc:next
```

## Control myMPD

The `mympd` action executes myMPD scripts. It connects to the myMPD API on localhost.

In this example GPIO number 21 is used to call a script named `Jukebox` in the partition `default`.

**/etc/mygpiod.d/21.in**

```ini
event_request = falling
bias = pull-up
debounce = 1000
action_falling = mympd:https://127.0.0.1 default Jukebox
```
