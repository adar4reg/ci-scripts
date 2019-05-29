# Created By   : Dick Tsai
# Created Date : Mon May 27 2019
# Description  : Set up device before running monkey test

import sys
import time
from uiautomator import Device

d = Device(sys.argv[1])
d.screen.on()

d(text="START").wait.exists(timeout=30)

# language
d(text="START").click.wait()

# connect to mobile network
d(text="SKIP").click.wait()

# connect to wi-fi
d(text="SKIP").click.wait()
d(text="CONTINUE").click.wait()

# date & time
d(text="NEXT").click.wait()

# google services
d(text="MORE").click.wait()
d(text="MORE").click.wait()
d(text="ACCEPT").click.wait()

# protect your phone
d(text="Not now").click.wait()
d(text="SKIP ANYWAY").click.wait()

# accelerated location
d(text="NEXT").click.wait()

# open settings
d(resourceId="com.google.android.googlequicksearchbox:id/search_widget_google_logo").wait.exists(timeout=30)
d.open.quick_settings()
d(resourceId="com.android.systemui:id/settings_button").click.wait()

# turn off WiFi
d(scrollable=True).scroll.to(text="Network & internet")
d(text="Network & internet").click.wait()
if d(text="ON", className="android.widget.Switch").exists:
   d(text="ON", className="android.widget.Switch").click.wait()
d.press("back")

# turn off bt
d(scrollable=True).scroll.to(text="Connected devices")
d(text="Connected devices").click.wait()
d(text="Connection preferences").click.wait()
d(text="Bluetooth").click.wait()
if d(text="ON", className="android.widget.Switch").exists:
   d(text="ON", className="android.widget.Switch").click.wait()
d.press("back")
d.press("back")
d.press("back")

# Display -> Choose "Never"
d(scrollable=True).scroll.to(text="Display")
d(text="Display").click.wait()
d(text="Advanced").click.wait()
d(text="Sleep").click.wait()
d(text="Never").click.wait()
d.press("back")

# Security -> Choose Screen lock "None"
d(scrollable=True).scroll.to(text="Security & location")
while d(text="Security & location").exists:
   d(text="Screen lock").click.wait()
d(text="None").click.wait()
d.press("back")

# Stay Awake > On
d(scrollable=True).scroll.to(text="System")
d(text="About phone").click.wait()
d(scrollable=True).scroll.to(text="Build number")
d(text="Build number").click()
d(text="Build number").click()
d(text="Build number").click()
d(text="Build number").click()
d(text="Build number").click()
d(text="Build number").click()
d(text="Build number").click()
d.press("back")
d(text="System").click.wait()
d(text="Advanced").click.wait()
d(text="Developer options").click.wait()
d(scrollable=True).scroll.to(text="Stay awake")
d(text="Stay awake").right(text="OFF", className="android.widget.Switch").click.wait()
d.press("home")
