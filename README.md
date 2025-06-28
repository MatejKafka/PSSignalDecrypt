# Signal Desktop config decryption tool

Requires [PowerShell 6 or higher](https://github.com/PowerShell/PowerShell/releases/), the built-in version of PowerShell 5 in Windows 10 will not work.

---

Signal Desktop stores all messages in a database encrypted with an installation-specific encryption key, which is protected using DPAPI on Windows. As a result, if you just copy the `%APPDATA%\Signal` directory to a new computer, it will be unable to decrypt it.

This PowerShell script generates a new Signal config file containing the equivalent plaintext encryption key instead of the DPAPI-protected key and returns it. To move the Signal Desktop installation to a different machine:

1. Close Signal Desktop.
2. Run `Unprotect-SignalConfig.ps1`. It should return a PowerShell object containing the patched config.
3. Replace `%APPDATA%\Signal\config.json` with the output of the script:
  ```powershell
  .\Unprotect-SignalConfig.ps1 | ConvertTo-Json | Set-Content $env:APPDATA\Signal\config.json
  ```
4. Move the `%APPDATA%\Signal` directory to the new machine.
5. Run Signal Desktop on the new machine. It should automatically replace the plaintext key with a DPAPI-protected version for the new machine.

