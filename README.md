# FlashlsLib
bese on https://github.com/mangui/flashls

```javascript
<?xml version="1.0" encoding="utf-8"?>
<s:Application xmlns:fx="http://ns.adobe.com/mxml/2009"
			   xmlns:s="library://ns.adobe.com/flex/spark"
			   xmlns:mx="library://ns.adobe.com/flex/mx"
			   minWidth="955" minHeight="110" creationComplete="main()">
	<fx:Declarations>
		<!-- 将非可视元素（例如服务、值对象）放在此处 -->
	</fx:Declarations>
	<fx:Script>
		<![CDATA[
			import view.View;
			private var view:View;
			private function main():void{
				view = new View;
				stageGroup.addElement(view);
			}
		]]>
	</fx:Script>
	<s:Group id="stageGroup"></s:Group>
</s:Application>
```