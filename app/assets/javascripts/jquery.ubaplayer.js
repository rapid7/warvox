/*! UbaPlayer - v1.0.1 - 2012-06-06
* https://github.com/brianhadaway/UbaPlayer
* Copyright (c) 2012 Brian Hadaway; Licensed MIT, GPL */

(function($){
	var defaults = {
		audioButtonClass:	"audioButton",
		autoPlay:	null,
		codecs:	[{name:"OGG", codec: 'audio/ogg; codecs="vorbis"'}, {name:"MP3", codec: 'audio/mpeg'}],
		continuous:	false,
		extension:	null,
		flashAudioPlayerPath:	"libs/swf/player.swf",
		flashExtension:	".mp3",
		flashObjectID:	"audioPlayer",
		loadingClass:	"loading",
		loop:	false,
		playerContainer:	"player",
		playingClass:	"playing",
		swfobjectPath:	"libs/swfobject/swfobject.js",
		volume:	0.5
	},
	currentTrack,
	isPlaying = false,
	isFlash = false,
	audio,
	$buttons,
	$tgt,
	$el,
	playTrack,
	resumeTrack,
	pauseTrack,
	methods = {
		play: function(element){
			$tgt = element;
			currentTrack = _methods.getFileNameWithoutExtension($tgt.attr("href"));
			isPlaying = true;
			$tgt.addClass(defaults.loadingClass);
			$buttons.removeClass(defaults.playingClass);

			if(isFlash){
				if(audio) {
					_methods.removeListeners(window);
				}
				audio = document.getElementById(defaults.flashObjectID);
				_methods.addListeners(window);
				audio.playFlash(currentTrack + defaults.extension);
			} else {
				if(audio) {
					audio.pause();
					_methods.removeListeners(audio);
				}
				audio = new Audio("");
				_methods.addListeners(audio);
				audio.id = "audio";
				audio.loop = defaults.loop ? "loop" : "";
				audio.volume = defaults.volume;
				audio.src = currentTrack + defaults.extension;
				audio.play();
			}
		},

		pause: function(){
			if(isFlash){
				audio.pauseFlash();
			} else {
				audio.pause();
			}

			$tgt.removeClass(defaults.playingClass);
			isPlaying = false;
		},

		resume: function(){
			if(isFlash){
				audio.playFlash();
			} else {
				audio.play();
			}
			$tgt.addClass(defaults.playingClass);
			isPlaying = true;
		},

		playing: function(){
			return isPlaying;
		}
	},
	
	_methods = {
		init: function( options ){
			var types;

			//set defaults
			$.extend(defaults, options);
			$el = this;

			//listen for clicks on the controls
			$(".controls").bind("click",function(event){
				_methods.updateTrackState(event);
				return false;
			});
			$buttons = $("."+defaults.audioButtonClass);

			types = defaults.codecs;
			for(var i = 0, ilen = types.length; i < ilen; i++){
				var type = types[i];
				if(_methods.canPlay(type)){
					defaults.extension = [".", type.name.toLowerCase()].join("");
					break;
				}
			}

			if(!defaults.extension || isFlash){
				isFlash = true;
				defaults.extension = defaults.flashExtension;
			}

			if(isFlash){
				$el.html("<div id='" + defaults.playerContainer + "'/>");
				$.getScript(defaults.swfobjectPath,function(){
					swfobject.embedSWF(defaults.flashAudioPlayerPath, defaults.playerContainer, "0", "0", "9.0.0", "swf/expressInstall.swf", false, false, {id:defaults.flashObjectID}, _methods.swfLoaded);
				});
			} else {
				if(defaults.autoPlay){
					methods.play(defaults.autoPlay);
				}
			}
		},

		updateTrackState: function( evt ){
			$tgt = $(evt.target);
			if(!$tgt.hasClass("audioButton")){
				return;
			}
			if(!audio || (audio && currentTrack !== _methods.getFileNameWithoutExtension($tgt.attr("href")))){
				methods.play($tgt);
			} else if(!isPlaying) {
				methods.resume();
			} else {
				methods.pause();
			}
		},

		addListeners: function(elem) {
			$(elem).bind({"canplay" : _methods.onLoaded,
						"error" : _methods.onError,
						"ended" : _methods.onEnded});
		},

		removeListeners: function(elem) {
			$(elem).unbind({"canplay" : _methods.onLoaded,
						"error" : _methods.onError,
						"ended" : _methods.onEnded});
		},

		onLoaded: function () {
			$buttons.removeClass(defaults.loadingClass);
			$tgt.addClass(defaults.playingClass);

			audio.play();
		},

		onError: function () {
			$buttons.removeClass(defaults.loadingClass);
			if(isFlash){
				_methods.removeListeners(window);
			} else {
				_methods.removeListeners(audio);
			}
		},

		onEnded: function () {
			isPlaying = false;
			$tgt.removeClass(defaults.playingClass);
			currentTrack = "";
			if(isFlash){
				_methods.removeListeners(window);
			} else {
				_methods.removeListeners(audio);
			}

			if(defaults.continuous){
				var $next = $tgt.next().length ? $tgt.next() : $(defaults.audioButtonClass).eq(0);
				methods.play($next);
			}

		},

		canPlay: function(type) {
			if(!document.createElement("audio").canPlayType){
				return false;
			} else {
				return document.createElement("audio").canPlayType(type.codec).match(/maybe|probably/i) ? true : false;
			}
		},

		swfLoaded: function(){
			if(defaults.autoPlay){
				setTimeout(function(){methods.play(defaults.autoPlay);}, 500);
			}
		},

		getFileNameWithoutExtension: function(fileName){
			//this function take a full file name and returns an extensionless file name
			//ex. entering foo.mp3 returns foo
			//ex. entering foo returns foo (no change)

			var fileNamePieces = fileName.split('.');
			fileNamePieces.pop();
			return fileNamePieces.join(".");
		}
	};

	$.fn.ubaPlayer = function(method){
		if(methods[method]){
			return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
		} else if ( typeof method === "object" || ! method ) {
			return _methods.init.apply( this, arguments );
		} else {
			$.error( "Method " +  method + " does not exist on jquery.ubaPlayer" );
		}
	};

})(jQuery);
