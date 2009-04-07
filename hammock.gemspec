# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{hammock}
  s.version = "0.2.13"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ben Hoskings"]
  s.date = %q{2009-04-07}
  s.description = %q{Hammock is a Rails plugin that eliminates redundant code in a very RESTful manner. It does this in lots in lots of different places, but in one manner: it encourages specification in place of implementation.   Hammock enforces RESTful resource access by abstracting actions away from the controller in favour of a clean, model-like callback system.  Hammock tackles the hard and soft sides of security at once with a scoping security system on your models. Specify who can verb what resources under what conditions once, and everything else - the actual security, link generation, index filtering - just happens.  Hammock inspects your routes and resources to generate a routing tree for each resource. Parent resources in a nested route are handled transparently at every point - record retrieval, creation, and linking.  It makes more sense when you see how it works though, so check out the screencast!}
  s.email = ["ben@hoskings.net"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.rdoc", "misc/scaffold.txt"]
  s.files = ["History.txt", "LICENSE", "Manifest.txt", "README.rdoc", "Rakefile", "hammock.gemspec", "lib/hammock.rb", "lib/hammock/ajaxinate.rb", "lib/hammock/callback.rb", "lib/hammock/callbacks.rb", "lib/hammock/canned_scopes.rb", "lib/hammock/constants.rb", "lib/hammock/controller_attributes.rb", "lib/hammock/export_scope.rb", "lib/hammock/hamlink_to.rb", "lib/hammock/javascript_buffer.rb", "lib/hammock/logging.rb", "lib/hammock/model_attributes.rb", "lib/hammock/model_logging.rb", "lib/hammock/monkey_patches/action_pack.rb", "lib/hammock/monkey_patches/active_record.rb", "lib/hammock/monkey_patches/array.rb", "lib/hammock/monkey_patches/hash.rb", "lib/hammock/monkey_patches/logger.rb", "lib/hammock/monkey_patches/module.rb", "lib/hammock/monkey_patches/numeric.rb", "lib/hammock/monkey_patches/object.rb", "lib/hammock/monkey_patches/route_set.rb", "lib/hammock/monkey_patches/string.rb", "lib/hammock/overrides.rb", "lib/hammock/resource_mapping_hooks.rb", "lib/hammock/resource_retrieval.rb", "lib/hammock/restful_actions.rb", "lib/hammock/restful_rendering.rb", "lib/hammock/restful_support.rb", "lib/hammock/route_drawing_hooks.rb", "lib/hammock/route_for.rb", "lib/hammock/route_node.rb", "lib/hammock/route_step.rb", "lib/hammock/scope.rb", "lib/hammock/suggest.rb", "lib/hammock/utils.rb", "misc/scaffold.txt", "misc/template.rb", "tasks/hammock_tasks.rake", "test/hammock_test.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/benhoskings/hammock}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{hammock}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Hammock is a Rails plugin that eliminates redundant code in a very RESTful manner}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rails>, ["~> 2.2"])
      s.add_runtime_dependency(%q<benhoskings-ambitious-activerecord>, ["~> 0.1.3.5"])
      s.add_development_dependency(%q<newgem>, [">= 1.3.0"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.0"])
    else
      s.add_dependency(%q<rails>, ["~> 2.2"])
      s.add_dependency(%q<benhoskings-ambitious-activerecord>, ["~> 0.1.3.5"])
      s.add_dependency(%q<newgem>, [">= 1.3.0"])
      s.add_dependency(%q<hoe>, [">= 1.8.0"])
    end
  else
    s.add_dependency(%q<rails>, ["~> 2.2"])
    s.add_dependency(%q<benhoskings-ambitious-activerecord>, ["~> 0.1.3.5"])
    s.add_dependency(%q<newgem>, [">= 1.3.0"])
    s.add_dependency(%q<hoe>, [">= 1.8.0"])
  end
end
