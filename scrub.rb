# frozen_string_literal: true

# !/usr/bin/env ruby
class Scrub
  require 'json'
  attr_reader :input_json, :sensitive_fields

  def initialize(args_arr)
    @sensitive_fields = args_arr[0]
    @input_json = args_arr[1]
  end

  def process_files
    if sensitive_fields.nil? || input_json.nil?
      puts 'Please supply two arguments: a text file with a list of sensitive fields and a JSON file of user data.'
      return
    end

    sensitive_fields_file = File.read(sensitive_fields)
    input_json_file       = File.read(input_json)

    if sensitive_fields_file.empty? || input_json_file.empty?
      puts 'Please confirm both files have content.'
      return
    end

    @sensitive_fields_arr = sensitive_fields_file.tr("\n", ",").split(",")
    if @sensitive_fields_arr.include?('name')
      @sensitive_fields_arr.append('first', 'last')
    end

    personal_info_unscrubbed = JSON.parse(input_json_file)
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
    if !@sensitive_fields_arr.include?(scrub_field)
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
