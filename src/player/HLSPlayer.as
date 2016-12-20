package player
{
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.NetStatusEvent;
	import flash.events.StageVideoAvailabilityEvent;
	import flash.events.StageVideoEvent;
	import flash.events.TimerEvent;
	import flash.events.VideoEvent;
	import flash.geom.Rectangle;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.media.StageVideo;
	import flash.media.StageVideoAvailability;
	import flash.media.Video;
	import flash.net.URLRequest;
	import flash.net.URLStream;
	import flash.utils.Timer;
	
	import mx.controls.Alert;
	
	import org.mangui.hls.HLS;
	import org.mangui.hls.event.HLSEvent;
	
	import spark.components.Group;
	import spark.core.SpriteVisualElement;
	
	import utils.Utils;
	
	public class HLSPlayer extends Group
	{
		private var hlsURL:String = "";
		private var hls:HLS;
		private var video:Video;
		private var stageVideo:StageVideo;
		private const tf:SoundTransform = new SoundTransform();
		
		private var oldLoaded:Number = 0;
		private var bitrateInterval:uint = 1;
		
		private var startEmpty:Number = -1;
		private var emptyArr:Array = [];
		private var timestampArr:Array = [];
		private var fpsArr:Array = [];
		private var bitrateArr:Array = [];
		private var emptyStr:String = "";
		private var timestampStr:String = "";
		private var fpsStr:String = "";
		private var bitrateStr:String = "";
		private var timestampCounter:int = 0;
		private var emptyCounter:int = 0;
		private var fpsCounter:int = 0;
		private var bitrateCounter:int = 0;
		public var timestamp:String = "";
		public var buffer:String = "";
		public var fps:String = "";
		public var bitrate:String = "";
		public var multiBitrate:Boolean = false;//暂时不用
		
		private const timer:Timer = new Timer(1000);
		private const timeoutTimer:Timer = new Timer(8000);
		private var timeoutCounter:int = 0;
		
		public function HLSPlayer()
		{
			super();
			if(stage) {
				init();
			} else {
				this.addEventListener(Event.ADDED_TO_STAGE, init);
			}
		}
		
		private function init(event:Event = null):void {
			if(event)this.removeEventListener(Event.ADDED_TO_STAGE, init);
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.fullScreenSourceRect = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
			stage.addEventListener(StageVideoAvailabilityEvent.STAGE_VIDEO_AVAILABILITY, onStageVideoState);
			stage.addEventListener(Event.RESIZE, onStageResize);		
		}
		
		private function onStageVideoState(event:StageVideoAvailabilityEvent):void {
			var available:Boolean = (event.availability == StageVideoAvailability.AVAILABLE);
			
			hls = new HLS();
			hls.stage = stage;
			stage.frameRate = 60;
			
			hls.addEventListener(HLSEvent.MANIFEST_LOADED, manifestLoadedHandler);
			hls.addEventListener(HLSEvent.ERROR, manifestErrorHandler);
			hls.addEventListener(HLSEvent.MEDIA_TIME, mediaTimeHandler);
			hls.addEventListener(HLSEvent.LEVEL_SWITCH, levelSwitchHandler);
			
			if (available && stage.stageVideos.length > 0) {
				trace("use StageVideo");
				stageVideo = stage.stageVideos[0];
				stageVideo.addEventListener(StageVideoEvent.RENDER_STATE, onStageVideoStateChange);
				stageVideo.viewPort = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
				stageVideo.attachNetStream(hls.stream);
			} else {
				trace("use Video");
				video = new Video(192, 104);
				video.addEventListener(VideoEvent.RENDER_STATE, onVideoStateChange);
				video.smoothing = true;
				video.attachNetStream(hls.stream);
				const s:SpriteVisualElement = new SpriteVisualElement;
				addElement(s);
				s.addChild(video);
			}
			stage.removeEventListener(StageVideoAvailabilityEvent.STAGE_VIDEO_AVAILABILITY, onStageVideoState);
			
			timer.addEventListener(TimerEvent.TIMER, timerHandler);
			timeoutTimer.addEventListener(TimerEvent.TIMER, timeoutHandler);
		}
		
		private function manifestLoadedHandler(event:HLSEvent):void {
//			trace("----");
//			trace("hls.levels.length = "+hls.levels.length);
//			for(var i:int=0;i<hls.levels.length;i++){
//				trace(hls.levels[i].bitrate);
//			}
//			trace("----");
			
			multiBitrate = !(hls.levels.length==1);
			trace("multiBitrate = "+multiBitrate);
			
			hls.stream.play(null, -1);
			timer.reset();
			timer.start();
		}
		
		private function manifestErrorHandler(event:HLSEvent):void {
			dispatchEvent(new Event("STH_WRONG"));
		}
		
		private function mediaTimeHandler(event:HLSEvent):void {
			
		}
		
		private function levelSwitchHandler(event:HLSEvent):void {
//			if(!multiBitrate)return;
			
			const br:Number = Math.floor(hls.levels[event.level].bitrate/1024*10)/10;//kbps
			this.bitrateArr.push({
				time:Utils.date((new Date).time),
				bitrate:br
			});
			getBitrateResult();
		}
		
		private function onStageResize(event:Event):void {
			
		}
		
		private function onStageVideoStateChange(event:StageVideoEvent):void {
			
		}
		
		private function onVideoStateChange(event:VideoEvent):void {
			
		}
		
		public function initPlayer(_hlsURL:String):void {
			hlsURL = _hlsURL;
			
			hls.stream.addEventListener(NetStatusEvent.NET_STATUS, netStatus);
			trace("测试 静音 "+volume);
			tf.volume = 0;
			hls.stream.soundTransform = tf;
			hls.load(hlsURL);
		}
		
		public function update():void{
			emptyArr = [];
			timestampArr = [];
			fpsArr = [];
			emptyStr = "";
			timestampStr = "";
			fpsStr = "";
			timestampCounter = 0;
			emptyCounter = 0;
			fpsCounter = 0;
		}
		
		private function netStatus(event:NetStatusEvent):void {
			this.dispatchEvent(event.clone());
			
			var currentTime:Date = new Date();
			if(event.info.code == "NetStream.Buffer.Empty"){
				startEmpty = (new Date).time;
				timeoutTimer.start();
			} else if(event.info.code == "NetStream.Buffer.Full") {
				timeoutTimer.stop();
				
				const now:Number = (new Date()).time;
				if(startEmpty>0){
					emptyArr.push({
						endtime:Utils.date(now),
						duration:(now - startEmpty)/1000
					});
					trace("缓冲："+emptyArr[emptyArr.length-1].duration);
					startEmpty = -1;
					
					getBufferResult();
				}
			}
		}
		
		private function timerHandler(event:TimerEvent):void {
			//fps
			const fps:Number = hls.stream.currentFPS;
			this.fpsArr.push({
				time:Utils.date((new Date).time), 
				fps:fps
			});
			getFpsResult();
			
			//timestamp
			timestampArr.push({
				time:Utils.date((new Date).time),
				timestamp:hls.stream.time
			});
			getTimestampResult();
			
			//bitrate simple-bit
//			if(!multiBitrate && timer.currentCount%bitrateInterval==0){
//				var loaded:Number = hls.stream.bytesLoaded;//Bytes			
//				var difference:Number = (loaded - oldLoaded)*8;//bit
//				var br:Number = 0;
//				if(difference>0) {
//					br = Math.floor((difference/(bitrateInterval*timer.delay/1000))/1024);//kbps
//				}
//				this.bitrateArr.push({
//					time:Utils.date((new Date).time),
//					bitrate:br
//				});
//				oldLoaded = loaded;
//				getBitrateResult();
//			}
		}
		
		/**
		 * 超时 
		 * @param event
		 * 
		 */		
		private function timeoutHandler(event:TimerEvent):void{
			timeoutTimer.stop();
			
			if(++timeoutCounter >= 3){
				this.unloadResource();
				dispatchEvent(new Event("STH_WRONG"));
				Alert.show("超时");
				timeoutCounter = 0;
			}else{
				trace("timeout");
				this.initPlayer(hlsURL);	
			}
		}
		
		private function unloadResource():void
		{
			try {
				hls.stream.close();
			} catch (error:Error) {
				trace(error);
			}
			
			if(timeoutTimer.running)timeoutTimer.stop();
			timer.reset();
			startEmpty = -1;
		}
		
		public function set volume(_v:Number):void{
			try {
				tf.volume = _v;
				hls.stream.soundTransform = tf;
			} catch (error:Error) {
				trace(error);
			}
		}
		public function get volume():Number {
			var v:Number = 0;
			try {
				v = hls.stream.soundTransform.volume;
			} catch (error:Error) {
				trace(error);
			}
			return v;
		}
		
		
		/**
		 * 帧率数据 
		 * 
		 */		
		private function getFpsResult():void{
			var i:int;
			for(i=fpsCounter;i<fpsArr.length;i++){
				fps = (fpsArr[i].time+" : "+Math.floor(fpsArr[i].fps)+"\r\n");
			}
			fpsCounter = i;
			dispatchEvent(new Event("UPDATE_FPS"));
		}
		
		/**
		 * 时间戳数据 
		 * 
		 */		
		private function getTimestampResult():void{
			var i:int;
			for(i=timestampCounter;i<this.timestampArr.length;i++){
				timestamp = timestampArr[i].time+" : "+timestampArr[i].timestamp+"\r\n";
			}
			timestampCounter = i;
			dispatchEvent(new Event("UPDATE_TIMESTAMP"));
		}
		
		/**
		 * 码率数据 
		 * 
		 */		
		private function getBitrateResult():void {
			var i:int;
			for(i=bitrateCounter;i<bitrateArr.length;i++) {
				this.bitrate = (bitrateArr[i].time+" : "+bitrateArr[i].bitrate)+"\r\n";
			}
			this.bitrateCounter = i;
			dispatchEvent(new Event("UPDATE_BITRATE"));
		}
		
		/**
		 * 缓冲数据 
		 * 
		 */		
		private function getBufferResult():void{
			var i:int;
			for(i=emptyCounter;i<emptyArr.length;i++){
				buffer = emptyArr[i].endtime+" : "+emptyArr[i].duration+"\r\n";
			}
			emptyCounter = i;
			dispatchEvent(new Event("UPDATE_BUFFER"));
		}
	}
}