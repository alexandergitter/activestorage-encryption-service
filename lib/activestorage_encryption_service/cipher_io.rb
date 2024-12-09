module ActiveStorageEncryptionService
  class CipherIO
    def initialize(io, cipher)
      @io = io
      @cipher = cipher
      @header_bytes_read = 0
    end

    def read(length = nil, buffer = nil)
      return "" if length && length <= 0

      buffer ||= String.new.force_encoding(Encoding::BINARY)
      buffer.clear

      if @header_bytes_read < HEADER_SIZE
        header_bytes_to_read = [HEADER_SIZE - @header_bytes_read, length].compact.min
        buffer << @cipher.header[@header_bytes_read, header_bytes_to_read]
        @header_bytes_read += header_bytes_to_read
      end

      header_adjusted_length = length&.-(buffer.bytesize)
      plaintext = @io.read(header_adjusted_length)
      buffer << @cipher.encrypt(plaintext || "".b)

      return nil if buffer.empty? && length && length > 0

      buffer
    end

    def rewind
      @cipher.seek(0)
      @header_bytes_read = 0
      @io.rewind
    end
  end
end
