$LOAD_PATH.unshift File.dirname(__FILE__)

require "logger"
require "stringio"

require "ffmpeg/version"
require "ffmpeg/errors"
require "ffmpeg/media_file"
require "ffmpeg/io_ext"
require "ffmpeg/transcoder"
require "ffmpeg/concatenator"
require "ffmpeg/encoding_options"


module FFMPEG

  def self.logger=(log)
    @logger = log
  end


  def self.logger
    return @logger if @logger
    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO
    @logger = logger
  end


  def self.ffmpeg_binary=(bin)
    @ffmpeg_binary = bin
  end


  def self.ffmpeg_binary
    @ffmpeg_binary || "ffmpeg"
  end


  def self.concatenate(input_files, output_file, options = EncodingOptions.new, transcoder_options = {}, &block)
    raise unless input_files.respond_to? :each
    media_files = input_files.map do |f|
      f.is_a?(MediaFile) ? f : MediaFile.new(f)
    end
    Concatenator.new(media_files, output_file, options, transcoder_options).run &block
  end


  def self.test
    FFMPEG.concatenate([MediaFile.new("test/a.flac"),"test/b.wav","test/c.mp3"],"test/o.mp3") do |p|
      puts p
    end
  end

end


