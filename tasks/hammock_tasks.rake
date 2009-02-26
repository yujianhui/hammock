desc "Regenerate the Manifest from the working tree"
task :git_to_manifest do
  cmd = %Q(git ls-files -x '.*' > Manifest.txt)
  `#{cmd}`; $? == 0
end
