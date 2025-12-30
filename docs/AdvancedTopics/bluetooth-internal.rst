Internal Bluetooth
==================

Enabling internal bluetooth
---------------------------

If bluetooth is disabled, enable it.

.. code:: sh

   mount -oremount,rw /boot
   sed -i 's/dtoverlay=disable-bt/#dtoverlay=disable-bt/' /boot/usercfg.txt
   mount -oremount,ro /boot
   savereboot.sh

The Bluetooth controller is not automatically discovered on the UART.
Test attaching it and check that the controller is found.

.. code:: sh

   btattach -B /dev/ttyAMA0 -P bcm -S 115200 -N &
   /etc/init.d/bluetooth start

After that ``bluetoothctl list`` should list your bluetooth controller.

If the interface is discovered after the attach, you can make attaching
persistent by uncommenting the line next to “rpi bluetooth” in
``/etc/mdev.conf``.

.. code:: sh

   sed -i 's/^#ttyAMA0/ttyAMA0/' /etc/mdev.conf
