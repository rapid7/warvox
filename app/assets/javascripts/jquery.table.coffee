# table plugin
#
# Adds sorting and other dynamic functions to tables.
jQuery ($) ->
  $.table =
    defaults:
      searchable:        true
      searchInputHint:   'Search'
      sortableClass:     'sortable'
      setFilteringDelay: false
      datatableOptions:
        "bStateSave":    true
        "oLanguage":
          "sSearch":  ""
          "sProcessing":    "Loading..."
        "fnDrawCallback": ->
          $.table.controlBar.buttons.enable()
        "sDom": '<"control-bar"f><"list-table-header clearfix"l>t<"list-table-footer clearfix"ip>r'
        "sPaginationType": "full_numbers"
        "fnInitComplete": (oSettings, json) ->
           # if old search term saved, display it
          searchTerm = getParameterByName 'search'
          # FIX ME
          $searchBox = $('#search', $(this).parents().eq(3))

          if searchTerm
            $searchBox.val searchTerm
            $searchBox.focus()

          # insert the cancel button to the left of the search box
          $searchBox.before('<a class="cancel-search" href="#"></a>')
          $a = $('.cancel-search')
          table = this
          searchTerm = $searchBox.val()
          searchBox = $searchBox.eq(0)
          $a.hide() if (!searchTerm || searchTerm.length < 1)

          $a.click (e) ->  # called when red X is clicked
            $(this).hide()
            table.fnFilter ''
            $(searchBox).blur()           # blur to trigger filler text
            e.preventDefault()            # Other control code can be found in filteringDelay.js plugin.
          # bind to fnFilter() calls
          # do this by saving fnFilter to fnFilterOld & overriding
          table['fnFilterOld'] = table.fnFilter
          table.fnFilter = (str) ->
            $a = jQuery('.cancel-search')
            if str && str.length > 0
              $a.show()
            else
              $a.hide()
            table.fnFilterOld(str)

          window.setTimeout ( =>
            this.fnFilter(searchTerm)
            ), 0

          $('.button a.search').click() if searchTerm

      analysisTabOptions:
        "aLengthMenu":      [[10, 50, 100, 250, 500, -1], [10, 50, 100, 250, 500, "All"]]
        "iDisplayLength":   10
        "bProcessing":      true
        "bServerSide":      true
        "bSortMulti":       false

    checkboxes:
      bind: ->
        # TODO: This and any other 'table.list' selectors that appear in the plugin
        # code will trigger all sortable tables visible on the page.
        $("table.list thead tr th input[type='checkbox']").live 'click', (e) ->
          $checkboxes = $("input[type='checkbox']", "table.list tbody tr td:nth-child(1)")
          if $(this).attr 'checked'
            $checkboxes.attr 'checked', true
          else
            $checkboxes.attr 'checked', false

    controlBar:
      buttons:
        # Disables/enables buttons based on number of checkboxes selected,
        # and the class name.
        enable: ->
          numChecked = $("tbody tr td input[type='checkbox']", "table.list").filter(':checked').not('.invisible').size()
          disable = ($button) ->
            $button.addClass 'disabled'
            $button.children('input').attr 'disabled', 'disabled'
          enable = ($button) ->
            $button.removeClass 'disabled'
            $button.children('input').removeAttr 'disabled'

          switch numChecked
            when 0
              disable $('.btn.single',  '.control-bar')
              disable $('.btn.multiple','.control-bar')
              disable $('.btn.any',     '.control-bar')
            when 1
              enable  $('.btn.single',  '.control-bar')
              disable $('.btn.multiple','.control-bar')
              enable  $('.btn.any',     '.control-bar')
            else
              disable $('.btn.single',  '.control-bar')
              enable  $('.btn.multiple','.control-bar')
              enable  $('.btn.any',     '.control-bar')

        show:
          bind: ->
            # Show button
            $showButton = $('span.button a.show', '.control-bar')
            if $showButton.length
              $showButton.click (e) ->
                unless $showButton.parent('span').hasClass 'disabled'
                  $("table.list tbody tr td input[type='checkbox']").filter(':checked').not('.invisible')
                  hostHref = $("table.list tbody tr td input[type='checkbox']")
                    .filter(':checked')
                    .parents('tr')
                    .children('td:nth-child(2)')
                    .children('a')
                    .attr('href')
                  window.location = hostHref
                e.preventDefault()

        edit:
          bind: ->
            # Settings button
            $editButton = $('span.button a.edit', '.control-bar')
            if $editButton.length
              $editButton.click (e) ->
                unless $editButton.parent('span').hasClass 'disabled'
                  $("table.list tbody tr td input[type='checkbox']").filter(':checked').not('.invisible')
                  hostHref = $("table.list tbody tr td input[type='checkbox']")
                    .filter(':checked')
                    .parents('tr')
                    .children('td:nth-child(2)')
                    .children('span.settings-url')
                    .html()
                  window.location = hostHref
                e.preventDefault()

        bind: (options) ->
          # Move the buttons into the control bar.
          $('.control-bar').prepend($('.control-bar-items').html())
          $('.control-bar-items').remove()

          # Move the control bar to a new location, if specified.
          if !!options.controlBarLocation
            $('.control-bar').appendTo(options.controlBarLocation)

          this.enable()
          this.show.bind()
          this.edit.bind()

      bind: (options) ->
        this.buttons.bind(options)
        # Redraw the buttons with each checkbox click.
        $("input[type='checkbox']", "table.list").live 'click', (e) =>
          this.buttons.enable()

    searchField:
      # Add an input hint to the search field.
      addInputHint: (options, $table) ->
        if options.searchable
          # if the searchbar is in a control bar, expand selector scope to include control bar
          searchScope = $table.parents().eq(3) if !!options.controlBarLocation
          searchScope ||= $table.parents().eq(2)  # otherwise limit scope to just the table
          $searchInput = $('.dataTables_filter input', searchScope)
          # We'll need this id set for the checkbox functions.
          $searchInput.attr 'id', 'search'
          $searchInput.attr 'placeholder', options.searchInputHint
          # $searchInput.inputHint()

    bind: ($table, options) ->
      $tbody = $table.children('tbody')
      dataTable = null
      # Turn the table into a DataTable.
      if $table.hasClass options.sortableClass
        # Don't mess with the search input if there's no control bar.
        unless $('.control-bar-items').length
          options.datatableOptions["sDom"] = '<"list-table-header clearfix"lfr>t<"list-table-footer clearfix"ip>'

        datatableOptions = options.datatableOptions
        # If we're loading under the Analysis tab, then load the standard
        # Analysis tab options.
        if options.analysisTab
          $.extend(datatableOptions, options.analysisTabOptions)
          options.setFilteringDelay = true
          options.controlBarLocation = $('.analysis-control-bar')

        dataTable = $table.dataTable(datatableOptions)
        $table.data('dataTableObject', dataTable)
        dataTable.fnSetFilteringDelay(500) if options.setFilteringDelay

        # If we're loading under the Analysis tab, then load the standard Analysis tab functions.
        if options.analysisTab
          # Gray out the table during loads.
          $("##{$table.attr('id')}_processing").watch 'visibility', ->
            if $(this).css('visibility') == 'visible'
              $table.css opacity: 0.6
            else
              $table.css opacity: 1

          # Checking a host_ids checkbox should also check the invisible related object checkbox.
          $table.find('tbody tr td input[type=checkbox].hosts').live 'change', ->
            $(this).siblings('input[type=checkbox]').attr('checked', $(this).attr('checked'))

        this.checkboxes.bind()
        this.controlBar.bind(options)
        # Add an input hint to the search field.
        this.searchField.addInputHint(options, $table)
        # Keep width at 100%.
        $table.css('width', '100%')

  $.fn.table = (options) ->
    settings = $.extend true, {}, $.table.defaults, options
    $table   = $(this)
    return this.each -> $.table.bind($table, settings)
