This is a hacky script designed to crawl the Trello API for a board and then
post the information to Flow for import into Planner.

This repo also has the exported flow which _should_ import (although I haven't
tried it) although all the group and plan IDs are hard-coded, check through each
step and edit a necessary.

Setup
-----
Clone the repo and `bundle` to get required gems. Then you need to get an API
key, API token and your board ID. In an `irb` session:

```ruby
require 'tacokit'
# Go to https://trello.com/app-key and grab your "Developer API key"
key = 'ThatKey'
Tacokit.authorize key: key, scope: 'read', expiration: 'never', name: 'Exporter'
# Open the URL you're given in a browser, allow access, then copy the token
token = 'ThatToken'
client = Tacokit::Client.new(app_key: key, app_token: token)
# This will be a mapping of board name to board id
Hash[client.boards.map{|b| [b[:name], b[:id]]}]
```

Edit `import-board.rb`. Change the `POST_URL` to the URL for your Flow trigger
and change the `API_KEY`, `API_TOKEN` and `BOARD_ID` to match what you got in
the console above.

Use
---
Just `ruby import-board.rb`. Note that each card is a new Flow run. Keep an eye
on the run history to check progress and avoid messing withe

Known limitations
----------------

1. Commenting on tasks isn't possible in Flow. The import combines all Trello
   comments into one "narrative" and puts it in the task description.
2. Planner tasks don't have markup. The raw markdown from Trello will be
   displayed.
3. Labels can't be manipulated with Flow. Trello labels are discarded.
4. Non-file attachments (other Trello cards and boards) are discarded.
5. There's a bit of a race condition in the Flow between the "Check if a list
   exists" and the "Create a new list if needed" steps. A tasks may end up in
   duplicate lists. It should only be 2 or 3 tasks per list, but if you're
   worried about it, you could add some some delay to the import script loop
   (`sleep 5 #seconds` or whatever).
