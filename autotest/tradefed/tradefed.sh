#!/bin/bash -el

project=$1
fastboot_artifact=$2
autotest_artifact=$3

rm -rf tmp
mkdir tmp
cd tmp
mv ../$fastboot_artifact .
7z x $fastboot_artifact
zip -j fastboot.zip fastboot_bin/*

java -cp "/home/jenkins/workspace/tradefed/lib/*" com.android.tradefed.command.CommandRunner arima/${project} --serial=${project}AAAAAAAAAAA
adb shell df -h > partition.txt
adb shell getprop | awk '{sub(/:/,"$")}1' | column -t -s $ > property.txt

for z in 0/stub/**/*.zip; do unzip ${z}; done
mv 0/stub/**/test*.html test_result.html
mv 0/stub/**/*.jpeg .
zip -r ../${autotest_artifact} *.txt *.html *.jpeg

cd ..
rm -rf tmp
