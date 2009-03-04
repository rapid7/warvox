<% if @dial_data_todo.length > 0 %>

<h1 class='title'>Processing <%= @dial_data_todo.length %> Calls...</h1>

<table width='100%' align='center' border=0 cellspacing=0 cellpadding=6>
<tr>
	<td align='center'> </td>
	<td align='center'> </td>
</tr>
</table>

<table class='table_scaffold' width='100%'>
  <tr>
    <th>Number</th>
    <th>CallerID</th>	
    <th>Provider</th>
    <th>Call Time</th>
	<th>Ring Time</th>
  </tr>

<% for dial_result in @dial_data_todo.sort{|a,b| a.number <=> b.number } %>
  <tr>
    <td><%=h dial_result.number %></td>
    <td><%=h dial_result.cid %></td>
    <td><%=h dial_result.provider.name %></td>
    <td><%=h dial_result.seconds %></td>
    <td><%=h dial_result.ringtime %></td>
  </tr>
<% end %>
</table>

<script language="javascript">
	setTimeout("location.reload(true);", 3000);
</script>

<%= will_paginate @dial_data_todo %>

<% else %>

<h1 class='title'>No Completed Calls Found</h1>

<% end %>

<br />
