require "active_storage/service"
require "active_support/core_ext/numeric"

module ActiveStorage
  class Service::EncryptionService < Service
    delegate :delete, :delete_prefixed, :exist?, :url, to: :@primary

    def self.build(primary:, encryption_key:, name:, configurator:, **config)
      new(primary: configurator.build(primary), encryption_key: encryption_key).tap do |service_instance|
        service_instance.name = name
      end
    end

    def initialize(primary:, encryption_key:)
      @primary = primary
      @encryption_key = [encryption_key].pack("H*")
    end

    def upload(key, io, checksum: nil, **options)
      nonce = SecureRandom.random_bytes(8)
      cipher = new_cipher(nonce: nonce)

      cipher_io = ActiveStorageEncryptionService::CipherIO.new(io, cipher)
      checksum = compute_checksum_in_chunks(cipher_io) if checksum.present?

      @primary.upload key, cipher_io, checksum: checksum, **options
    end

    def download(key)
      cipher = nil

      if block_given?
        @primary.download(key) do |chunk|
          if cipher
            yield cipher.decrypt(chunk)
          else
            header, data = split_header_and_data(chunk)
            cipher = new_cipher(header: header)
            yield cipher.decrypt(data)
          end
        end
      else
        header, data = split_header_and_data(@primary.download(key))
        cipher = new_cipher(header: header)
        cipher.decrypt(data)
      end
    end

    def download_chunk(key, range)
      header = download_header(key)
      cipher = new_cipher(header: header)
      cipher.seek(range.begin || 0)

      header_adjusted_range = Range.new(
        range.begin&.+(ActiveStorageEncryptionService::HEADER_SIZE),
        range.end&.+(ActiveStorageEncryptionService::HEADER_SIZE),
        range.exclude_end?
      )

      cipher.decrypt(@primary.download_chunk(key, header_adjusted_range))
    end

    private

    def new_cipher(header: nil, nonce: nil)
      ActiveStorageEncryptionService::ChaCha20Cipher.new(@encryption_key, header: header, nonce: nonce)
    end

    def compute_checksum_in_chunks(io)
      raise ArgumentError, "io must be rewindable" unless io.respond_to?(:rewind)

      OpenSSL::Digest::MD5.new.tap do |checksum|
        read_buffer = "".b
        while io.read(5.megabytes, read_buffer)
          checksum << read_buffer
        end

        io.rewind
      end.base64digest
    end

    def download_header(key)
      @primary.download_chunk(key, 0...ActiveStorageEncryptionService::HEADER_SIZE)
    end

    def split_header_and_data(data)
      header = data[0...ActiveStorageEncryptionService::HEADER_SIZE]
      data = data[ActiveStorageEncryptionService::HEADER_SIZE..]
      [header, data]
    end
  end
end
