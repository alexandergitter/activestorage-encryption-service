# ActiveStorageEncryptionService

An ActiveStorage service that encrypts files before storing them. Currently, the only supported encryption algorithm is
ChaCha20 with a 256-bit key.

**WARNING**: This Gem is not ready for production use. It may very well eat your CPU, RAM and your data. There's no guarantee
that the encryption is actually secure. It currently doesn't do any kind of message authentication.

## How it works

This service transparently wraps another ActiveStorage service, encrypting files before they are stored and decrypting
them when they are retrieved.

Currently the service uses the ChaCha20 cipher. A random nonce is generated for each uploaded file and the data is encrypted
using the nonce and the configured secret key. A binary header of 200 bytes is prepended to the encrypted data, holding
information about the used encryption algorithm and its parameters (the nonce and a key check value in the case of ChaCha20).
Header + encrypted data are then stored using the wrapped, primary service.

The ChaCha20 implementation used here allows for random access inside the key stream, which enables this service to support
range requests efficiently.

## Installation

For now, add this repository to your Gemfile.

## Usage

Add something like this to your `config/storage.yml`:

```yaml
# ... other services here. This example assumes you have a
# service `local`.

encrypted:
  service: Encryption
  
  # The primary service that will do the actual data storage
  # and retrieval.
  primary: local
  
  # The secret key to use. This is a 64-character hex string
  # (will be parsed as a 32-byte binary key).
  # Instead of hardcoding the key here, you will probably want
  # to use an environment variable, Rails credentials or something
  # similar.
  encryption_key: "0001020304050607080910111213141516171819202122232425262728293031"
```
