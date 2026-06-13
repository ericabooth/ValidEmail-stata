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
net install validemail, from("https://raw.githubusercontent.com/ericbooth/ValidEmail-stata/master/")
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

## Authors
**Eric A. Booth**  
eric.a.booth@gmail.com  
[https://github.com/ericbooth/ValidEmail-stata](https://github.com/ericbooth/ValidEmail-stata)

## License
MIT
