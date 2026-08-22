#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")"
printf -- '--- local tags ---\n'
git tag --list
printf -- '--- remote tags ---\n'
git ls-remote --tags origin
printf -- '--- workflows ---\n'
ls -1 .github/workflows
printf -- '--- ci ---\n'
ls -1 ci
