# Research Report: Statistical Analysis

## Overview

This report summarises findings from our latest dataset review.

## Greek Notation Used in Statistics

Statistical formulas frequently use Greek letters that fall outside the Windows-1252 character set supported by Prawn's built-in PDF fonts:

- **Alpha** (significance level): α = 0.05
- **Beta** (type II error rate): β = 0.20
- **Sigma** (standard deviation): σ
- **Mu** (population mean): μ
- **Delta** (change / difference): Δ

## Mathematical Symbols

The following mathematical symbols are also outside Windows-1252:

- Summation: ∑
- Infinity: ∞
- Not equal to: ≠
- Greater than or equal to: ≥
- Less than or equal to: ≤
- Element of: ∈

## Conclusion

Any document containing characters such as α, β, σ, ∑, ∞, or ≠ will trigger
`Prawn::Errors::IncompatibleStringEncoding` when rendered with Prawn's built-in
fonts, because those fonts only support the Windows-1252 encoding.
