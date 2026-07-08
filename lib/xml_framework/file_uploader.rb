require 'securerandom'
require 'fileutils'

module XmlFramework
  class FileUploader
    ALLOWED_TYPES = %w[image/jpeg image/png image/gif image/webp application/pdf].freeze

    def initialize(upload_root: nil)
      @upload_root = upload_root || default_upload_root
      FileUtils.mkdir_p(@upload_root)
    end

    def save(uploaded_file, field_name:)
      return nil unless uploaded_file.respond_to?(:original_filename)

      original = uploaded_file.original_filename.to_s
      ext = File.extname(original)
      safe_name = "#{field_name}_#{SecureRandom.hex(8)}#{ext}"
      path = @upload_root.join(safe_name)

      File.open(path, 'wb') { |f| f.write(uploaded_file.read) }
      safe_name
    end

    def url_for(stored_name)
      return nil if stored_name.blank?

      "/uploads/#{stored_name}"
    end

    def full_path(stored_name)
      @upload_root.join(stored_name.to_s)
    end

    private

    def default_upload_root
      if defined?(Rails) && Rails.respond_to?(:root)
        Rails.root.join('public', 'uploads')
      else
        Pathname.new(Dir.pwd).join('public', 'uploads')
      end
    end
  end
end
