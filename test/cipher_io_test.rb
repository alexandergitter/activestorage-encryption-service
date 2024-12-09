require "test_helper"

class CipherIOTest < Minitest::Test
  def setup
    @nonce = "\x00\x01\x02\x03\x04\x05\x06\x07".b
    @kcv = "\x76\xb8\xe0\xad\xa0\xf1\x3d\x90".b

    cipher = ActiveStorageEncryptionService::ChaCha20Cipher.new("\x00".b*32, nonce: @nonce)
    io = StringIO.new("hello world".b)
    @ciphertext = "\x79\x38\xf1\x36\xde\x52\xa6\x05\xdd\x52\x2a".b
    @cio = ActiveStorageEncryptionService::CipherIO.new(io, cipher)
  end

  def test_read_zero_length_returns_empty_string
    assert_equal "", @cio.read(0)
  end

  def test_read_returns_header_before_data
    assert_equal "CC20", @cio.read(4)
    assert_equal @nonce + @kcv, @cio.read(16)
    assert_equal "\x00".b * 180, @cio.read(180)
    assert_equal @ciphertext[0, 5], @cio.read(5)
  end

  def test_read_returns_header_and_data_in_one_call
    expected = "CC20".b + @nonce + @kcv + "\x00".b * 180 + @ciphertext[0, 5]
    assert_equal expected, @cio.read(205)
  end

  def test_read_reads_until_eof_when_no_length_given
    expected = "CC20".b + @nonce + @kcv + "\x00".b * 180 + @ciphertext
    assert_equal expected, @cio.read
  end

  def test_read_puts_data_into_buffer_when_given
    buffer = String.new("old buffer content").force_encoding(Encoding::BINARY)
    @cio.read(12, buffer)
    assert_equal "CC20".b + @nonce, buffer
  end

  def test_read_returns_correct_values_at_eof
    @cio.read # consume all data first
    assert_equal "", @cio.read
    assert_equal "", @cio.read(nil)
    assert_equal "", @cio.read(0)
    assert_nil @cio.read(1)
  end
end
