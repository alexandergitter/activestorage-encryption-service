module ActiveStorageEncryptionService
  class IncorrectKeyError < StandardError; end

  class ChaCha20Cipher
    delegate :encrypt, :decrypt, :seek, :nonce, to: :@cipher

    def initialize(key, header: nil, nonce: nil)
      raise ArgumentError, "either :header or :nonce must be provided" unless header || nonce

      nonce, provided_kcv = parse_header(header) if header
      @cipher = ::ChaCha20.new(key, nonce)
      @kcv = generate_kcv(key)

      raise IncorrectKeyError, "provided key is incorrect" if provided_kcv && provided_kcv != @kcv
    end

    def header
      pad("CC20#{nonce}#{@kcv}".b)
    end

    private

    def parse_header(header)
      raise ArgumentError, ":header must be #{HEADER_SIZE} bytes" unless header.bytesize == HEADER_SIZE
      raise ArgumentError, ":header must start with 'CC20'" unless header.start_with?("CC20")
      nonce = header[4, 8]
      kcv = header[12, 8]
      [nonce, kcv]
    end

    def generate_kcv(key)
      kcv_nonce = "\x00".b * 8
      kcv_nonce = "\xff".b * 8 if nonce == kcv_nonce
      kcv_cipher = ::ChaCha20.new(key, kcv_nonce)
      kcv_cipher.encrypt("\x00".b * 8)
    end

    def pad(bytes)
      raise ArgumentError, "unpadded header bytes must be at most #{HEADER_SIZE} bytes" if bytes.bytesize > HEADER_SIZE
      bytes + "\x00".b * (HEADER_SIZE - bytes.bytesize)
    end
  end
end
