jQuery ($) ->
  $ ->
    resultsPath = $('#results-path').html()
    $resultsTable = $('#results-table')

    # Enable DataTable for the results list.
    $resultsDataTable = $resultsTable.table
      analysisTab: true
      controlBarLocation: $('.analysis-control-bar')
      searchInputHint:   'Search Calls'
      searchable: true
      datatableOptions:
        "sDom": "<'row'<'span6'l><'span6'f>r>t<'row'<'span6'i><'span6'p>>",
        "sPaginationType": "bootstrap",
        "oLanguage":
          "sEmptyTable":    "No analysis results."
        "sAjaxSource":      resultsPath
        "aaSorting":      [[1, 'asc']]
        "aoColumns": [
          {"mDataProp": "checkbox", "bSortable": false, "sWidth": "22px"}
          {"mDataProp": "number"}
          {"mDataProp": "line_type"}
          {"mDataProp": "signal"}
        ]
        "fnServerData": ( sSource, aoData, fnCallback ) ->
          $.getJSON sSource, aoData, (json) ->
            fnCallback(json)
            $(".xtooltip").tooltip('fixTitle')
            $(".xpopover").popover
              html: true
              placement: 'right'
              trigger: 'hover'
              delay: { show: 300, hide: 300 }
              animation: false

    # Gray out the table during loads.
    $("#results-table_processing").watch 'visibility', ->
      if $(this).css('visibility') == 'visible'
        $resultsTable.css opacity: 0.6
      else
        $resultsTable.css opacity: 1

    # Display the search bar when the search icon is clicked
    $('.button .search').click (e) ->
      $filter = $('.dataTables_filter')
      $input = $('.dataTables_filter input')
      if $filter.css('bottom').charAt(0) == '-' # if (css matches -42px)
        # input box is visible, hide it
        # only allow user to hide if there is no search string
        if !$input.val() || $input.val().length < 1
          $filter.css('bottom', '99999999px')
      else # input box is invisible, display it
        $filter.css('bottom', '-42px')
        $input.focus()  # auto-focus input
      e.preventDefault()

    searchVal = $('.dataTables_filter input').val()
    $('.button .search').click() if searchVal && searchVal.length > 0
