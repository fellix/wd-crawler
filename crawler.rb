require "nokogiri"
require "open-uri"
require 'fileutils'

BASE_URL =  "http://walkingdeadbr.com/hqonline"
MAGAZINE_PAGE = "#{BASE_URL}/index.php?cat=3"

def collect_chapters
  chapters = []
  doc = Nokogiri::HTML open(MAGAZINE_PAGE)
  doc.css("table.maintable td.catrow span.catlink a").each do |chapter_link|
    chapter = { link: chapter_link[:href], name: chapter_link.content }
    chapters << chapter
  end
  chapters
end

def collect_albums chapter
  albums = []
  doc = Nokogiri::HTML open("#{BASE_URL}/#{chapter[:link]}")
  doc.css("table.maintable td.tableh2 span.alblink a").each do |album_link|
    album = { link: album_link[:href], name: album_link.content, chapter: chapter }
    albums << album
  end
  albums
end

def download_magazines album
  parse_album_images album[:link]
  parse_album_images "#{album[:link]}&page=2"
  puts "Downloaded #{album[:chapter][:name]} - #{album[:name]}"
end

def parse_album_images link
  doc = Nokogiri::HTML open("#{BASE_URL}/#{link}")
  doc.css("table.maintable td.thumbnails td a").each do |thumb_link|
    download_images thumb_link[:href]
  end
end

def download_images href
  main_doc = Nokogiri::HTML open("#{BASE_URL}/#{href}")
  puts "#{BASE_URL}/#{href}"
  main_doc.css("table.maintable td.display_media img").each do |magazine_image|
    image_src = magazine_image[:src]
    dirs = image_src.split "/"
    dirs = dirs[0..dirs.length-2].join("/")
    FileUtils::mkdir_p dirs
    unless File.exist? image_src
      puts "downloading #{image_src}"
      open("#{image_src}", 'wb') do |file|
        file << open("#{BASE_URL}/#{image_src}").read
      end
    end
  end
end

chapters = collect_chapters
chapters.each do |chapter|
  albums = collect_albums chapter
  albums.each do |album|
    download_magazines album
  end
end
