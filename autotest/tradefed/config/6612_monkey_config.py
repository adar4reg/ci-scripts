# Created By   : Dick Tsai
# Created Date : Tue Jun 11 2019
# Description  : Set up device before running monkey test

import sys
import time
from uiautomator import Device

d = Device(sys.argv[1])
d.screen.on()

# unlock screen
d.swipe(0, 800, 0, 0)

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
while d(text="ON", className="android.widget.Switch").exists:
   d(text="ON", className="android.widget.Switch").click.wait()
   time.sleep(10)
   while d(text="Close app").exists:
      d(text="Close app").click.wait()

d.press("back")
d.press("back")
d.press("back")

# Display -> Choose "Never"
d(scrollable=True).scroll.to(text="Display")
d(text="Display").click.wait()
d(text="Advanced").click.wait()
d(text="Sleep").click.wait()
d(text="30 minutes").click.wait()
d.press("back")

# Security -> Choose Screen lock "None"
d(scrollable=True).scroll.to(text="Security & location")
while d(text="Security & location").exists:
   d(text="Screen lock").click.wait()
d(text="None").click.wait()
d.press("back")

# Stay Awake > On
d(scrollable=True).scroll.to(text="About phone")
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
d(scrollable=True).scroll.to(text="Developer options")
d(text="Developer options").click.wait()
d(scrollable=True).scroll.to(text="Stay awake")
d(text="Stay awake").right(text="OFF", className="android.widget.Switch").click.wait()
d.press("home")
