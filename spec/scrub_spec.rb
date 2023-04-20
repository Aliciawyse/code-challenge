# frozen_string_literal: true

require './scrub'
require 'tempfile'

describe Scrub do
  let(:subject) { described_class.new(arguments).process_files }

  context 'with missing args' do
    let(:arguments) { [] }

    it 'returns a helpful message about missing required info' do
      expect{subject}.to raise_error(Scrub::ScrubFileError)
    end
  end

  context 'with empty files' do
    let(:sensitive_fields_file) { Tempfile.new(['sensitive_fields', '.txt']) }
    let(:input_json_file) { Tempfile.new(['input_json', '.json']) }
    let(:arguments) { [sensitive_fields_file, input_json_file] }

    it 'returns a helpful message about empty files' do
      expect { subject }.to output(/Please confirm both files have content./).to_stdout
    end
  end

  context 'with sensitive fields to scrub' do
    let(:arguments) { [sensitive_fields_file.path, input_json_file.path] }

    before do
      allow(File).to receive(:new).with('output.json', 'w').and_call_original
    end

    context 'basic' do
      let(:sensitive_fields_file) do
        Tempfile.new(['sensitive_fields', '.txt']).tap do |file|
          File.open(file, 'w') do |f|
            f.write(
              <<~INPUT
                name
                phone
                email
              INPUT
            )
          end
        end
      end

      let(:input_json_file) do
        Tempfile.new(['input_json', '.json']).tap do |input_file|
          File.open(input_file, 'w') do |f|
            f.write({
              "name": 'Kelly Doe',
              "email": 'kdoe@example.com',
              "id": 12_324,
              "phone": '5551234567'
            }.to_json)
          end
        end
      end

      let(:output) do
        <<~JSON
          {
            "name": "***** ***",
            "email": "****@*******.***",
            "id": 12324,
            "phone": "**********"
          }
        JSON
      end

      it 'scrubs basic data' do
        subject
        expect(File.read('output.json')).to eq(output)
      end
    end

    context 'array' do
      let(:sensitive_fields_file) do
        Tempfile.new(['sensitive_fields', '.txt']).tap do |file|
          File.open(file, 'w') do |f|
            f.write(
              <<~INPUT
                name
                phone
                email
              INPUT
            )
          end
        end
      end
      let(:input_json_file) do
        Tempfile.new(['input_json', '.json']).tap do |input_file|
          File.open(input_file, 'w') do |f|
            f.write({
              "name": 'Kelly Doe',
              "email": ['kdoe@example.com', 'kelly@gmail.com', 'kelly@doe.net'],
              "id": 12_324,
              "phone": '5551234567'
            }.to_json)
          end
        end
      end

      let(:output) do
        <<~JSON
          {
            "name": "***** ***",
            "email": [
              "****@*******.***",
              "*****@*****.***",
              "*****@***.***"
            ],
            "id": 12324,
            "phone": "**********"
          }
        JSON
      end

      it 'scrubs data in array' do
        subject
        expect(File.read('output.json')).to eq(output)
      end
    end

    context 'boolean' do
      let(:sensitive_fields_file) do
        Tempfile.new(['sensitive_fields', '.txt']).tap do |file|
          File.open(file, 'w') do |f|
            f.write(
              <<~INPUT
                name
                email
                phone
                us_citizen
              INPUT
            )
          end
        end
      end
      let(:input_json_file) do
        Tempfile.new(['input_json', '.json']).tap do |input_file|
          File.open(input_file, 'w') do |f|
            f.write({
              "name": 'Kelly Doe',
              "email": 'kdoe@example.com',
              "id": 12_324,
              "phone": '5551234567',
              "us_citizen": false,
              "admin": false
            }.to_json)
          end
        end
      end
      let(:output) do
        <<~JSON
          {
            "name": "***** ***",
            "email": "****@*******.***",
            "id": 12324,
            "phone": "**********",
            "us_citizen": "-",
            "admin": false
          }
        JSON
      end

      it 'scrubs boolean data' do
        subject
        expect(File.read('output.json')).to eq(output)
      end
    end

    context 'numbers (in other words integers)' do
      let(:sensitive_fields_file) do
        Tempfile.new(['sensitive_fields', '.txt']).tap do |file|
          File.open(file, 'w') do |f|
            f.write(
              <<~INPUT
                name
                email
                phone
              INPUT
            )
          end
        end
      end
      let(:input_json_file) do
        Tempfile.new(['input_json', '.json']).tap do |input_file|
          File.open(input_file, 'w') do |f|
            f.write({
              "name": 'Kelly Doe',
              "email": 'kdoe@example.com',
              "id": 12_324,
              "phone": 5_551_234_567
            }.to_json)
          end
        end
      end
      let(:output) do
        <<~JSON
          {
            "name": "***** ***",
            "email": "****@*******.***",
            "id": 12324,
            "phone": "**********"
          }
        JSON
      end

      it 'scrubs integer data' do
        subject
        expect(File.read('output.json')).to eq(output)
      end
    end

    context 'floats' do
      let(:sensitive_fields_file) do
        Tempfile.new(['sensitive_fields', '.txt']).tap do |file|
          File.open(file, 'w') do |f|
            f.write(
              <<~INPUT
                name
                email
                phone
                account_balance
              INPUT
            )
          end
        end
      end
      let(:input_json_file) do
        Tempfile.new(['input_json', '.json']).tap do |input_file|
          File.open(input_file, 'w') do |f|
            f.write({
              "name": 'Kelly Doe',
              "email": 'kdoe@example.com',
              "id": 12_324,
              "phone": '5551234567',
              "account_balance": 1234.56,
              "title": 'manager'
            }.to_json)
          end
        end
      end
      let(:output) do
        <<~JSON
          {
            "name": "***** ***",
            "email": "****@*******.***",
            "id": 12324,
            "phone": "**********",
            "account_balance": "****.**",
            "title": "manager"
          }
        JSON
      end

      it 'scrubs float data' do
        subject
        expect(File.read('output.json')).to eq(output)
      end
    end

    context 'nested objects' do
      let(:sensitive_fields_file) do
        Tempfile.new(['sensitive_fields', '.txt']).tap do |file|
          File.open(file, 'w') do |f|
            f.write(
              <<~INPUT
                name
                email
                phone
              INPUT
            )
          end
        end
      end
      let(:input_json_file) do
        Tempfile.new(['input_json', '.json']).tap do |input_file|
          File.open(input_file, 'w') do |f|
            f.write({
              "name": 'Kelly Doe',
              "id": 12_324,
              "contact": {
                "email": 'kdoe@example.com',
                "phone": '5551234567'
              }
            }.to_json)
          end
        end
      end
      let(:output) do
        <<~JSON
          {
            "name": "***** ***",
            "id": 12324,
            "contact": {
              "email": "****@*******.***",
              "phone": "**********"
            }
          }
        JSON
      end
      it 'scrubs data in nested object' do
        subject
        expect(File.read('output.json')).to eq(output)
      end
    end

    context 'mixed type arrays' do
      let(:sensitive_fields_file) do
        Tempfile.new(['sensitive_fields', '.txt']).tap do |file|
          File.open(file, 'w') do |f|
            f.write(
              <<~INPUT
                name
                email
                phone
                us_citizen
                account_balance
              INPUT
            )
          end
        end
      end
      let(:input_json_file) do
        Tempfile.new(['input_json', '.json']).tap do |input_file|
          File.open(input_file, 'w') do |f|
            f.write({
              "name": 'Kelly Doe',
              "email": 'kdoe@example.com',
              "id": 12_324,
              "phone": '5551234567',
              "contacts": [{
                "name": 'Bob Doe',
                "us_citizen": false
              },
                           12_345,
                           'bob@example.com',
                           {
                             "id": 2343,
                             "name": 'John Smith',
                             "email": 'john.smith@yahoo.com'
                           },
                           {
                             "phone": '(555) 234-2343',
                             "name": 'Joe Schmoe',
                             "email": 'jschmoe@aol.com'
                           }]
            }.to_json)
          end
        end
      end
      let(:output) do
        <<~JSON
          {
            "name": "***** ***",
            "email": "****@*******.***",
            "id": 12324,
            "phone": "**********",
            "contacts": [
              {
                "name": "*** ***",
                "us_citizen": "-"
              },
              12345,
              "bob@example.com",
              {
                "id": 2343,
                "name": "**** *****",
                "email": "****.*****@*****.***"
              },
              {
                "phone": "(***) ***-****",
                "name": "*** ******",
                "email": "*******@***.***"
              }
            ]
          }
        JSON
      end
      it 'scrubs data in mixed type arrays' do
        subject
        expect(File.read('output.json')).to eq(output)
      end
    end

    context 'sensitive nested objects' do
      let(:sensitive_fields_file) do
        Tempfile.new(['sensitive_fields', '.txt']).tap do |file|
          File.open(file, 'w') do |f|
            f.write(
              <<~INPUT
                name
                email
                phone
              INPUT
            )
          end
        end
      end
      let(:input_json_file) do
        Tempfile.new(['input_json', '.json']).tap do |input_file|
          File.open(input_file, 'w') do |f|
            f.write({
              "name": {
                "first": 'Kelly',
                "last": 'Doe'
              },
              "id": 12_324,
              "email": 'kdoe@example.com',
              "phone": '5551234567'
            }.to_json)
          end
        end
      end
      let(:output) do
        <<~JSON
          {
            "name": {
              "first": "*****",
              "last": "***"
            },
            "id": 12324,
            "email": "****@*******.***",
            "phone": "**********"
          }
        JSON
      end

      it 'scrubs data in nested objects' do
        subject
        expect(File.read('output.json')).to eq(output)
      end
    end

    xcontext 'sensitive nested arrays' do
      let(:sensitive_fields_file) do
        Tempfile.new(['sensitive_fields', '.txt']).tap do |file|
          File.open(file, 'w') do |f|
            f.write(
              <<~INPUT
                name
                email
                phone
                us_citizen
                account_balance
              INPUT
            )
          end
        end
      end
      let(:input_json_file) do
        Tempfile.new(['input_json', '.json']).tap do |input_file|
          File.open(input_file, 'w') do |f|
            f.write({
              "name": 'Kelly Doe',
              "id": 12_324,
              "email": [
                {
                  "id": 23_432,
                  "value": 'kdoe@example.com'
                }, {
                  "id": 23_432,
                  "value": 'kdoe@gmail.com'
                }
              ],
              "phone": [
                %w[555 123 4561],
                %w[555 989 4444],
                %w[555 781 4630]
              ]
            }.to_json)
          end
        end
      end
      let(:output) do
        <<~JSON
          {
            "name": "***** ***",
            "id": 12324,
            "email": [
              {
                "id": "*****",
                "value": "****@*******.***"
              }, {
                "id": "*****",
                "value": "****@*****.***"
              }
            ],
            "phone": [
              [
                "***",
                "***",
                "****"
              ],
              [
                "***",
                "***",
                "****"
              ],
              [
                "***",
                "***",
                "****"
              ]
            ]
          }
        JSON
      end

      it 'scrubs data in nested arrays' do
        subject
        expect(File.read('output.json')).to eq(output)
      end
    end
  end
end
