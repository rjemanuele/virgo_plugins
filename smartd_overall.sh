#!/bin/sh

if [ $# != 1 ]; then
    echo Usage $0 \<disk device\>
    exit 1
fi

RESULT=`smartctl -H $1 2>&1 | head -1`
RETCODE=$?

# Make sure smartcrl ran by checking the $RESULT starting with "smartctl"
echo "$RESULT" | grep -qe '^smartctl'
RAN=$?

# We decode the return code according to the man page
# Bit 0: Command line did not parse.
# Bit 1: Device open failed, device did not return an IDENTIFY DEVICE structure, or device is in a low-power mode (see ´-n´ option above).
# Bit 2: Some SMART command to the disk failed, or there was a checksum error in a SMART data structure (see ´-b´ option above).
# Bit 3: SMART status check returned "DISK FAILING".
# Bit 4: We found prefail Attributes <= threshold.
# Bit 5: SMART status check returned "DISK OK" but we found that some (usage or prefail) Attributes have been <= threshold at some time in the past.
# Bit 6: The device error log contains records of errors.
# Bit 7: The device self-test log contains records of errors.  [ATA only] Failed self-tests outdated by a newer successful extended self-test are ignored.

if [ $RAN != 0 ]; then
    echo status err smrtctl failed to run
else
    echo status ok smartctl ran successfully
    echo metric parse_fail int $(($RETCODE & 1))
    echo metric device_open_fail int $(( ($RETCODE & 2) >>1 ))
    echo metric smart_command_fail int $(( ($RETCODE & 4) >> 2 ))
    echo metric disk_failing int $(( ($RETCODE & 8) >> 3 ))
    echo metric prefail int $(( ($RETCODE & 16) >> 4 ))
    echo metric past_prefail int $(( ($RETCODE & 32) >> 5 ))
    echo metric errors_logged int $(( ($RETCODE & 68) >> 6 ))
    echo metric selftest_errors_logged int $(( ($RETCODE & 128) >> 7 ))
fi
exit 0
