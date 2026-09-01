# OWASP Top 10 for Cloud Security — Project Mapping

A structured mapping of this project's work against the OWASP Top 10 for Cloud Security risk categories, each linked to relevant CWE (Common Weakness Enumeration) identifiers. This shows which real, industry-recognized risk categories the project addressed — and, just as importantly, which it didn't — rather than treating the checklist as complete coverage of "cloud security."

| # | OWASP Cloud Risk | Related CWE(s) | Addressed in this project? |
|---|---|---|---|
| 1 | Insecure Identities, Credentials, Secrets, and Access Management | CWE-798, CWE-287, CWE-306, CWE-522, CWE-259, CWE-269 | ✅ Least-privilege IAM policy, SSH key-only authentication |
| 2 | Insecure Interfaces and APIs | CWE-20, CWE-79, CWE-89, CWE-352, CWE-918 | ❌ Not directly tested |
| 3 | Misconfiguration and Inadequate Change Control | CWE-16, CWE-276, CWE-732, CWE-250 | ✅ Apache directory listing fix |
| 4 | Lack of Cloud Security Architecture and Strategy | CWE-657, CWE-668, CWE-284 | ✅ CIS Benchmark framework applied structurally |
| 5 | Insecure Software Development | CWE-20, CWE-79, CWE-89, CWE-502, CWE-94 | ❌ Not directly tested |
| 6 | Unsecured Third-Party Resources | CWE-829, CWE-1104, CWE-1357 | ❌ Not directly tested |
| 7 | System Vulnerabilities | CWE-1104, CWE-119, CWE-787, CWE-416 | ✅ Lynis scanning, patching, rkhunter/fail2ban |
| 8 | Accidental Cloud Data Disclosure | CWE-200, CWE-201, CWE-359, CWE-312 | ❌ Not directly tested |
| 9 | Misconfiguration of Cloud Services | CWE-16, CWE-732, CWE-284, CWE-276 | ✅ Partially — one Apache misconfiguration found and fixed |
| 10 | Insufficient Cloud Security Monitoring and Incident Response | CWE-778, CWE-223, CWE-117 | ✅ CloudWatch + CloudTrail configured and verified |

## Summary

**Directly addressed: 5 of 10 categories** (#1, #3, #4, #7, #10)
**Partially addressed: 1 of 10 categories** (#9)
**Not tested in this project: 4 of 10 categories** (#2, #5, #6, #8)

The categories not tested here (insecure APIs, insecure software development, third-party resources, and accidental data disclosure) are primarily relevant to application-development-heavy cloud environments — this project focused on infrastructure and identity hardening for a single EC2 instance, so those categories represent natural scope boundaries rather than oversights.
