require "test_helper"

class ChaCha20CipherTest < Minitest::Test
  def test_header
    c = ActiveStorageEncryptionService::ChaCha20Cipher.new("\x00".b*32, nonce: "\x00\x00\x00\x00\x00\x00\x00\x01".b)
    assert_equal "CC20\x00\x00\x00\x00\x00\x00\x00\x01\x76\xb8\xe0\xad\xa0\xf1\x3d\x90".b + "\x00".b * 180, c.header
  end

  def test_uses_ff_nonce_for_kcv_when_nonce_is_zero
    c = ActiveStorageEncryptionService::ChaCha20Cipher.new("\x00".b*32, nonce: "\x00".b*8)
    assert_equal "CC20\x00\x00\x00\x00\x00\x00\x00\x00\xe2\xf6\xbe\x72\x47\x57\xb1\x09".b + "\x00".b * 180, c.header
  end

  def test_can_be_initialized_with_nonce_or_header
    c = ActiveStorageEncryptionService::ChaCha20Cipher.new("\x00".b*32, nonce: "\x00".b*8)
    assert_equal "\x76\xb8\xe0\xad\xa0\xf1\x3d\x90".b, c.encrypt("\x00".b*8)

    # "CC20" (identifier) + nonce + kcv
    header = "CC20\x00\x00\x00\x00\x00\x00\x00\x01\x76\xb8\xe0\xad\xa0\xf1\x3d\x90".b + "\x00".b * 180
    c = ActiveStorageEncryptionService::ChaCha20Cipher.new("\x00".b*32, header: header)
    assert_equal "\xde\x9c\xba\x7b\xf3\xd6\x9e\xf5".b, c.encrypt("\x00".b*8)
  end

  def test_fails_when_nonce_and_header_are_both_nil
    assert_raises(ArgumentError) { ActiveStorageEncryptionService::ChaCha20Cipher.new("\x00".b*32) }
  end

  def test_fails_for_invalid_headers
    # Incorrect length
    assert_raises(ArgumentError) { ActiveStorageEncryptionService::ChaCha20Cipher.new("\x00".b*32, header: "CC20".b + "\x00".b*100) }
    # Incorrect identifier
    assert_raises(ArgumentError) { ActiveStorageEncryptionService::ChaCha20Cipher.new("\x00".b*32, header: "\x00".b*200) }
  end

  def test_fails_for_incorrect_key
    header = "CC20\x00\x00\x00\x00\x00\x00\x00\x01\x76\xb8\xe0\xad\xa0\xf1\x3d\x90".b + "\x00".b * 180
    assert_raises(ActiveStorageEncryptionService::IncorrectKeyError) { ActiveStorageEncryptionService::ChaCha20Cipher.new("\x12".b*32, header: header) }
  end
end
