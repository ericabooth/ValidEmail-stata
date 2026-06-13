*! test_validemail.do - Test script for validemail.ado
*! Eric A. Booth
*! 2024-06-13

clear
set more off

* Ensure we are using the local version of the ado file
cap adopath + "/Users/ebooth/Documents/GitHub/ValidEmail-stata"
cap program drop validemail

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
* gmail.com should be 2 (or 3 if we add it to disposable, but it's not)
* nonexistent should be 1
* mailinator should be 3
* invalid-email should be 0

di _n(2) "{title:Validation Successful if Statuses match expectations}"
tab status2
