require "active_support/core_ext/module"
require "ruby-chacha20"
require_relative "activestorage_encryption_service/version"
require_relative "activestorage_encryption_service/cipher_io"
require_relative "activestorage_encryption_service/chacha20_cipher"

module ActiveStorageEncryptionService
  HEADER_SIZE = 200
end
