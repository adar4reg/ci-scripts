#!/bin/bash -el

project=$1
serial=$2
fastboot_artifact=$3
autotest_artifact=$4
flasher=$5
testcase=$6
tmp_folder="tmp_$serial"

if [ -z "$testcase" ]; then
  testcase="arima/$project"
fi

if ! [ -z "$flasher" ]; then
  flasher="--flasher-class $flasher"
fi

rm -rf $tmp_folder
mkdir $tmp_folder
cd $tmp_folder
7z x ../$fastboot_artifact -o./
cd fastboot_bin
zip -r -0 ../fastboot.zip *
cd ..

cp /opt/tradefed/tradefed-testcase-1.0-jar-with-dependencies.jar .
java -cp "./*" com.android.tradefed.command.CommandRunner ${testcase} --log-level=debug --log-file-path=. --serial=${serial} ${flasher}

for z in 0/stub/**/*.zip; do unzip ${z}; done
mv 0/stub/**/test*.html test_result.html
mv 0/stub/**/*.jpeg .
zip -r ../${autotest_artifact} *.txt *.html *.jpeg anr

cd ..
rm -rf $tmp_folder
