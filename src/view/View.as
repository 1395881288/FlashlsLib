package view
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.FileReference;
	import flash.system.Capabilities;
	import flash.system.Security;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	
	import mx.controls.Alert;
	import mx.core.FlexGlobals;
	
	import player.HLSPlayer;
	
	import spark.components.Button;
	import spark.components.Group;
	import spark.components.TextArea;
	import spark.components.TextInput;
	
	import utils.Utils;
	
	public class View extends Group
	{
		private const input:TextInput = new TextInput;
		private var p:HLSPlayer;
		private var hlsURL:String;
		private var btn:Button;
		private var volumeBtn:Button;
		private var getBufferResult:Button;
		private var getTimestamp:Button;
		private var getFps:Button;
		private const info:TextArea = new TextArea;
		private const file:FileReference = new FileReference;
		
		public function View()
		{
			if(stage)
			{
				init();
			}
			else
			{
				this.addEventListener(Event.ADDED_TO_STAGE, init);
			}
		}
		
		private function init(event:Event = null):void
		{
			if(event)this.removeEventListener(Event.ADDED_TO_STAGE, init);
			
			hlsURL = FlexGlobals.topLevelApplication.parameters.hls;
			
			if(!Utils.isAIR){
				Security.allowDomain("*");
			}
			
			inputHandler();
			outputHandler();
			playerHandler();
			
			file.addEventListener(IOErrorEvent.IO_ERROR, function(event:IOErrorEvent):void{
				Alert.show("file, "+event.type);
			});
			file.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(event:SecurityErrorEvent):void{
				Alert.show("file, "+event.type);
			});
			file.addEventListener(Event.COMPLETE, function(event:Event):void{
				//				Alert.show("HLSPlayer file, "+event.toString());
			});
			file.addEventListener(Event.CANCEL, function(event:Event):void{
				
			});
		}
		
		/**
		 * 输入+播放
		 * 
		 */		
		private function inputHandler():void{
			input.x = 196;
			input.width = stage.stageWidth - 192 - 4;
			input.height = 21;
			input.prompt = "Input a HLS URL";
			addElement(input);
			if(hlsURL && hlsURL.length>0) {
				input.text = hlsURL;
			}
			
			btn = new Button;
			btn.label = "播放";
			btn.addEventListener(MouseEvent.CLICK, playBtnHandler);
			btn.width = 100;
			btn.x = stage.stageWidth - 100 - 10 - 100;
			btn.y = input.y + 25;
			addElement(btn);
			
			volumeBtn = new Button;
			volumeBtn.label = "声音开关";
			volumeBtn.addEventListener(MouseEvent.CLICK, volumeBtnHandler);
			volumeBtn.x = stage.stageWidth - 100;
			volumeBtn.y = input.y + 25;
			volumeBtn.width = 100;
			addElement(volumeBtn);
		}
		
		/**
		 * 视频 
		 * 
		 */		
		private function playerHandler():void{
			p = new HLSPlayer();
			p.addEventListener(NetStatusEvent.NET_STATUS, status);
			p.addEventListener("STH_WRONG", function(event:Event):void{
				info.text = "";
			});
			p.addEventListener("UPDATE_FPS", function(event:Event):void{
				try {
					ExternalInterface.call("showFPSLog", p.fps);
				} catch (error:Error) {
					trace(error.toString());
				}
			});
			p.addEventListener("UPDATE_BUFFER", function(event:Event):void{
				try {
					ExternalInterface.call("showBufferLog", p.buffer);
				} catch (error:Error) {
					trace(error.toString());
				}
			});
			p.addEventListener("UPDATE_TIMESTAMP", function(event:Event):void{
				try {
					ExternalInterface.call("showTimestampLog", p.timestamp);
				} catch (error:Error) {
					trace(error.toString());
				}
			});
			p.addEventListener("UPDATE_BITRATE", function(event:Event):void{
				try {
					ExternalInterface.call("showBitrateLog", p.bitrate);
				} catch (error:Error) {
					trace(error.toString());
				}
			});
			addElement(p);
		}
		
		private function status(event:NetStatusEvent):void {
			if(event.info.code == "NetStream.Buffer.Empty") {
				info.text = "loading";
			} else if(event.info.code == "NetStream.Buffer.Full") {
				info.text = "";
			}
		}
		
		/**
		 * 播放按钮 
		 * @param event
		 * 
		 */		
		private function playBtnHandler(event:MouseEvent):void{
			const url:String = input.text;
			if(url == "")
			{
				Alert.show("请填写HLS流地址");
				return;
			}
			else
			{
				var arr:Array = url.split(".");
				if(url.length <= 0 || arr[arr.length-1] != "m3u8") {
					Alert.show("请填写HLS流地址");
					return;
				}	
			}
			
			p.timestamp = url+"\r\n\r\nTIMESTAMP\r\n\r\n时刻 : 时间戳\r\n\r\n";
			p.buffer = url+"\r\n\r\nBUFFER\r\n\r\n卡顿结束时刻 : 卡顿时长(秒)\r\n\r\n";
			p.fps = url+"\r\n\r\nFPS\r\n\r\n时刻 : FPS\r\n\r\n";
			p.bitrate = url+"\r\n\r\nBITRATE kbps\r\n\r\n时刻 : BITRATE\r\n\r\n";
			if(!Utils.isAIR) {
				try {
					ExternalInterface.call("showFPSLog", p.fps);
					ExternalInterface.call("showBufferLog", p.buffer);
					ExternalInterface.call("showTimestampLog", p.timestamp);
					ExternalInterface.call("showBitrateLog", p.bitrate);
					ExternalInterface.call("saveURL", url);
				} catch (error:Error) {
					trace(error.toString());
				}
			}
			
			volumeBtn.alpha = .3;
			p.update();
			p.initPlayer(url);
			info.text = "loading";
		}
		
		/**
		 * 声音开关 
		 * @param event
		 * 
		 */		
		private function volumeBtnHandler(event:MouseEvent):void{
			if(p.volume == -1) {
				return;
			} else if(p.volume == 0) {
				p.volume = 1;
				volumeBtn.alpha = 1;
			} else {
				p.volume = 0;
				volumeBtn.alpha = .3;
			}
		}
		
		/**
		 * 输出按钮 
		 * 
		 */		
		private function outputHandler():void{
			info.x = 196;
			info.y = input.y + 25;
			info.prompt = "HLS Status";
			info.width = 100;
			info.height = 21;
			addElement(info);
			
			getTimestamp = new Button;
			getTimestamp.label = "保存时间戳";
			getTimestamp.x = 196;
			getTimestamp.y = stage.stageHeight - 27;
//			addElement(getTimestamp);
			getTimestamp.addEventListener(MouseEvent.CLICK, function(event:MouseEvent):void{
				try{
					file.save(p.timestamp, "TIMESTAMP "+Utils.fileName()+".txt");
				} catch (error:Error) {
					Alert.show(error.toString());
				}
			});
			
			getFps = new Button;
			getFps.label = "保存帧率";
			getFps.x = getTimestamp.x + 90;
			getFps.y = stage.stageHeight - 27;
//			addElement(getFps);
			getFps.addEventListener(MouseEvent.CLICK, function(event:MouseEvent):void{
				try{
					file.save(p.fps, "FPS "+Utils.fileName()+".txt");
				} catch (error:Error) {
					Alert.show(error.toString());
				}
			});
			
			getBufferResult = new Button;
			getBufferResult.label = "保存缓冲";
			getBufferResult.x = getFps.x + 80;
			getBufferResult.y = stage.stageHeight - 27;
//			addElement(getBufferResult);
			getBufferResult.addEventListener(MouseEvent.CLICK, function(event:MouseEvent):void{
				try{
					file.save(p.buffer, "BUFFER "+Utils.fileName()+".txt");
				} catch (error:Error) {
					Alert.show(error.toString());
				}
			});
			
			
			
		}
	}
}