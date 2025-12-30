Power on and off with GPIO
==========================

myMPDos can be configured to shutdown the Raspberry Pi safely with a
press of a button.

Configuration
-------------

- Connect a button to pin 5 (GPIO 3 SCL) and pin 6 (Ground).
- We use the internal pull-up resistor and do not need an external one.

.. code:: sh

   # Add the package mygpiod

   apk add mygpiod

   # Configure GPIO 3 (SCL)

   cat > /etc/mygpiod.d/3.in << EOL
   event_request = falling
   bias = pull-up
   debounce = 1000
   action_falling = system:/etc/mygpiod.scripts/shutdown.sh
   EOL

   # Add a script for shutdown

   mkdir /etc/mygpiod.scripts
   cat > /etc/mygpiod.scripts/shutdown.sh << EOL
   #!/bin/sh
   doas /usr/bin/saveshutdown.sh
   EOL
   chmod +x /etc/mygpiod.scripts/shutdown.sh

   # Configure doas

   echo "permit nopass mygpiod cmd /usr/bin/saveshutdown.sh" >> /etc/doas.d/mygpiod.conf

   # Enable and start the mygpiod service

   rc-update add mygpiod
   service mygpiod start

How it works
------------

Power on
~~~~~~~~

The WAKE_ON_GPIO powers on the the Raspberry Pi if you shorten pin 5
(GPIO 3 SCL) to ground.

Power off
~~~~~~~~~

The myGPIOd daemon listens on pin 5 (GPIO 3 SCL) and calls
``/etc/mygpiod.scripts/shutdown.sh``.

--------------

References
~~~~~~~~~~

- `myGPIOd <https://github.com/jcorporation/myGPIOd>`__
- https://www.raspberrypi.org/documentation/hardware/raspberrypi/bcm2711_bootloader_config.md
