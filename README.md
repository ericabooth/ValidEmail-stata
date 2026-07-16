# ValidEmail-stata: Email Validation for Stata

`validemail` is a Stata command that provides robust validation for email addresses. It goes beyond simple format checking by verifying domain existence via DNS/MX lookups and identifying disposable email providers.

## Features
- **Regex Validation**: Uses ICU regular expressions (`ustrregexm`) for robust format checking.
- **DNS/MX Lookups**: Verifies that the email domain actually exists and is configured to receive mail.
- **Disposable Email Detection**: Identifies domains from common temporary email services (e.g., Mailinator).
- **Batch Processing**: Efficiently checks unique domains to minimize network overhead.
- **Status Codes**: Provides detailed validation results (Format Error, DNS Failure, Valid, Disposable).
- **Customizable**: Support for custom regex patterns and case-insensitive matching.

## Installation
You can install `validemail` directly from GitHub in Stata:
```stata
net install validemail, from("https://raw.githubusercontent.com/ericabooth/ValidEmail-stata/main/") replace force
help validemail
```

## Syntax
```stata
validemail varname [, options]
```

### Options
- `generate(newvar)`: New variable for validation status (Default: `validated_status`).
- `mx`: Check for MX (Mail Exchanger) records (Recommended).
- `lowercase`: Convert emails to lowercase before checking.
- `mergereport`: Show a summary table of results.
- `dns(newvar)`: Save extracted domains.
- `ip(newvar)`: Save resolved IP addresses.

### Status Codes
- **0**: Invalid format (Regex failed).
- **1**: Valid format, but DNS/MX lookup failed (domain might not exist).
- **2**: Valid format and DNS/MX lookup passed.
- **3**: Valid format and DNS/MX passed, but the domain is a known disposable provider.

## Examples

### 1. Basic Validation
```stata
validemail email_address, mergereport
```

### 2. Comprehensive Validation with MX Check
```stata
validemail email, mx lowercase generate(email_status) mergereport
```

### 3. Identify Disposable Emails
```stata
validemail email, disposable(is_temp)
tab is_temp
```

###Test script
```stata
*! test_validemail.do - Test script for validemail.ado
*! Eric A. Booth
*! 2024-06-13

clear
set more off

* Force Stata to use the local version in this folder FIRST
cap adopath ++ "/Users/ebooth/Documents/GitHub/ValidEmail-stata"
cap program drop validemail
which validemail

* 1. Create dummy data with various email formats
input str60 email
"valid.user@gmail.com"
"invalid-email"
"user@nonexistent-domain-12345.com"
"test@mailinator.com"
"another.valid.one@yahoo.com"
"bad@format@extra.com"
"user+tag@example.org"
"spaces in@email.com"
"CAPS@DOMAIN.COM"
"multiple..dots@gmail.com"
".startwithdot@test.com"
"endwithdot.@test.com"
"valid@outlook.com"
"test@10minutemail.com"
end

* 2. Run basic validation
di _n(2) "{title:Test 1: Basic Validation}"
cap drop validated_*
validemail email, mergereport

* 3. Run validation with MX check and lowercase
di _n(2) "{title:Test 2: MX Check and Lowercase}"
cap drop validated_*
cap drop status2 domain2
validemail email, mx lowercase mergereport generate(status2) dns(domain2)

* 4. Display results
list email status2 domain2 validated_ip validated_disposable, abbrev(20)

* 5. Check specific results
* gmail.com should be 2
* nonexistent should be 1
* mailinator should be 3
* invalid-email should be 0

di _n(2) "{title:Validation Successful if Statuses match expectations}"
tab status2
```

## Authors
**Eric A. Booth**  
eric.a.booth@gmail.com  
[https://github.com/ericabooth/ValidEmail-stata](https://github.com/ericabooth/ValidEmail-stata)

## License
MIT
