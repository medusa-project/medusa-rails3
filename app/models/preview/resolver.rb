require 'singleton'

#TODO possibly revise this to use a regexp search, at least on the content types,
# since the lists are starting to get large.
module Preview
  class Resolver < Object
    include Singleton

    attr_accessor :mime_type_viewers, :extension_viewers

    def initialize
      self.mime_type_viewers = invert_hash_of_arrays(Settings.cfs_file_viewers.mime_types)
      self.extension_viewers = invert_hash_of_arrays(Settings.cfs_file_viewers.extensions)
    end

    def find_preview_viewer_type(cfs_file)
      mime_type_viewers[cfs_file.content_type_name&.split(';')&.first] ||
          extension_viewers[File.extname(cfs_file.name).sub(/^\./, '').downcase] ||
          :none
    end

    PREVIEWER_MAP = {
        image: Image,
        video: Video,
        audio: Audio,
        text: Text,
        pdf: Pdf,
        none: Default
    }
    def find_previewer(cfs_file)
      previewer_class = PREVIEWER_MAP[find_preview_viewer_type(cfs_file)]
      raise 'Unrecognized previewer type' unless previewer_class
      previewer_class.new(cfs_file)
    end

    protected

    def invert_hash_of_arrays(hash_of_arrays)
      Hash.new.tap do |h|
        hash_of_arrays.each do |key, values|
          values.each {|value| h[value] = key.to_sym}
        end
      end
    end

  end
end