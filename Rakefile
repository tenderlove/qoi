ENV["MT_NO_PLUGINS"] = "1"

require "rake/testtask"
require "rake/clean"
require "bundler"
Bundler::GemHelper.install_tasks

def download from, to
  Dir.mkdir 'tmp' unless File.directory?("tmp")

  require "net/http"
  require "net/https"
  require "fileutils"

  FileUtils.mkdir_p File.dirname(to)

  url = URI.parse from
  client = Net::HTTP.new(url.host, url.port)
  client.use_ssl = true
  client.start do |http|
    http.request_get(url.path) do |res|
      File.open(to, "w") do |f|
        res.read_body do |segment|
          f.write segment
        end
      end
    end
  end
end

TEST_IMAGES_URL = "https://qoiformat.org/qoi_test_images.zip"
TEST_IMAGES_ZIP = "test/images/tests.zip"
TEST_IMAGES_FOLDER = "test/images/qoi_test_images"

file TEST_IMAGES_FOLDER => TEST_IMAGES_ZIP do |t|
  require "zip"
  Zip::File.open(t.source) do |zip|
    zip.each do |entry|
      entry.extract File.join("test", "images", entry.name)
    end
  end
end

file TEST_IMAGES_ZIP do |t|
  download TEST_IMAGES_URL, t.name
end

CLEAN.include [TEST_IMAGES_ZIP, TEST_IMAGES_FOLDER]

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
  t.warning = true
end

task :test => TEST_IMAGES_FOLDER
