#!/bin/bash

seleniumJavaVersion=2.47.1
seleniumJavaUrl="http://selenium-release.storage.googleapis.com/${seleniumJavaVersion%.*}/selenium-java-$seleniumJavaVersion.zip"
seleniumJavaChecksum="9e3d3274b10480b7c0f9c5f314ef8c9200427927"

cucumberCoreVersion=1.2.4
cucumberCoreUrl="http://central.maven.org/maven2/info/cukes/cucumber-core/$cucumberCoreVersion/cucumber-core-$cucumberCoreVersion.jar"
cucumberCoreChecksum="72790b1da44d8d3d2764c6aef29865ee228bbeb1"

cucumberJavaVersion=1.2.4
cucumberJavaUrl="http://central.maven.org/maven2/info/cukes/cucumber-java/$cucumberJavaVersion/cucumber-java-$cucumberJavaVersion.jar"
cucumberJavaChecksum="57cca534b7abe43f6dd7624b90d3d97d33d3023d"

cucumberJvmDepsVersion=1.0.5
cucumberJvmDepsUrl="http://central.maven.org/maven2/info/cukes/cucumber-jvm-deps/$cucumberJvmDepsVersion/cucumber-jvm-deps-$cucumberJvmDepsVersion.jar"
cucumberJvmDepsChecksum="69ed0efe4b81f05da3c0bdc7281cbdc43f5ceb26"

gherkinVersion=2.12.2
gherkinUrl="http://central.maven.org/maven2/info/cukes/gherkin/$gherkinVersion/gherkin-$gherkinVersion.jar"
gherkinChecksum="017138631fa20fd0e44a13e50d6b7be59cee1a94"

junitVersion=4.12
junitUrl="http://central.maven.org/maven2/junit/junit/$junitVersion/junit-$junitVersion.jar"
junitChecksum="2973d150c0dc1fefe998f834810d68f278ea58ec"

mockitoVersion=1.10.19
mockitoUrl="http://central.maven.org/maven2/org/mockito/mockito-all/$mockitoVersion/mockito-all-$mockitoVersion.jar"
mockitoChecksum="539df70269cc254a58cccc5d8e43286b4a73bf30"

cd "${0%/*}/.."
if [ ! ${PWD##*/} == "JSC" ]; then
  echo "Please run this script from the JSC directory."
  exit
fi

clear

echo "Downloading dependencies..."; echo
function check()
{
  filepath=$1
  expectedSha=$2
  if [ -f $filepath ]; then
    actualSha=$(openssl sha1 $filepath | sed 's/^.* //')
    if [ $actualSha == $expectedSha ]; then
      return 0
    else
      rm $filepath
      return 2
    fi
  else
    return 1
  fi
}
function download()
{
  url=$1
  expectedSha=$2
  filename=${url##*/}
  filepath="lib/$filename"
  check $filepath $expectedSha
  if [ $? == 0 ]; then return; fi
  curl $url > $filepath
  check $filepath $expectedSha
  case $? in
    0)
      return 0
      ;;
    1)
      echo; echo "Unable to download $url.  Please try again."; echo
      exit
      ;;
    2)
      echo; echo "Invalid checksum for $1.  Please try again."; echo
      exit
      ;;
  esac
}
download $seleniumJavaUrl $seleniumJavaChecksum
if [ ! -d "lib/selenium-$seleniumJavaVersion" ]; then unzip "lib/selenium-java-$seleniumJavaVersion.zip" -d lib; fi
download $cucumberCoreUrl $cucumberCoreChecksum
download $cucumberJavaUrl $cucumberJavaChecksum
download $cucumberJvmDepsUrl $cucumberJvmDepsChecksum
download $gherkinUrl $gherkinChecksum
download $junitUrl $junitChecksum
download $mockitoUrl $mockitoChecksum
clear
echo "Successfully downloaded dependencies!"; echo

seleniumJavaJar="lib/selenium-$seleniumJavaVersion/selenium-java-$seleniumJavaVersion.jar"
seleniumJavaSrcsJar="lib/selenium-$seleniumJavaVersion/selenium-java-$seleniumJavaVersion-srcs.jar"
seleniumLibJars="lib/selenium-$seleniumJavaVersion/libs/*"
seleniumJars="$seleniumJavaJar:$seleniumJavaSrcsJar:$seleniumLibJars"
cucumberJavaJar="lib/cucumber-java-$cucumberJavaVersion.jar"
cucumberCoreJar="lib/cucumber-core-$cucumberCoreVersion.jar"
cucumberJvmDepsJar="lib/cucumber-jvm-deps-$cucumberJvmDepsVersion.jar"
gherkinJar="lib/gherkin-$gherkinVersion.jar"
cucumberAllJars="$cucumberJavaJar:$cucumberCoreJar:$cucumberJvmDepsJar:$gherkinJar"
junitJar="lib/junit-$junitVersion.jar"
mockitoJar="lib/mockito-all-$mockitoVersion.jar"

echo "Compiling src/Main.java ..."
javac \
  -d target \
  -cp "$junitJar:$seleniumJars:$cucumberJavaJar:$cucumberCoreJar" \
  -XDsuppressNotes \
  src/Main.java
if [ $? -ne 0 ]; then exit; fi
echo "Successfully compiled src/Main.java!"; echo

echo "Compiling test/JUnitTest.java ..."
javac \
  -d target \
  -cp "target:$junitJar:$seleniumJars:$cucumberJavaJar:$mockitoJar" \
  -XDsuppressNotes \
  test/JUnitTest.java
if [ $? -ne 0 ]; then exit; fi
echo "Successfully compiled test/JUnitTest.java!"; echo

java \
  -cp "target:$junitJar:$seleniumJars:$cucumberJavaJar:$cucumberCoreJar" \
  com.jsc.Main \
  > log/JSC.log
case $? in
  0)
    ;;
  123)
    echo "Error: unable to fetch list of stocks from Yahoo! Finance.  Please try again later."; echo
    exit
    ;;
  234)
    echo "Error: unable to fetch price from Google Finance.  Please try again later."; echo
    exit
    ;;
  *)
    exit
    ;;
esac

echo "Running unit tests ..."
java \
  -cp "target:$junitJar:$seleniumJars:$cucumberJavaJar:$cucumberCoreJar:$mockitoJar" \
  -XX:MaxJavaStackTraceDepth=3 \
  org.junit.runner.JUnitCore \
  com.jsc.JUnitTest
if [ $? -ne 0 ]; then exit; fi
echo "Unit tests passed!"; echo

echo "Running Cucumber scenario ..."
java \
  -cp "target:$junitJar:$seleniumJars:$cucumberAllJars" \
  cucumber.api.cli.Main \
  --strict \
  --glue com.jsc \
  --plugin pretty \
  features
if [ $? -ne 0 ]; then exit; fi
echo "Cucumber scenario passed!"; echo

rm -rf lib/*

if [ `uname` == Darwin ]; then
  open img/success.jpg
else
  xdg-open img/success.jpg
fi
