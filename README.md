# Building
`zig build -Drelease-safe`

# Usage

## Encryption
`photo.jpg` = input photo

`message.txt` = message to encrypt

`imagezero.jpg` = encrypted jpg image

`zig-out/bin/jpg-embeder encrypt [passwd]`

## Decryption
`imagezero.jpg` = input photo

`message.txt` = output file for decrypted message

`zig-out/bin/jpg-embeder decrypt [passwd]`
