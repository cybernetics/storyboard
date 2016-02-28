{mainStory} = require '../storyboard'  # you'd write: `'storyboard'`
mainStory.info 'client', 'Running client...'

nodeButton = document.getElementById 'refresh'
nodeItems  = document.getElementById 'items'
nodeButton.addEventListener 'click', -> _refresh 'Click on Refresh'

_refresh = (storyTitle) ->
  story = mainStory.child {title: storyTitle}
  story.info 'serverInterface', "Fetching items from server..."
  fetch '/items',
    method: 'post'
    headers:
      'Accept': 'application/json'
      'Content-Type': 'application/json'
    body: JSON.stringify {storyId: story.id}
  .then (response) -> response.json()
  .then (items) ->
    if Array.isArray items
      story.info 'serverInterface', "Fetched items from server: #{items.length}"
      nodeItems.innerHTML = items.map((o) -> "<li>#{o}</li>").join('')
    story.close()

_refresh 'Initial fetch'