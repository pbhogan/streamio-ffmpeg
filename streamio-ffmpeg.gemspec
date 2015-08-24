# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require "ffmpeg/version"

Gem::Specification.new do |s|
  s.name        = "streamio-ffmpeg"
  s.version     = FFMPEG::VERSION
  s.authors     = ["Patrick Hogan", "David Backeus"]
  s.email       = ["pbhogan@gmail.com", "david@streamio.com"]
  s.homepage    = "http://github.com/pbhogan/streamio-ffmpeg"
  s.summary     = "Wraps ffmpeg to read metadata and transcode audio and video files."

  s.add_development_dependency "rspec", "~> 2.14"
  s.add_development_dependency "rake", "~> 10.1"

  s.files        = Dir.glob("lib/**/*") + %w(README.md LICENSE CHANGELOG)
end
