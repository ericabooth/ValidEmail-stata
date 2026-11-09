*! validemail.ado  Email Validation via Regex, DNS/MX Check, and Disposable Domain Detection
*! version 2.2.0  2026-11-09
*! Eric A. Booth <eric.a.booth@gmail.com>
*
* Changelog
*   2.2.0  2026-11-09  DNS/MX parser rewritten: the resolver's own Server/Address
*                      header no longer counts as a pass, so NXDOMAIN and
*                      "can't find" domains get status 1; mx requires a
*                      "mail exchanger" answer. ip() now holds the domain's first
*                      A-record address (was always blank). The DNS flag is a
*                      tempvar, so a user variable named dns_valid is no longer
*                      dropped or misread. Row order is preserved. Temporary
*                      nslookup files are removed with erase (the old shell rm
*                      was Unix-only and never matched). Domains with
*                      characters other than letters, digits, dots and hyphens
*                      are not passed to the shell and get status 1. Data with
*                      no valid-format address no longer stops with r(2000).
*   2.1.1  2024-06-13  Previous release.

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

    * Default Regex
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
        
        * Initialize Disposable (ip() is created by the DNS merge below)
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
    tempvar dnsok order
    loc n_skipped = 0
    loc n_noout = 0

    qui {
        g double `order' = _n
        preserve
        keep if `generate' == 1
        keep `dns'
        if _N > 0 duplicates drop `dns', force

        loc n_domains = _N

        if `n_domains' > 0 {
            * 1. Store domain names in locals to survive 'clear'
            forval i = 1/`n_domains' {
                loc d`i' = `dns'[`i']
            }

            noi di as text "Checking DNS/MX for `n_domains' unique domains..."
            loc type = cond("`mx'" != "", "-type=MX", "")
            loc mxflag = ("`mx'" != "")

            tempname memhold
            tempfile master_dns
            postfile `memhold' str255 `dns' str255 `ip' byte `dnsok' using `master_dns', replace

            forval i = 1/`n_domains' {
                loc d_name `"`d`i''"'
                loc resfile `"`email_results'_`i'.txt"'
                loc ve_valid = 0
                loc ve_ip ""

                * Only plain host names reach the shell (letters, digits,
                * dots, hyphens; first character a letter or digit).
                if ustrregexm(`"`d_name'"', "^[A-Za-z0-9][A-Za-z0-9.-]*$") {
                    * nslookup is an external program, so a shell call is required
                    cap erase `"`resfile'"'
                    qui !nslookup `type' `d_name' > "`resfile'" 2>&1
                    mata: _validemail_parse(st_local("resfile"), `mxflag')
                    if `ve_out' == 0 loc ++n_noout
                    cap erase `"`resfile'"'
                }
                else loc ++n_skipped

                post `memhold' (`"`d_name'"') (`"`ve_ip'"') (`ve_valid')

                * Progress
                if mod(`i', 5) == 0 | `i' == `n_domains' {
                    noi di as text "." _continue
                }
            }
            noi di ""
            postclose `memhold'

            * Load the results and save to dns_list
            use `master_dns', clear
            duplicates drop `dns', force
            save "`dns_list'", replace
        }
        restore

        * Merge results back to main dataset
        if `n_domains' > 0 {
            merge m:1 `dns' using "`dns_list'", nogenerate keep(master match)
            sort `order'

            * Update Status
            replace `generate' = 2 if `generate' == 1 & `dnsok' == 1
            replace `generate' = 3 if `generate' == 2 & `disposable' == 1
            drop `dnsok'
            compress `ip'
        }
        else g `ip' = ""
        order `ip', before(`disposable')
        drop `order'
    }

    if `n_skipped' > 0 {
        di as text "Note: `n_skipped' domain(s) contain characters other than letters, digits, dots and hyphens; not looked up (status 1)."
    }
    if `n_noout' > 0 {
        di as error "Warning: nslookup returned no output for `n_noout' domain(s). Check that nslookup is installed and on your PATH."
    }

    * Report results
    di as smcl `"{hline}"'
    di as text "Email Validation Report for {bf:`varlist'}"
    di as text "Status codes in {bf:`generate'}:"
    
    qui count if `generate' == 0
    di as text "  0: Invalid format: " _col(35) as result r(N)
    
    qui count if `generate' == 1
    di as text "  1: Valid format, DNS/MX fail: " _col(35) as result r(N)
    
    qui count if `generate' == 2
    di as text "  2: Valid format, DNS/MX pass: " _col(35) as result r(N)
    
    qui count if `generate' == 3
    di as text "  3: Valid format, Disposable: " _col(35) as result r(N)
    di as smcl `"{hline}"'

    if "`mergereport'" != "" {
        capture label drop evstatus
        label define evstatus 0 "Invalid Format" 1 "DNS Fail" 2 "Valid" 3 "Disposable"
        label values `generate' evstatus
        tab `generate'
    }

end

* Parse one nslookup result file.
* Returns locals ve_valid (1 = lookup passed), ve_ip (first answer address,
* A lookups only) and ve_out (1 = file had any output).
* The resolver header (Server:/Address:) is never an answer: an A pass needs
* an Address(es): line after a Name: line in the same block. An MX pass needs
* a "mail exchanger" line. NXDOMAIN, "can't find" and "Non-existent domain"
* produce no such lines, so they fail.
mata:
void _validemail_parse(string scalar fn, real scalar mx)
{
    real scalar fh, valid, inans, nlines, c
    string scalar line, low, val, ip
    string matrix eof

    valid = 0
    inans = 0
    nlines = 0
    ip = ""
    eof = J(0, 0, "")
    if (fileexists(fn)) {
        fh = _fopen(fn, "r")
        if (fh >= 0) {
            while ((line = fget(fh)) != eof) {
                line = strtrim(subinstr(line, char(13), ""))
                if (line == "") {
                    inans = 0
                    continue
                }
                nlines++
                low = strlower(line)
                if (mx) {
                    if (strpos(low, "mail exchanger")) valid = 1
                    continue
                }
                if (substr(low, 1, 5) == "name:") {
                    inans = 1
                    continue
                }
                if (inans & (substr(low, 1, 8) == "address:" | substr(low, 1, 10) == "addresses:")) {
                    c = strpos(line, ":")
                    val = strtrim(substr(line, c + 1, .))
                    if (val != "") {
                        valid = 1
                        if (ip == "") ip = val
                    }
                }
            }
            fclose(fh)
        }
    }
    st_local("ve_valid", strofreal(valid))
    st_local("ve_ip", ip)
    st_local("ve_out", strofreal(nlines > 0))
}
end
