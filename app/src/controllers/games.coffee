_ = require 'underscore'
Spine._ = require 'underscore'
$      = Spine.$

fsUtils = require '../lib/fs-utils'

class Games extends Spine.Controller
  className: 'app-games'

  elements:
    '.cards .card': 'cards'

  events:
    'click .card': 'click'
    'click .settings-button': 'showSettings'
    'mouseover .card': 'mouseover'
    'mouseleave .card': 'mouseleave'

  constructor: ->
    super

    @settings = new App.Settings

    @games = []
    @gamesConsole = null

    @cardMatrix = []
    @currentlySelectedCard = null

    @rows = 3
    @perRow = 4
    @perPage = @rows * @perRow

    @numberOfPages = 0
    @page = 0
    @x = -1
    @y = -1

  build: ->
    @games = @gameConsole.games()

    @numberOfPages = parseInt(@games.length / @perPage)
    @numberOfPages++ if @games.length % @perPage

  render: ->
    @html @view 'main/games', @

  update: ->
    @build()
    @render();

  showSettings: ->
    app.showSettings()

  launchGame: (game) ->
    command = "#{@settings.retroarchPath()}/bin/retroarch"
    options = ["--config", "#{@settings.retroarchPath()}/configs/all/retroarch.cfg", "--appendconfig", "#{@settings.retroarchPath()}/configs/#{game.gameConsole()}/retroarch.cfg", game.path]

    {spawn} = require 'child_process'
    ls = spawn command, options
    # receive all output and process
    ls.stdout.on 'data', (data) -> console.log data.toString().trim()
    # receive error messages and process
    ls.stderr.on 'data', (data) -> console.log data.toString().trim()

  click: (e) ->
    e.preventDefault()
    card = $(e.currentTarget)

    game = @games[card.index()]
    @launchGame(game)

  selectCard: (card) ->
    @currentlySelectedCard.removeClass('selected') if @currentlySelectedCard
    $(card).addClass('selected')

  deselectCard: (card) ->
    $(card).removeClass('selected')

  setSelected: (i, j) ->

    # check direction for scrolling later
    if j > @y
      direction = 'right'
    else if j < @y
      direction = 'left'


    # max up at the top
    if i < 0
      i = 0
    # max down at the bottom
    if i >= @rows
      i = @rows-1

    # max left on first page
    if j < 0 && @page == 0
      j = 0

    # go back a page and place on far right column
    if j < 0 && @page > 0
      j = @perRow-1
      @page -= 1


    # advancing a page to the right
    if j >= @perRow
      # max right to the far right on the last page
      if j >= @page+1 >= @numberOfPages
        j = 3
      # advance a page
      else
        j = 0
        @page += 1


        # check to see if there are contents on that row
        adjustedI = @page*@rows + i
        index = (@perRow * adjustedI + j)
        # no items on that row, pop to the top
        if index >= @games.length
          i = 0

    # adjust i for what page it's on
    # don't forget, according to the DOM, the pages are
    # UNDER each other
    adjustedI = @page*@rows + i
    index = (@perRow * adjustedI + j)

    if index < @games.length
      # set selected items
      @currentlySelectedCard.removeClass('selected') if @currentlySelectedCard
      @currentlySelectedCard = $(@cards[index])
      @currentlySelectedCard.addClass('selected')



      # check if card is visible, if it isn't scroll to it
      if !@currentlySelectedCard.visible()
        scrollAmount = @currentlySelectedCard.width() + 50
        if direction == 'left'
          scrollOption = "-=#{scrollAmount}px"
        else
          scrollOption = "+=#{scrollAmount}px"

        $.scrollTo(scrollOption, 150, {easing:'swing'})


      # save these for later
      @x = i;
      @y = j;


  mouseover: (e) ->
    card = $(e.currentTarget)
    @selectCard(card)

  mouseleave: (e) ->
    card = $(e.currentTarget)
    @deselectCard(card)

  keyboardNav: (e) ->

    switch e.keyCode
      when KeyCodes.up
        @setSelected(@x-1,@y);
        e.preventDefault()
      when KeyCodes.down
        @setSelected(@x+1,@y);
        e.preventDefault()
      when KeyCodes.left
        @setSelected(@x,@y-1);
        e.preventDefault()
      when KeyCodes.right
        @setSelected(@x,@y+1);
        e.preventDefault()
      when KeyCodes.enter
        @launchGame(@games[$(@currentlySelectedCard).index()  + (@page*12) ])
        e.preventDefault()
      when KeyCodes.esc
        app.showHome()
        e.preventDefault()

module.exports = Games
