#! /usr/bin/env python

import os
import sys
import subprocess
import time
import threading
from uiautomator import Device

def dialog():
    if d(text="Make Phone your default Phone app?").exists:
        d(text="SET DEFAULT").click.wait()
    if d(text="Use Messaging instead of LightOS as your SMS app?").exists:
        d(text="YES").click.wait()
    if d(text="Use LightOS as Home").exists:
        d.click(240, 500)
    if d(text="Use Launcher3 as Home").exists:
        d(text="ALWAYS").click.wait()

def select_wifi():
    if d(text="arimaguest").exists:
        d(text="arimaguest").click.wait()
        d(text="Forget Network").click.wait()
    else:
        d.click(419, 300)
        i=360
        while i <= 600:
            d.click(419, i)
            if d(text="arimaguest").exists:
                d(text="arimaguest").click.wait()
                return
            i+=30

def screen_on():
    d.screen.on()

serial = sys.argv[1]
d = Device(serial)

# set up uiautomator
t = threading.Thread(target = screen_on)
t.start()
time.sleep(60)
subprocess.call("adb -s " + str(serial) + " shell input keyevent 26",shell=True)
time.sleep(2)
subprocess.call("adb -s " + str(serial) + " shell input tap 259 413",shell=True)
t.join()

d(text="CONTINUE").wait.exists(timeout=30)
d(text="CONTINUE").click.wait()
d(text="CONNECT TO WIFI").click.wait()
while d(text="Connect To Wifi").exists:
    select_wifi()
    time.sleep(20)

while not d(text="INSTALL").exists:
    d.screen.on()
    time.sleep(3)

d(text="INSTALL").click.wait()
if d(text="REBOOT LIGHTOS").exists:
    d(text="REBOOT LIGHTOS").click.wait()
time.sleep(60)

# change light os to android os
d.screen.on()
subprocess.call("adb -s " + str(serial) + " shell input keyevent 24 25 24 25 25 KEYCODE_STOP_RECORD",shell=True)
dialog()
dialog()
dialog()
dialog()

# turn off WiFi
subprocess.call("adb -s " + str(serial) + " shell svc wifi disable",shell=True)
