# What's it
* This is a tool for resigning ipa package with your distribution provisioning profile.
* Include Individual and Enterprise distribution provisioning profile

# Requirements
* Mac OS 9.0 +
* Xcode6.0+ with development tools

# How to use
#### code resign and decompress icon png.
<pre>coderesign -d /you/ipa/path/xx.ipa -p your_distribution.mobileprovision -ci certificates_index -py your-python</pre>
Or
<pre>coderesign -d /you/ipa/path/xx.ipa -p your_distribution.mobileprovision -ex your_extension_distribution.mobileprovision -wp your_watchkitapp_distribution_mobileprovision -ci certificates_index -py your-python</pre>
#### only code resign
<pre>coderesign -d /you/ipa/path/xx.ipa -p your_distribution.mobileprovision  -ci certificates_index</pre>
Or
<pre>coderesign -d /you/ipa/path/xx.ipa -p your_distribution.mobileprovision -ex your_extension_distribution.mobileprovision -wp your_watchkitapp_distribution_mobileprovision -ci certificates_index</pre>
#### only decompress icon png.
<pre>coderesign -d /you/ipa/path/xx.ipa -py your-python</pre>

# Support list:
* Support resign normal app, watch kit extension, watch kit app, widget extension and swift dylibs.
* Support decompress the icon file from ipa.
* Support check CPU construction for app.
* Support dump the specific app info.
* Support resign ipa file for Individual & Enterprise provision profile that related to developer or distribution cert.

# One More Thing:
#### if you want to resign the third ipa package with Individual distribution provision profile
option -ci: App ID prefix should be passed that you can find this value from developer.apple.com when you creating app id, or find it from keychain tools if you have been installed the cert. 
For example : "MM776WPM62", you can find it from keychain tool
<pre>iPhone Developer: Miao guangfa (MM776WPM62)</pre>

#### if you want to resign the third ipa package with Enterprise  distribution provision profile
option -ci: distribution name should be passed that you can find this value from keychain tools.
For example: "iPhone Distribution: Beijing xxx Network Technology Co., Ltd.", you should only pass "Beijing xxx Network Technology Co., Ltd".

# Screenshot of running result:
![Image text](https://raw.githubusercontent.com/0x4d4746h/coderesign/master/result_screenshot.png)

# Usage:
Enter <pre>coderesign</pre> and return, or
Enter <pre>coderesign -h</pre>and return.
![Image text](https://raw.githubusercontent.com/0x4d4746h/coderesign/master/Usage.png)

# License
These specifications and coderesign are available under the MIT license.




