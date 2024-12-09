$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "activestorage-encryption-service"
require "active_storage/service/encryption_service"

require "minitest/autorun"

FIXTURES_DIR = Pathname.new(__dir__).join("fixtures")

class MockService
  attr_accessor :uploads

  def initialize(uploads = {})
    @uploads = uploads
  end

  def upload(key, io, checksum: nil, **options)
    @uploads[key] = { data: io.read, checksum: checksum }
  end

  def download(key)
    if block_given?
      io = StringIO.new(@uploads[key][:data])
      until io.eof?
        yield io.read(1024)
      end
    else
      @uploads[key][:data]
    end
  end

  def download_chunk(key, range)
    @uploads[key][:data][range]
  end
end
