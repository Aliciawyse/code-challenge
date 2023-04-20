#!/usr/bin/env ruby
# frozen_string_literal: true

class Scrub
  class ScrubFileError < StandardError
  end
  require 'json'
  attr_reader :input_json, :sensitive_fields

  def initialize(args_arr)
    if args_arr.empty?
      raise ScrubFileError, 'Please supply a text file with a list of sensitive fields and a JSON file of user data.'
    end

    @sensitive_fields = File.readlines(args_arr[0], chomp: true)
    @input_json = File.read(args_arr[1])
  end

  def process_files
    if sensitive_fields.empty? || input_json.empty?
      puts 'Please confirm both files have content.'
      return
    end

    if sensitive_fields.include?('name')
      sensitive_fields.append('first', 'last')
    end

    personal_info_unscrubbed = JSON.parse(input_json)
    peronsal_info_scrubbed = {}
    personal_info_unscrubbed.each_pair do |data_type, data|
      peronsal_info_scrubbed[data_type] = parse_personal_info(field_name: data_type, field_value: data)
    end

    new_file = File.new('output.json', 'w')
    new_file.puts(JSON.pretty_generate(peronsal_info_scrubbed))
    new_file.close
  end

  def parse_personal_info(field_name:, field_value:)
    if field_value.is_a?(Array)
      field_value.map do |info|
        parse_personal_info(field_name: field_name, field_value: info)
      end
    elsif field_value.is_a?(Hash)
      field_value.each do |inner_key, inner_value|
        field_value[inner_key] = parse_personal_info(field_name: inner_key, field_value: inner_value)
      end
    else
      replace_personal_info(scrub_field: field_name, personal_info: field_value)
    end
  end

  def replace_personal_info(scrub_field:, personal_info:)
    if !sensitive_fields.include?(scrub_field)
      personal_info
    elsif [true, false].include?(personal_info)
      '-'
    else
      personal_info.to_s.gsub(/[a-z,A-Z,0-9]/, '*')
    end
  end
end

# Ensures file can run from the command line
Scrub.new(ARGV).process_files if $PROGRAM_NAME == __FILE__
