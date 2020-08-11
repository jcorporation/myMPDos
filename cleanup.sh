#!/bin/bash
#
# SPDX-License-Identifier: GPL-2.0-or-later
# myMPD (c) 2018-2020 Juergen Mang <mail@jcgames.de>
# https://github.com/jcorporation/mympd
#

echo "Cleanup"
[ -d tmp ] || exit 0
rm -fr tmp
exit 0
