param(
    [string]$SignalDataDir = $env:APPDATA + "\Signal"
)

# Signal encrypts its database with an installation-specific encryption key; it uses the safeStorage
#  Electron API to protect the database encryption key, which internally uses the OSCrypt primitive
#  in Chromium; older Chromium versions use DPAPI to directly encrypt the OSCrypt data, newer versions
#  instead encrypt the data using AES256-GCM with an internal key, which is encrypted by DPAPI

# Signal database decryption source:
#  https://github.com/signalapp/Signal-Desktop/blob/main/app/main.ts#L1672
# safeStorage source:
#  https://github.com/electron/electron/pull/30020/files
# OSCrypt source:
#  https://source.chromium.org/chromium/chromium/src/+/main:components/os_crypt/sync/os_crypt_win.cc
# this is what implements the AES-GCM, including serializing the auth tag
#  https://github.com/google/boringssl/blob/master/crypto/fipsmodule/cipher/aead.c.inc
#  https://github.com/google/boringssl/blob/master/crypto/fipsmodule/cipher/e_aes.c.inc#L1006

# the internal OSCrypt key is stored in "Local State" JSON file in `os_crypt.encrypted_base`, base64-encoded and prefixed with "DPAPI"
$EncKey = cat -Raw "$SignalDataDir\Local State" | ConvertFrom-Json | % os_crypt | % encrypted_key | % {[convert]::FromBase64String($_)}
if ("DPAPI" -ne [System.Text.Encoding]::ASCII.GetString($EncKey, 0, 5)) {
    throw "Unknown OSCrypt internal encryption key format (missing 'DPAPI' prefix)."
}
# remove the DPAPI prefix
$EncKey = $EncKey | select -Skip 5
# decrypt the internal OSCrypt key
$Key = [System.Security.Cryptography.ProtectedData]::Unprotect($EncKey, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)

# the Signal database encryption key is stored in "config.json"
$SignalConf = cat -Raw "$SignalDataDir\config.json" | ConvertFrom-Json -AsHashtable
$EncData = [convert]::FromHexString($SignalConf["encryptedKey"])
function slice($Start, $End = $EncData.Length) {
    if ($Start -lt 0) {$Start = $EncData.Length + $Start}
    if ($End -lt 0) {$End = $EncData.Length + $End}
    return $EncData[$Start..($End - 1)]
}

# Chromium OSCrypt uses the following storage format to store the AES256-GCM-encrypted data:
# 3 byte prefix ("v10")
$Prefix = [System.Text.Encoding]::ASCII.GetString((slice 0 3))
# 12 byte nonce
$Nonce = slice 3 (3+12)
# the ciphertext itself
$Ciphertext = slice (3+12) -16
# 16 byte GCM authentication tag appended at the end
$Tag = slice -16

if ($Prefix -ne "v10") {
    throw "Unknown prefix for the encrypted database key, expected 'v10': $Prefix"
}

$Plaintext = [byte[]]::new($Ciphertext.Length)

$Cipher = [System.Security.Cryptography.AesGcm]::new($Key)
$Cipher.Decrypt($Nonce, $Ciphertext, $Tag, $Plaintext, $null)

$SignalDbKey = [System.Text.Encoding]::ASCII.GetString($Plaintext)

$PatchedConf = $SignalConf.Clone()
$PatchedConf.Remove("encryptedKey")
$PatchedConf["key"] = $SignalDbKey

return $PatchedConf