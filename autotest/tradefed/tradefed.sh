#!/bin/bash -el

project=$1
fastboot_artifact=$2
autotest_artifact=$3
testcase=$4
flasher=$5

if [ -z "$testcase" ]; then
  testcase=$project
fi
if ! [ -z "$flasher" ]; then
  flasher="--flasher-class $flasher"
fi

rm -rf tmp
mkdir tmp
cd tmp
mv ../$fastboot_artifact .
7z x $fastboot_artifact
zip -j fastboot.zip fastboot_bin/*

java -cp "/opt/tradefed/*" com.android.tradefed.command.CommandRunner arima/${testcase} --serial=${project}AAAAAAAAAAA ${flasher}

for z in 0/stub/**/*.zip; do unzip ${z}; done
mv 0/stub/**/test*.html test_result.html
mv 0/stub/**/*.jpeg .
zip -r ../${autotest_artifact} *.txt *.html *.jpeg

cd ..
rm -rf tmp
