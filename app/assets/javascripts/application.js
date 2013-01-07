// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
//= require jquery
//= require jquery_ujs
//= require twitter/bootstrap
//= require bootstrap-lightbox
//= require dataTables/jquery.dataTables
//= require dataTables/jquery.dataTables.bootstrap
//= require dataTables.hiddenTitle
//= require dataTables.filteringDelay
//= require dataTables.fnReloadAjax
//= require jquery.table
//= require dataTables_overrides
//= require highcharts




function getParameterByName(name)
{
  name = name.replace(/[\[]/, "\\\[").replace(/[\]]/, "\\\]");
  var regexS = "[\\?&]" + name + "=([^&#]*)";
  var regex = new RegExp(regexS);
  var results = regex.exec(window.location.href);
  if(results == null)
    return "";
  else
    return decodeURIComponent(results[1].replace(/\+/g, " "));
}


/*
 * If the given select element is set to "", disables every other element
 * inside the select's form.
 */
function disable_fields_if_select_is_blank(select) {
	var formElement = Element.up(select, "form");
	var fields = formElement.getElements();

	Element.observe(select, "change", function(e) {
		var v = select.getValue();
		for (var i in fields) {
			if (fields[i] != select && fields[i].type && fields[i].type.toLowerCase() != 'hidden' && fields[i].type.toLowerCase() != 'submit') {
				if (v != "") {
					fields[i].disabled = true
				} else {
					fields[i].disabled = false;
				}
			}
		}
	});
}

function enable_fields_with_checkbox(checkbox, div) {
	var fields;

	if (!div) {
		div = Element.up(checkbox, "fieldset")
	}

	f = function(e) {
		fields = div.descendants();
		var v = checkbox.getValue();
		for (var i in fields) {
			if (fields[i] != checkbox && fields[i].type && fields[i].type.toLowerCase() != 'hidden') {
				if (!v) {
					fields[i].disabled = true
				} else {
					fields[i].disabled = false;
				}
			}
		}
	}
	f();
	Element.observe(checkbox, "change", f);
}

function placeholder_text(field, text) {
	var formElement = Element.up(field, "form");
	var submitButton = Element.select(formElement, 'input[type="submit"]')[0];

	if (field.value == "") {
		field.value = text;
		field.setAttribute("class", "placeholder");
	}

	Element.observe(field, "focus", function(e) {
		field.setAttribute("class", "");
		if (field.value == text) {
			field.value = "";
		}
	});
	Element.observe(field, "blur", function(e) {
		if (field.value == "") {
			field.setAttribute("class", "placeholder");
			field.value = text;
		}
	});
	submitButton.observe("click", function(e) {
		if (field.value == text) {
			field.value = "";
		}
	});
}


function submit_checkboxes_to(path, token) {
	var f = document.createElement('form');
	f.style.display = 'none';

	/* Set the post destination */
	f.method = "POST";
	f.action = path;

	/* Create the authenticity_token */
	var s = document.createElement('input');
	s.setAttribute('type', 'hidden');
	s.setAttribute('name', 'authenticity_token');
	s.setAttribute('value', token);
	f.appendChild(s);

	/* Copy the checkboxes from the host form */
	$("input[type=checkbox]").each(function(i,e) {
		if (e.checked)  {
			var c = document.createElement('input');
			c.setAttribute('type', 'hidden');
			c.setAttribute('name',  e.getAttribute('name')  );
			c.setAttribute('value', e.getAttribute('value') );
			f.appendChild(c);
		}
	})

	/* Look for hidden variables in checkbox form */
	$("input[type=hidden]").each(function(i,e) {
		if ( e.getAttribute('name').indexOf("[]") != -1 )  {
			var c = document.createElement('input');
			c.setAttribute('type', 'hidden');
			c.setAttribute('name',  e.getAttribute('name')  );
			c.setAttribute('value', e.getAttribute('value') );
			f.appendChild(c);
		}
	})

	/* Copy the search field from the host form */
	$("input#search").each(function (i,e) {
		if (e.getAttribute("class") != "placeholder") {
			var c = document.createElement('input');
			c.setAttribute('type', 'hidden');
			c.setAttribute('name',  e.getAttribute('name')  );
			c.setAttribute('value', e.value );
			f.appendChild(c);
		}
	});

	/* Append to the main form body */
	document.body.appendChild(f);
	f.submit();
	return false;
}


// Look for the other half of this in app/coffeescripts/forms.coffee
function enableSubmitButtons() {
  $("form.formtastic input[type='submit']").each(function(elmt) {
    elmt.removeClassName('disabled'); elmt.removeClassName('submitting');
  });
}
