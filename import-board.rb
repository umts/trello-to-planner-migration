require 'tacokit'
require 'json'
require 'httparty'
require 'uri'
require 'cgi'

POST_URL = 'https://the-post-url-of-your-flow.example.com/'
API_KEY = 'your Trello API Key (see README)'
API_TOKEN = 'your Trello API Token (see README)'
BOARD_ID = 'your Trello Board ID (see README)'

uri = URI.parse(POST_URL)
headers = {'Content-Type' => 'application/json'}

client = Tacokit::Client.new(app_key: API_KEY, app_token: API_TOKEN)
board = client.board(BOARD_ID, cards: 'all')
lists = Hash[ client.lists(board).map{|l| [l[:id], l[:name]]} ]

board.cards.each do |card|
  comments = client.card_actions(card[:id]).select do |action|
    action[:type] == 'commentCard'
  end.sort_by{ |action| action[:date] }

  narative = "#{card[:desc]}\n=-=-=-=\n" + comments.map do |comment|
    "#{comment[:member_creator][:full_name]}, #{comment[:date]}:\n\n" +
      comment[:data][:text]
  end.join("\n---------------\n")

  attachments = []
  client.card_attachments(card[:id]).select do |attachment|
    attachment[:is_upload]
  end.each do |attachment|
    base, ext = attachment[:name].split(/(?<=.)\.(?=[^.])(?!.*\.[^.])/)
    base = base.downcase.tr(' ', '-').gsub(/[^a-z0-9-]/, '')

    loop do
      fn = [base, ext].compact.join('.')
      break unless attachments.map{|a| a[:filename]}.include? fn
      base = base.succ
    end

    attachments << {
      filename: fn,
      url: CGI.unescape(attachment[:url].match(/backingUrl=(.*)/)[1])
    }
  end

  body = {
    title: card[:name],
    description: narative,
    list: lists[card[:list_id]],
    due: card[:due]&.iso8601,
    archived: card[:closed],
    attachments: attachments
  }.to_json

  response = HTTParty.post(uri, body: body, headers: headers)

  puts "#{card[:name]}: #{response.code}"
end
