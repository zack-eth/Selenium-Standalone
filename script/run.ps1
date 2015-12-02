$seleniumJavaVersion = '2.47.1'
$seleniumJavaUrl = "http://selenium-release.storage.googleapis.com/$($seleniumJavaVersion -replace '.[^.]*$','')/selenium-java-$seleniumJavaVersion.zip"
$seleniumJavaChecksum = '9e3d3274b10480b7c0f9c5f314ef8c9200427927'

$cucumberCoreVersion = '1.2.4'
$cucumberCoreUrl = "http://central.maven.org/maven2/info/cukes/cucumber-core/$cucumberCoreVersion/cucumber-core-$cucumberCoreVersion.jar"
$cucumberCoreChecksum = '72790b1da44d8d3d2764c6aef29865ee228bbeb1'

$cucumberJavaVersion = '1.2.4'
$cucumberJavaUrl = "http://central.maven.org/maven2/info/cukes/cucumber-java/$cucumberJavaVersion/cucumber-java-$cucumberJavaVersion.jar"
$cucumberJavaChecksum = '57cca534b7abe43f6dd7624b90d3d97d33d3023d'

$cucumberJvmDepsVersion = '1.0.5'
$cucumberJvmDepsUrl = "http://central.maven.org/maven2/info/cukes/cucumber-jvm-deps/$cucumberJvmDepsVersion/cucumber-jvm-deps-$cucumberJvmDepsVersion.jar"
$cucumberJvmDepsChecksum = '69ed0efe4b81f05da3c0bdc7281cbdc43f5ceb26'

$gherkinVersion = '2.12.2'
$gherkinUrl = "http://central.maven.org/maven2/info/cukes/gherkin/$gherkinVersion/gherkin-$gherkinVersion.jar"
$gherkinChecksum = '017138631fa20fd0e44a13e50d6b7be59cee1a94'

$junitVersion = '4.12'
$junitUrl = "http://central.maven.org/maven2/junit/junit/$junitVersion/junit-$junitVersion.jar"
$junitChecksum = '2973d150c0dc1fefe998f834810d68f278ea58ec'

$mockitoVersion = '1.10.19'
$mockitoUrl = "http://central.maven.org/maven2/org/mockito/mockito-all/$mockitoVersion/mockito-all-$mockitoVersion.jar"
$mockitoChecksum = '539df70269cc254a58cccc5d8e43286b4a73bf30'

cd (get-item (Split-Path $MyInvocation.MyCommand.Path)).parent.FullName
if ((Split-Path $pwd -Leaf) -ne ‘JSC’)
{
  Write-Host Please run this script from the JSC directory.
  exit
}

cls

Write-Host Downloading dependencies...
function download($url, $sha1)
{
  $file = $url.substring($url.lastindexof('/') + 1)
  $filepath = (Get-Location).Path + '\lib\' + $file
  $check = check $filepath $sha1
  if ($check -eq 0) { return }
  $client = new-object System.Net.WebClient
  $client.UseDefaultCredentials = $true
  $client.DownloadFile($url, $filepath)
  $check = check $filepath $sha1
  if ($check -eq 0)
  {
    return
  }
  ElseIf ($check -eq 1)
  {
    Write-Host "`nUnable to download $file.  Please try again.`n"
    exit
  }
  ElseIf ($check -eq 2)
  {
    Write-Host "`nInvalid checksum for $file.  Please try again.`n"
    exit
  }
}
function check($filepath, $sha1)
{
  if (Test-Path -Path $filepath)
  {
    $service = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider
    $computedSha1 = [System.BitConverter]::ToString($service.ComputeHash([System.IO.File]::ReadAllBytes($filepath)))
    if ($computedSha1.replace('-','').tolower() -eq $sha1) { return 0 }
    else
    {
      Remove-Item $filepath
      return 2
    }
  }
  return 1
}
function unzip($file, $folder)
{
  if (Test-Path ((Get-Location).Path + "\lib\$folder") -PathType Container) { return }
  $shell_app = new-object -com shell.application
  $zip_file = $shell_app.namespace((Get-Location).Path + "\lib\$file")
  $destination = $shell_app.namespace((Get-Location).Path + '\lib')
  $destination.Copyhere($zip_file.items())
}
download $seleniumJavaUrl $seleniumJavaChecksum
unzip "selenium-java-$seleniumJavaVersion.zip" "selenium-$seleniumJavaVersion"
download $cucumberCoreUrl $cucumberCoreChecksum
download $cucumberJavaUrl $cucumberJavaChecksum
download $cucumberJvmDepsUrl $cucumberJvmDepsChecksum
download $gherkinUrl $gherkinChecksum
download $junitUrl $junitChecksum
download $mockitoUrl $mockitoChecksum
Write-Host Successfully downloaded dependencies!`n

$seleniumJavaJar = "lib\selenium-$seleniumJavaVersion\selenium-java-$seleniumJavaVersion.jar"
$seleniumJavaSrcsJar = "lib\selenium-$seleniumJavaVersion\selenium-java-$seleniumJavaVersion-srcs.jar"
$seleniumLibJars = "lib\selenium-$seleniumJavaVersion\libs\*"
$seleniumJars = "$seleniumJavaJar;$seleniumJavaSrcsJar;$seleniumLibJars"
$cucumberJavaJar = "lib\cucumber-java-$cucumberJavaVersion.jar"
$cucumberCoreJar = "lib\cucumber-core-$cucumberCoreVersion.jar"
$cucumberJvmDepsJar = "lib\cucumber-jvm-deps-$cucumberJvmDepsVersion.jar"
$gherkinJar = "lib\gherkin-$gherkinVersion.jar"
$cucumberAllJars = "$cucumberJavaJar;$cucumberCoreJar;$cucumberJvmDepsJar;$gherkinJar"
$junitJar = "lib\junit-$junitVersion.jar"
$mockitoJar = "lib\mockito-all-$mockitoVersion.jar"

Write-Host Compiling src\Main.java ...
javac `
  -encoding UTF-8 `
  -d target `
  -cp "$junitJar;$seleniumJars;$cucumberJavaJar;$cucumberCoreJar" `
  -XDsuppressNotes `
  src\Main.java
if ($LASTEXITCODE -ne 0) { exit }
Write-Host Successfully compiled src/Main.java!`n

Write-Host Compiling test\JUnitTest.java ...
javac `
  -d target `
  -cp "target;$junitJar;$seleniumJars;$cucumberJavaJar;$mockitoJar" `
  -XDsuppressNotes `
  test\JUnitTest.java
if ($LASTEXITCODE -ne 0) { exit }
Write-Host Successfully compiled test\JUnitTest.java!`n

java `
  -cp "target;$junitJar;$seleniumJars;$cucumberJavaJar;$cucumberCoreJar" `
  com.jsc.Main `
  > log/JSC.log
if ($LASTEXITCODE -eq 123) {
  Write-Host Error: unable to fetch list of stocks from Yahoo! Finance.  Please try again later.`n
  exit
}
ElseIf ($LASTEXITCODE -eq 234) {
  Write-Host Error: unable to fetch price from Google Finance.  Please try again later.`n
  exit
}
ElseIf ($LASTEXITCODE -ne 0) {
  exit
}

Write-Host Running unit tests ...
java `
  -cp "target;$junitJar;$seleniumJars;$cucumberJavaJar;$cucumberCoreJar;$mockitoJar" `
  -XX:MaxJavaStackTraceDepth=3 `
  org.junit.runner.JUnitCore `
  com.jsc.JUnitTest
if ($LASTEXITCODE -ne 0) { exit }
Write-Host Unit tests passed!`n

Write-Host Running Cucumber scenario ...`n
java `
  -cp "target;$junitJar;$seleniumJars;$cucumberAllJars" `
  cucumber.api.cli.Main `
  --strict `
  --glue com.jsc `
  --plugin pretty `
  --monochrome `
  features
if ($LASTEXITCODE -ne 0) { exit }
Write-Host Cucumber scenario passed!`n

Remove-Item lib\*.* -recurse

.\img\success.png
