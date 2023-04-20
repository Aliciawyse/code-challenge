# Scrub Personal Identifiable Information

## What is this?
Hello! This is a Ruby script that will scrub personal indentifiable information from a valid `input.json` file. This script determines what information to scrub based on a `sensitive_fields.txt` file.

## Prerequisites
Before you continue, ensure you have met the following requirements:
- You have installed the latest version of (Ruby)[https://www.ruby-lang.org/en/downloads/].
- You are using Mac OS machine.

## How to install:
- Clone this repo. For example `git clone https://github.com/Aliciawyse/code-challenge.git`
- Open this project in your code editor
- Open terminal and make sure you're in this project directory `cd code-challenge`
- Type in `bundle install`

## How to run specs:
- Type in `bundle exec rspec`
- There is a test case for each scenario listed in this assignment's Google Drive folder. Note that all the specs pass, except for the last one which is skipped for now.

## How to try it out:
- Open terminal and make sure you're in this project directory `cd code-challenge`
- Type in `chmod +x scrub.rb`. This allows you to run the program from the terminal as seen in following step.
- Type in `./scrub.rb sensitive_fields.txt input.json`
- Look for generated output in new file called `output.json`

## Project takeaways:
I got started by getting reliable specs in place and getting each to pass. Afterward certain patterns were more obvious, so I revisited the code to "DRY" it up. I also used the RuboCop linter to help with formatting the code nicely. It was a challenge to handle nested objects and arrays in a smart way. For next steps, it would be helpful to split up concepts such as: validating input, looping through input, replacing input.