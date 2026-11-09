{smcl}
{* *! version 2.2.1  09nov2026}{...}
{hline}
help for {hi:validemail}
{hline}

{title:Title}

{p 4 8 2}{hi:validemail} {hline 2} Email address validation using Regex, DNS/MX lookups, and disposable domain detection


{title:Syntax}

{p 4 8 2}
{cmd:validemail} {it:varname} [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt gen:erate(newvar)}}New variable for validation status codes (Default: validated_status){p_end}
{synopt:{opt dns(newvar)}}New variable for extracted domains (Default: validated_domain){p_end}
{synopt:{opt ip(newvar)}}New variable for the domain's first resolved address (Default: validated_ip){p_end}
{synopt:{opt dispos:able(newvar)}}New variable indicating disposable email domains (Default: validated_disposable){p_end}
{synopt:{opt mx}}Check for MX (Mail Exchanger) records instead of simple A records{p_end}
{synopt:{opt low:ercase}}Convert emails to lowercase before validation{p_end}
{synopt:{opt mergereport}}Display a tabulation of the validation results{p_end}
{synopt:{opt regex(string)}}Override the default format pattern{p_end}
{synoptline}


{title:Description}

{p}{cmd:validemail} provides a multi-stage validation for email address variables. It performs:
{p_end}
{p 4 8 2}1. {bf:Regex Check}: Verifies the format matches standard email patterns. Leading and trailing spaces are ignored; a space inside the address makes it invalid. The default pattern also rejects a local part or domain that starts or ends with a dot or contains two dots in a row.{p_end}
{p 4 8 2}2. {bf:Disposable Check}: Compares domains, ignoring case, against a list of known disposable email providers (e.g., mailinator.com).{p_end}
{p 4 8 2}3. {bf:DNS/MX Lookup}: Uses {cmd:nslookup} to verify the domain exists and can receive mail (if {cmd:mx} is specified).{p_end}

{p}A lookup passes only when {cmd:nslookup} returns an answer for the domain: an address line under a {cmd:Name:} line for the default A lookup, or a {cmd:mail exchanger} line with {opt mx}. The Server/Address lines that describe your own DNS server do not count. Domains that return NXDOMAIN, "can't find", "Non-existent domain" or "No answer" get status 1. Domains that contain characters other than letters, digits, dots and hyphens (possible only with a custom {opt regex()}) are not passed to the shell and get status 1. If {cmd:nslookup} produces no output at all, {cmd:validemail} prints a warning.{p_end}

{title:Status Codes}

{p}The {opt generate()} variable contains the following codes:{p_end}
{p 4 8 2}{bf:0}: Invalid format (Regex failed){p_end}
{p 4 8 2}{bf:1}: Valid format, but DNS/MX lookup failed (domain might not exist){p_end}
{p 4 8 2}{bf:2}: Valid format and DNS/MX lookup passed{p_end}
{p 4 8 2}{bf:3}: Valid format and DNS/MX passed, but the domain is a known disposable provider{p_end}


{title:Options}

{p 0 4}{opt gen:erate(newvar)} specifies the name of the new variable to hold the validation status. {p_end}

{p 0 4}{opt dns(newvar)} specifies the name of the new variable to hold the domain extracted from the email. {p_end}

{p 0 4}{opt ip(newvar)} specifies the name of the new variable to hold the first address that {cmd:nslookup} returns for the domain in its answer section. The address of your own DNS server is never stored. {opt ip()} is blank when the lookup fails and when {opt mx} is specified (MX answers list mail servers, not addresses). {p_end}

{p 0 4}{opt dispos:able(newvar)} specifies the name of the new 0/1 variable that marks addresses at a known disposable email provider. {p_end}

{p 0 4}{opt mx} instructs the command to specifically look for MX (Mail Exchanger) records. This is a more accurate way to verify if a domain is configured to receive emails. {p_end}

{p 0 4}{opt low:ercase} converts all email addresses to lowercase before validation. This is recommended as email domains are case-insensitive. {p_end}

{p 0 4}{opt mergereport} displays a summary table of the validation results using the generated status codes. {p_end}

{p 0 4}{opt regex(string)} allows you to provide a custom regular expression for the initial format check. It replaces the default pattern, {cmd:^[a-zA-Z0-9_%+-]+(\.[a-zA-Z0-9_%+-]+)*@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{c -(}2,{c )-}$}. {p_end}


{title:Examples}

{p 4 8 2}1. Basic validation of an email variable:{p_end}
{p 8 12 2}{cmd:. validemail email_address, mergereport}{p_end}

{p 4 8 2}2. Strict validation with MX check and lowercase conversion:{p_end}
{p 8 12 2}{cmd:. validemail email, mx lowercase generate(email_status) mergereport}{p_end}

{p 4 8 2}3. Using a custom regex:{p_end}
{p 8 12 2}{cmd:. validemail email, regex("^[a-z]+@[a-z]+\.com$")}{p_end}


{title:Changes}

{p 4 8 2}2.2.1 (09nov2026): runs when the temporary-file folder has a space in its name (it stopped with r(198)); an address with a space inside is now invalid format instead of being squeezed shut; the default pattern rejects leading, trailing, and doubled dots; the disposable check ignores case.{p_end}

{p 4 8 2}2.2.0 (09nov2026): the resolver header no longer counts as a DNS pass, so nonexistent domains get status 1; {opt ip()} now holds the domain's address; a user variable named {cmd:dns_valid} is left alone; row order is preserved; temporary files are removed on all systems; data with no valid-format address no longer stops with an error.{p_end}


{title:Author}

{p 4 4 2}Eric A. Booth{p_end}
{p 4 4 2}eric.a.booth@gmail.com{p_end}
{p 4 4 2}{browse "https://github.com/ericabooth/ValidEmail-stata"}{p_end}

{title:Also See}

{p 4 4 2}Online: {help ustrregexm}; the {cmd:nslookup} program that ships with your operating system{p_end}
