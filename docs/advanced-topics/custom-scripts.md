---
layout: page
permalink: /advanced-topics/custom-scripts
title: Run a custom script from myMPD client
---

To run a script from the myMPD client that needs root privileges, the script must be configured to be able to run through `doas`. `doas` is a small and secure replacement for `sudo`.

First, configure the script to run as root with the help of `doas`:

```
# Create the file /etc/doas.d/custom.conf
permit nopass mympd cmd /root/my-script.sh
```

Next, run a syntax check for `doas`:

```
doas -C /etc/doas.d/custom.conf
```

Finally, add the script in the myMPD client, calling it with `doas`:

```
result = mympd.os_capture("doas /root/my-script.sh")
return result
```
