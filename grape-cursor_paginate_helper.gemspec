# frozen_string_literal: true

require_relative 'lib/grape/cursor_paginate_helper/version'

Gem::Specification.new do |spec|
  spec.name = 'grape-cursor_paginate_helper'
  spec.version = Grape::CursorPaginateHelper::VERSION
  spec.authors = ['Shinichi Sugiyama']
  spec.email = ['sugiyama-shinichi@kayac.com']

  spec.summary = 'Grape API Helper for ActiveRecord::CursorPaginator'
  spec.description = 'see https://github.com/ssugiyama/grape-cursor_paginate_helper'
  spec.homepage = 'https://github.com/ssugiyama/grape-cursor_paginate_helper'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/Changelog.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) {|f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'active_record-cursor_paginator', '>= 0.2'
  spec.add_dependency 'grape', '>= 1.7'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
