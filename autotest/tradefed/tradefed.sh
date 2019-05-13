#!/bin/bash -el

project=$1
serial=$2
fastboot_artifact=$3
autotest_artifact=$4
testcase=$5
flasher=$6

if [ -z "$testcase" ]; then
  testcase="arima/$project"
fi
if ! [ -z "$flasher" ]; then
  flasher="--flasher-class $flasher"
fi

rm -rf tmp
mkdir tmp
cd tmp
mv ../$fastboot_artifact .
7z x $fastboot_artifact
cd fastboot_bin
zip -r ../fastboot.zip *
cd ..

java -cp "/opt/tradefed/*" com.android.tradefed.command.CommandRunner ${testcase} --log-level=debug --log-file-path=. --serial=${serial} ${flasher}

for z in 0/stub/**/*.zip; do unzip ${z}; done
mv 0/stub/**/test*.html test_result.html
mv 0/stub/**/*.jpeg .
zip -r ../${autotest_artifact} *.txt *.html *.jpeg

cd ..
rm -rf tmp
