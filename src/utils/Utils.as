package utils
{
	import flash.system.Capabilities;

	public class Utils
	{
		public function Utils()
		{
		}
		
		public static function date(...args):String
		{
			var d:Date;
			if(args.length>0) {
				d = new Date(args[0]);
			} else {
				d = new Date();
			}
			
			var _y:String = d.fullYear.toString();
			
			var _m:String = (d.month+1).toString();
			if(int(_m) < 10)_m = "0"+_m;
			
			var _date:String = d.date.toString();
			if(int(_date) < 10)_date = "0"+_date;
			
			var _h:String = d.hours.toString();
			if(int(_h) < 10)_h = "0"+_h;
			
			var _minute:String = d.minutes.toString();
			if(int(_minute) < 10)_minute = "0"+_minute;
			
			var _s:String = d.seconds.toString();
			if(int(_s) < 10)_s = "0"+_s;
			
			var _ms:String = d.milliseconds.toString();
			if(_ms.length == 1)
				_ms = _ms+"  ";
			else if(_ms.length == 2)
				_ms = _ms+" ";
			
			return _y+"-"+_m+"-"+_date+" "+_h+":"+_minute+":"+_s+"."+_ms;
		}
		
		public static function fileName(...args):String {
			var d:Date;
			if(args.length>0) {
				d = new Date(args[0]);
			} else {
				d = new Date();
			}
			
			var _h:String = d.hours.toString();
			if(int(_h) < 10)_h = "0"+_h;
			
			var _minute:String = d.minutes.toString();
			if(int(_minute) < 10)_minute = "0"+_minute;
			
			var _s:String = d.seconds.toString();
			if(int(_s) < 10)_s = "0"+_s;
			
			var _ms:String = d.milliseconds.toString();
			if(_ms.length == 1)
				_ms = _ms+"  ";
			else if(_ms.length == 2)
				_ms = _ms+" ";
			
			return _h+"_"+_minute+"_"+_s;
		}
		
		public static function get isAIR():Boolean {
			return Capabilities.playerType == "Desktop";
		}
		
	}
}