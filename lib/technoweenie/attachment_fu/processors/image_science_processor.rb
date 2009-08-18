require 'image_science'
module Technoweenie # :nodoc:
  module AttachmentFu # :nodoc:
    module Processors
      module ImageScienceProcessor
        def self.included(base)
          base.send :extend, ClassMethods
          base.alias_method_chain :process_attachment, :processing
        end

        module ClassMethods
          # Yields a block containing an Image Science image for the given binary data.
          def with_image(file, &block)
            ::ImageScience.with_image file, &block
          end
        end

        protected
          def process_attachment_with_processing
            return unless process_attachment_without_processing && image?
            with_image do |img|
              self.width  = img.width  if respond_to?(:width)
              self.height = img.height if respond_to?(:height)
              resize_image_or_thumbnail! img
            end
          end

          # Performs the actual resizing operation for a thumbnail
          def resize_image(img, size)
            # create a dummy temp file to write to
            # ImageScience doesn't handle all gifs properly, so it converts them to
            # pngs for thumbnails.  It has something to do with trying to save gifs
            # with a larger palette than 256 colors, which is all the gif format
            # supports.
            filename.sub! /gif$/, 'png'
            content_type.sub!(/gif$/, 'png')
            temp_paths.unshift write_to_temp_file(filename)
            grab_dimensions = lambda do |img|
              self.width  = img.width  if respond_to?(:width)
              self.height = img.height if respond_to?(:height)
              img.save self.temp_path
              self.size = File.size(self.temp_path)
              callback_with_args :after_resize, img
            end

            size = size.first if size.is_a?(Array) && size.length == 1
            if size.is_a?(Fixnum) || (size.is_a?(Array) && size.first.is_a?(Fixnum))
              if size.is_a?(Fixnum)
                img.thumbnail(size, &grab_dimensions)
              else
                img.resize(size[0], size[1], &grab_dimensions)
              end
            else
          
              new_size = [img.width, img.height] / size.to_s
              
              if size.ends_with?("!")
                
                aspect = new_size.first.to_f / new_size.last.to_f
                
                orig_width, orig_height = img.width, img.height
                
                aspect_width, aspect_height = (orig_height * aspect), (orig_width / aspect)
                
                new_width  = [aspect_width,  orig_width ].min.to_i
                new_height = [aspect_height, orig_height].min.to_i
                
                x = (orig_width  - new_width)  / 2
                y = (orig_height - new_height) / 2
                w = (orig_width  + new_width)  / 2
                h = (orig_height + new_height) / 2
                
                # crop
                img.with_crop(x, y, w, h) do |to_crop|
                  to_crop.resize(new_size.first, new_size.last, &grab_dimensions)
                end
              else
                img.resize(new_size[0], new_size[1], &grab_dimensions)
              end
            end
          end
      end
    end
  end
end