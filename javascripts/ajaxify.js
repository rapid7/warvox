$(document).ready(function() {
						   
	var hash = window.location.hash.substr(1);
	var href = $('#nav li#ajax a').each(function(){
		var href = $(this).attr('href');
		if(hash==href.substr(0,href.length-5)){
			var toLoad = hash+'.html #toload';
			$('#toload').load(toLoad)
		}											
	});

	$('#nav li#ajax a').click(function(){
								  
		var toLoad = $(this).attr('href')+' #toload';
		$('#toload').fadeTo('fast',0.00001,loadContent);
		$('#load').remove();
		$('#wrapper').append('<span id="load">LOADING...</span>');
		$('#load').fadeIn('fast');
		window.location.hash = $(this).attr('href').substr(0,$(this).attr('href').length-5);
		function loadContent() {
			$('#toload').load(toLoad,showNewContent())
		}
		function showNewContent() {
			$('#toload').delay(500).fadeTo('normal',1,hideLoader());
		}
		function hideLoader() {
			$('#load').fadeOut('normal');
		}
		return false;
		
	});

});
