*! validemail.ado  Email Validation via Regex, DNS/MX Check, and Disposable Domain Detection
*! version 2.0.0  2024-06-13
*! Eric A. Booth <eric.a.booth@gmail.com>
*! 
*! Syntax:  
*!     validemail varname [, GENerate(name) DNS(name) MX IP(name) DISPOSable(name) Mergereport regex(string) lowercase] 
*! 
*! Status codes in GENerate():
*!     0: Invalid format (Regex failed)
*!     1: Valid format, DNS/MX check failed
*!     2: Valid format, DNS/MX check passed
*!     3: Valid format, DNS/MX passed, but domain is in disposable list

cap program drop validemail
program define validemail
    version 14.0
    syntax varlist(max=1) [,  GENerate(name) DNS(name) mx IP(name) DISPOSable(name) Mergereport regex(string) LOWercase]

    * Default variable names
    if `"`generate'"' == "" loc generate validated_status
    if `"`dns'"' == ""      loc dns validated_domain
    if `"`ip'"' == ""       loc ip validated_ip
    if `"`disposable'"' == "" loc disposable validated_disposable

    * Confirm variables don't exist
    foreach v in `generate' `dns' `ip' `disposable' {
        cap confirm variable `v', exact
        if !_rc {
            noi di in r as smcl `"Variable {stata desc `v':`v'} already exists. Specify new variables in options."'
            error 198
        }
    }

    * Default Regex (RFC 5322 compliant-ish but manageable)
    if `"`regex'"' == "" {
        loc regex "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    }

    qui {
        * Clean input
        tempvar clean_email
        g `clean_email' = trim(`varlist')
        replace `clean_email' = subinstr(`clean_email', " ", "", .)
        if "`lowercase'" != "" {
            replace `clean_email' = lower(`clean_email')
        }

        * Initial status: 0 (Invalid Format)
        g `generate' = 0
        
        * Regex Check (Status 1: Valid Format)
        replace `generate' = 1 if ustrregexm(`clean_email', "`regex'")
        
        * Extract domain
        g `dns' = ""
        replace `dns' = ustrregexs(1) if ustrregexm(`clean_email', "@(.*)$")
        replace `dns' = "" if `generate' == 0
        
        * Initialize IP and Disposable
        g `ip' = ""
        g `disposable' = 0
    }

    * Disposable Check
    noi di as text "Checking for disposable domains..."
    qui {
        loc d_list "mailinator.com 10minutemail.com guerrillamail.com temp-mail.org yopmail.com throwawaymail.com sharklasers.com getairmail.com maildrop.cc dispostable.com"
        foreach d in `d_list' {
            replace `disposable' = 1 if `dns' == "`d'"
        }
    }

    * DNS / MX Check
    tempfile email_results
    tempfile dns_list
    
    qui {
        preserve
        keep if `generate' == 1
        keep `dns'
        duplicates drop `dns', force
        tempvar domain_id
        g `domain_id' = _n
        loc n_domains = _N
        
        if `n_domains' > 0 {
            noi di as text "Checking DNS/MX for `n_domains' unique domains..."
            
            forval i = 1/`n_domains' {
                loc d_name = `dns'[`i']
                loc type = cond("`mx'" != "", "-type=MX", "")
                
                if `"`c(os)'"' == "MacOSX" | `"`c(os)'"' == "Unix" {
                    !nslookup `type' `d_name' > "`email_results'_`i'.txt"
                }
                else if `"`c(os)'"' == "Windows" {
                    !nslookup `type' `d_name' > "`email_results'_`i'.txt"
                }
                
                * Progress
                if mod(`i', 5) == 0 | `i' == `n_domains' {
                    noi di as text "." _continue
                }
            }
            noi di ""
            
            * Process results
            clear
            set obs 0
            g `dns' = ""
            g `ip' = ""
            g dns_valid = 0
            
            forval i = 1/`n_domains' {
                tempfile chunk
                cap qui import delimited "`email_results'_`i'.txt", clear delimiters("\n") varnames(nonames)
                if !_rc & _N > 0 {
                    loc d_current = ""
                    loc ip_current = ""
                    loc valid = 0
                    
                    forval j = 1/`=_N' {
                        loc line = v1[`j']
                        if strpos("`line'", "Name:") {
                            loc d_current = trim(subinstr("`line'", "Name:", "", 1))
                        }
                        if strpos("`line'", "Address:") {
                            loc ip_current = trim(subinstr("`line'", "Address:", "", 1))
                            loc valid = 1
                        }
                        if strpos("`line'", "mail exchanger") {
                            loc valid = 1
                        }
                    }
                    
                    * Fallback if Name/Address not matched exactly but lookup succeeded
                    if `valid' == 0 {
                        count if strpos(v1, "NXDOMAIN")
                        if r(N) == 0 {
                            * Check if there's any non-header info
                            count if _n > 2
                            if r(N) > 0 loc valid = 1
                        }
                    }
                    
                    set obs `=_N+1'
                    replace `dns' = "`d_name'" in L
                    replace dns_valid = `valid' in L
                    replace `ip' = "`ip_current'" in L
                }
                else {
                    * File not found or empty
                    set obs `=_N+1'
                    replace `dns' = "`d_name'" in L
                    replace dns_valid = 0 in L
                }
            }
            save "`dns_list'", replace
        }
        restore
        
        * Merge back
        merge m:1 `dns' using "`dns_list'", nogenerate keep(master match)
        
        * Update Status
        replace `generate' = 2 if `generate' == 1 & dns_valid == 1
        replace `generate' = 3 if `generate' == 2 & `disposable' == 1
        
        * Clean up intermediate variables
        drop dns_valid
    }

    * Report
    di as smcl `"{hline}"'
    di as text "Email Validation Report for {bf:`varlist'}"
    di as text "Status codes in {bf:`generate'}:"
    di as text "  0: Invalid format: " _col(25) as result `=(count(`generate') if `generate'==0)'
    di as text "  1: Valid format, DNS/MX fail: " _col(25) as result `=(count(`generate') if `generate'==1)'
    di as text "  2: Valid format, DNS/MX pass: " _col(25) as result `=(count(`generate') if `generate'==2)'
    di as text "  3: Valid format, Disposable: " _col(25) as result `=(count(`generate') if `generate'==3)'
    di as smcl `"{hline}"'

    if "`mergereport'" != "" {
        label define evstatus 0 "Invalid Format" 1 "DNS Fail" 2 "Valid" 3 "Disposable"
        label values `generate' evstatus
        tab `generate'
    }

    * Cleanup temp files
    cap shell rm "`email_results'_*.txt"
end
