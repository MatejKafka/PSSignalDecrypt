# Signal Desktop config decryption tool

Signal Desktop stores all messages in an encrypted database, which is encrypted with an installation-specific encryption key, which is protected using DPAPI on Windows.

This PowerShell script generates a new Signal config file containing the equivalent plaintext encryption key instead of the DPAPI-protected key and returns it. To move the Signal Desktop installation to a different machine:

1. Close Signal Desktop.

2. Run `Unprotect-SignalConfig.ps1`. It should return a PowerShell object containing the patched config.

3. Replace `%APPDATA%\Signal\config.json` with the output of the script:
  ```powershell
  .\Unprotect-SignalConfig.ps1 | ConvertTo-Json | Set-Content $env:APPDATA\Signal\config.json
  ```

4. Move the `%APPDATA%\Signal` directory to the new machine.

5. Run Signal Desktop on the new machine. It should automatically replace the plaintext key with a DPAPI-protected version for the new machine.

