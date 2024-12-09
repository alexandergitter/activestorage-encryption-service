require "test_helper"
require "openssl"

class EncryptionServiceTest < Minitest::Test
  def setup
    encryption_key_hex = "0001020304050607080910111213141516171819202122232425262728293031"
    @encryption_key = [encryption_key_hex].pack("H*")
    @nonce = ["0001020304050607"].pack("H*")
    @mock_service = MockService.new
    @service = ActiveStorage::Service::EncryptionService.new(primary: @mock_service, encryption_key: encryption_key_hex)
  end

  def test_upload
    data = IO.binread(FIXTURES_DIR.join("image.jpg").to_s)
    checksum = OpenSSL::Digest::MD5.base64digest(data)

    SecureRandom.stub(:random_bytes, @nonce) do
      @service.upload("image.jpg", StringIO.new(data), checksum: checksum)
    end

    expected_data = IO.binread(FIXTURES_DIR.join("image.jpg.enc").to_s)
    expected_checksum = OpenSSL::Digest::MD5.base64digest(expected_data)

    assert_equal expected_data, @mock_service.uploads["image.jpg"][:data]
    assert_equal expected_checksum, @mock_service.uploads["image.jpg"][:checksum]
  end

  def test_download
    data = IO.binread(FIXTURES_DIR.join("image.jpg.enc").to_s)
    checksum = OpenSSL::Digest::MD5.base64digest(data)
    @mock_service.uploads = { "image.jpg" => { data: data, checksum: checksum } }

    expected_data = IO.binread(FIXTURES_DIR.join("image.jpg").to_s)

    assert_equal expected_data, @service.download("image.jpg")

    io = StringIO.new(expected_data)
    @service.download("image.jpg") do |chunk|
      assert_equal io.read(chunk.length), chunk
    end
  end

  def test_download_chunk
    data = IO.binread(FIXTURES_DIR.join("image.jpg.enc").to_s)
    checksum = OpenSSL::Digest::MD5.base64digest(data)
    @mock_service.uploads = { "image.jpg" => { data: data, checksum: checksum } }

    expected_data = IO.binread(FIXTURES_DIR.join("image.jpg").to_s)

    assert_equal expected_data[0..1023], @service.download_chunk("image.jpg", 0..1023)
    assert_equal expected_data[1024..], @service.download_chunk("image.jpg", 1024..)
  end
end
