# Signal Desktop config decryption tool

Requires [PowerShell 6 or higher](https://github.com/PowerShell/PowerShell/releases/), the built-in version of PowerShell 5 in Windows 10/11 will not work.

---

Signal Desktop stores all messages in a database encrypted with an installation-specific encryption key, which is protected using DPAPI on Windows. As a result, if you just copy the `%APPDATA%\Signal` directory to a new computer, Signal will be unable to decrypt it.

This PowerShell script generates a new Signal config file containing the equivalent plaintext encryption key instead of the DPAPI-protected key and returns it. To move the Signal Desktop installation to a different machine:

1. Close Signal Desktop.
3. Replace the Signal config file with the decrypted version by running `.\Unprotect-SignalConfig.ps1 -Update`. If you do not want to update the config file and only return the decrypted content, omit the `-Update` flag.
4. Move the `%APPDATA%\Signal` directory to the new machine.
5. Run Signal Desktop on the new machine. It should automatically replace the plaintext key with a DPAPI-protected version for the new machine.

