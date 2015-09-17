# coderesign
This is a tool for resigning ipa package with your distribution provisioning profile.
### (Include Individual and Enterprise distribution provisioning profile)

# Requirements
* Mac OS 9.0 +
* Xcode6.0+ with development tools

# How to use
<code>coderesign -d /you/ipa/path/xx.ipa -p your_distribution.mobileprovision -e your_entitlements.plist -id com.your.newbundleID -ci certificates_index -py your-python</code>

# Support list:
* Support decompress the icon file from ipa.
* Support check CPU construction for app.
* Support dump the specific app info.
* Support resign ipa file for Individual & Enterprise provision profile that related to developer or distribution cert.

### if you want to resign the third ipa package with Individual distribution provision profile
option -ci: App ID prefix should be passed that you can find this value from developer.apple.com when you creating app id. For example : "BXTP48X8WA"

### if you want to resign the third ipa package with Enterprise  distribution provision profile
option -ci: distribution name should be passed that you can find this value from keychain tools.
For example: "iPhone Distribution: Beijing xxx Network Technology Co., Ltd.", you should only pass "Beijing xxx Network Technology Co., Ltd".

# License
These specifications and coderesign are available under the MIT license.

# Screenshot of running result:
![Image text](https://raw.githubusercontent.com/0x4d4746h/coderesign/master/result_screenshot.png)


