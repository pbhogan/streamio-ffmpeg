require "open3"
require "shellwords"


module FFMPEG
  class Concatenator
    @@timeout = 30


    def self.timeout=(time)
      @@timeout = time
    end


    def self.timeout
      @@timeout
    end


    def initialize(input_files, output_file, options = EncodingOptions.new, transcoder_options = {})
      @input_files = input_files
      @output_file = output_file

      if options.is_a?(String) || options.is_a?(EncodingOptions)
        @raw_options = options
      elsif options.is_a?(Hash)
        @raw_options = EncodingOptions.new(options)
      else
        raise ArgumentError, "Unknown options format '#{options.class}', should be either EncodingOptions, Hash or String."
      end

      @transcoder_options = transcoder_options
      @errors = []

      apply_transcoder_options
    end


    def run(&block)
      process(&block)
      if @transcoder_options[:validate]
        validate_output_file(&block)
        return encoded
      else
        return nil
      end
    end


    def encoding_succeeded?
      @errors << "No output file created." and return false unless File.exists?(@output_file)
      @errors << "Encoded file is invalid." and return false unless encoded.valid?
      true
    end


    def encoded
      @encoded ||= MediaFile.new(@output_file)
    end


    private

    def expected_duration
      @input_files.map(&:duration).inject(0, :+)
    end


    def process
      # ffmpeg -y -i clip1.flac -i beep.wav -i clip2.mp3 -filter_complex concat=n=3:v=0:a=1 output.mp3
      inputs = @input_files.map do |input_file|
        "-i #{Shellwords.escape(input_file.path)}"
      end.join(" ")
      filter = @input_files.size > 1 ? "-filter_complex concat=n=#{@input_files.size}:v=0:a=1" : ""
      @command = "#{FFMPEG.ffmpeg_binary} -y #{inputs} #{filter} #{@raw_options} #{Shellwords.escape(@output_file)}"
      FFMPEG.logger.info("Processing...\n#{@command}\n")
      @output = ""

      Open3.popen3(@command) do |stdin, stdout, stderr, wait_thr|
        begin
          yield(0.0) if block_given?
          next_line = Proc.new do |line|
            fix_encoding(line)
            @output << line
            if line.include?("time=")
              if line =~ /time=(\d+):(\d+):(\d+.\d+)/ # ffmpeg 0.8 and above style
                time = ($1.to_i * 3600) + ($2.to_i * 60) + $3.to_f
              else # better make sure it wont blow up in case of unexpected output
                time = 0.0
              end
              progress = time / expected_duration
              yield(progress) if block_given?
            end
          end

          if @@timeout
            stderr.each_with_timeout(wait_thr.pid, @@timeout, 'size=', &next_line)
          else
            stderr.each('size=', &next_line)
          end

        rescue Timeout::Error => e
          FFMPEG.logger.error "Process hung...\n@command\n#{@command}\nOutput\n#{@output}\n"
          raise Error, "Process hung. Full output: #{@output}"
        end
      end
    end


    def validate_output_file(&block)
      if encoding_succeeded?
        yield(1.0) if block_given?
        FFMPEG.logger.info "Processing of #{@input_files.map(&:path).join(", ")} to #{@output_file} succeeded.\n"
      else
        errors = "Errors: #{@errors.join(", ")}. "
        FFMPEG.logger.error "Failed processing...\n#{@command}\n\n#{@output}\n#{errors}\n"
        raise Error, "Failed processing.#{errors}Full output: #{@output}"
      end
    end


    def apply_transcoder_options
      @transcoder_options[:validate] = @transcoder_options.fetch(:validate) { true }
    end


    def fix_encoding(output)
      output[/test/]
    rescue ArgumentError
      output.force_encoding("ISO-8859-1")
    end

  end
end

