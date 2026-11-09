*! test_validemail.do - Test script for validemail.ado
*! Eric A. Booth
*! 2026-11-09 (format and disposable checks are asserted; DNS results
*! depend on your network and are listed for inspection)

clear
set more off

* Force Stata to use the local version in this folder FIRST
* (run this file from the repository folder)
cap adopath ++ "`c(pwd)'"
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
* gmail.com should be 2 (validated_ip blank here because mx was used)
* nonexistent should be 1
* mailinator should be 3
* invalid-email should be 0

di _n(2) "{title:Validation Successful if Statuses match expectations}"
tab status2

* 6. Network-independent checks (format, disposable flag, row order)
assert status2 == 0 if inlist(email, "invalid-email", "bad@format@extra.com", "spaces in@email.com")
assert status2 == 0 if inlist(email, "multiple..dots@gmail.com", ".startwithdot@test.com", "endwithdot.@test.com")
assert status2 >= 1 if inlist(email, "valid.user@gmail.com", "user+tag@example.org", "CAPS@DOMAIN.COM")
assert validated_disposable == 1 if inlist(email, "test@mailinator.com", "test@10minutemail.com")
assert validated_disposable == 0 if !inlist(email, "test@mailinator.com", "test@10minutemail.com")
assert email[1] == "valid.user@gmail.com" & email[14] == "test@10minutemail.com"
di as res "ALL TESTS PASSED"
